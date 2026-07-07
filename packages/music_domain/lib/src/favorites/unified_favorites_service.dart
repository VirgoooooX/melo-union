import 'package:provider_contract/provider_contract.dart';

import '../capabilities/provider_capability_matrix.dart';
import 'favorites_override.dart';

final class UnifiedFavoriteTrack {
  const UnifiedFavoriteTrack({
    required this.unifiedId,
    required this.title,
    required this.artists,
    required this.duration,
    required this.variants,
  });

  final String unifiedId;
  final String title;
  final List<String> artists;
  final Duration duration;
  final List<SourceTrack> variants;

  bool get hasMultipleSources => variants.length > 1;

  /// Best available liked-at metadata across all variants (latest DateTime wins).
  LikedAtMetadata? get bestLikedAt {
    LikedAtMetadata? best;
    for (final variant in variants) {
      final candidate = _metadataFromTrack(variant);
      if (candidate?.likedAt == null) continue;
      final bestTime = best?.likedAt;
      if (bestTime == null || candidate!.likedAt!.isAfter(bestTime)) {
        best = candidate;
      }
    }
    return best;
  }

  static LikedAtMetadata? _metadataFromTrack(SourceTrack track) {
    if (track.likedAtSource == null) return null;
    return LikedAtMetadata(
      likedAt: track.likedAt,
      source: track.likedAtSource!,
      precision: track.likedAtPrecision ?? LikedAtMetadata.precisionUnknown,
    );
  }
}

final class CachedUnifiedFavorites {
  const CachedUnifiedFavorites({
    required this.tracks,
    required this.builtAt,
  });

  final List<UnifiedFavoriteTrack> tracks;
  final DateTime builtAt;
}

final class UnifiedFavoritesService {
  const UnifiedFavoritesService({
    this.capabilityMatrix = const ProviderCapabilityMatrix(),
  });

  final ProviderCapabilityMatrix capabilityMatrix;

  Future<List<UnifiedFavoriteTrack>> buildAllFavorites(
    StaticProviderRegistry registry,
  ) async {
    final result = await buildAllFavoritesWithResult(registry);
    return result.tracks;
  }

  Future<UnifiedFavoritesResult> buildAllFavoritesWithResult(
    StaticProviderRegistry registry, {
    FavoritesOverrideRegistry? overrides,
    LikedAtLedger? likedAtLedger,
  }) async {
    final eligibleEntries = capabilityMatrix.eligibleFavoritesEntries(registry);
    final failures = <ProviderId, String>{};
    final snapshots = <FavoriteSnapshot>[];

    for (final entry in eligibleEntries) {
      try {
        final snapshot = await entry.provider.pullFavorites();
        snapshots.add(snapshot);
      } catch (e) {
        failures[entry.descriptor.id] = e.toString();
      }
    }

    final bridgeLegacyLedger = likedAtLedger == null && overrides != null;
    final ledger = likedAtLedger ?? LikedAtLedger();
    if (bridgeLegacyLedger) {
      ledger.seedFromLegacy(overrides);
    }

    final result = buildFromSnapshots(
      snapshots,
      failures: failures,
      overrides: overrides,
      likedAtLedger: ledger,
    );

    if (bridgeLegacyLedger) {
      overrides.likedAtTracking
        ..clear()
        ..addEntries(
          ledger.entries.map((entry) => MapEntry(entry.ref, entry.metadata)),
        );
    }

    return result;
  }

  UnifiedFavoritesResult buildFromSnapshots(
    List<FavoriteSnapshot> snapshots, {
    Map<ProviderId, String> failures = const {},
    FavoritesOverrideRegistry? overrides,
    required LikedAtLedger likedAtLedger,
  }) {
    final groups = <_FavoriteGroup>[];

    _reconcileQqLedger(snapshots, likedAtLedger);

    for (final snapshot in snapshots) {
      for (final track in snapshot.tracks) {
        // Apply hidden track override
        if (overrides != null && overrides.hiddenTracks.contains(track.ref)) {
          continue;
        }

        final existingIndex = groups.indexWhere((group) {
          final rep = group.representative;
          // Check if there is an explicit split override
          if (overrides != null && overrides.shouldSplit(rep.ref, track.ref)) {
            return false;
          }
          // Check if there is an explicit merge override
          if (overrides != null && overrides.shouldMerge(rep.ref, track.ref)) {
            return true;
          }
          // Fallback to standard merge rule
          return _canMerge(rep, track);
        });

        if (existingIndex == -1) {
          groups.add(_FavoriteGroup(track));
        } else {
          groups[existingIndex].variants.add(track);
        }
      }
    }

    // Apply local liked-at only where provider time is not authoritative.
    for (final group in groups) {
      for (var i = 0; i < group.variants.length; i++) {
        final variant = group.variants[i];
        if (!_usesLocalLikedAt(variant.ref.providerId)) continue;
        final regMeta = likedAtLedger.likedAtFor(variant.ref);
        if (regMeta != null) {
          group.variants[i] = variant.copyWith(
            likedAt: regMeta.likedAt,
            likedAtSource: regMeta.source,
            likedAtPrecision: regMeta.precision,
            clearLikedAt: regMeta.likedAt == null,
          );
        }
      }
    }

    // Transitively merge groups if overrides dictate they should be merged
    if (overrides != null && overrides.mergeOverrides.isNotEmpty) {
      var mergedAny = true;
      while (mergedAny) {
        mergedAny = false;
        for (var i = 0; i < groups.length; i++) {
          for (var j = i + 1; j < groups.length; j++) {
            final trackI = groups[i].representative;
            final trackJ = groups[j].representative;
            if (overrides.shouldMerge(trackI.ref, trackJ.ref)) {
              groups[i].variants.addAll(groups[j].variants);
              groups.removeAt(j);
              mergedAny = true;
              break;
            }
          }
          if (mergedAny) break;
        }
      }
    }

    // Sort all groups by liked-at descending (newest first), across all providers.
    groups.sort(
        (a, b) => _bestLikedAt(b.variants).compareTo(_bestLikedAt(a.variants)));

    final tracks = [
      for (var index = 0; index < groups.length; index++)
        UnifiedFavoriteTrack(
          unifiedId: _unifiedIdFor(index, groups[index].representative),
          title: groups[index].representative.title,
          artists: groups[index].representative.artists,
          duration: groups[index].representative.duration,
          variants: List.unmodifiable(groups[index].variants),
        ),
    ];

    return UnifiedFavoritesResult(
      tracks: tracks,
      failures: Map.unmodifiable(failures),
    );
  }

  static bool _canMerge(SourceTrack left, SourceTrack right) {
    if (left.isrc != null && right.isrc != null && left.isrc == right.isrc) {
      return true;
    }

    final leftArtists = _normalizedArtists(left.artists);
    final rightArtists = _normalizedArtists(right.artists);
    final durationDelta = (left.duration - right.duration).inSeconds.abs();

    return _normalize(left.title) == _normalize(right.title) &&
        leftArtists == rightArtists &&
        durationDelta <= 2;
  }

  static void _reconcileQqLedger(
    List<FavoriteSnapshot> snapshots,
    LikedAtLedger ledger,
  ) {
    for (final snapshot in snapshots) {
      if (snapshot.providerId.value != 'qq_music') continue;
      final missing = <SourceTrack>[];
      for (final track in snapshot.tracks) {
        if (ledger.likedAtFor(track.ref) == null) {
          missing.add(track);
        }
      }
      if (missing.isEmpty) continue;
      final now = DateTime.now().toUtc();
      for (var i = 0; i < missing.length; i++) {
        ledger.record(
          missing[i].ref,
          LikedAtMetadata(
            likedAt: now.subtract(Duration(seconds: i)),
            source: LikedAtMetadata.sourceLocalEstimate,
            precision: LikedAtMetadata.precisionUnknown,
          ),
          updatedAt: now,
        );
      }
    }
  }

  static bool _usesLocalLikedAt(ProviderId providerId) {
    return providerId.value == 'qq_music';
  }

  static String _normalizedArtists(List<String> artists) {
    final normalized = artists.map(_normalize).toList(growable: false)..sort();
    return normalized.join('|');
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  static String _unifiedIdFor(int index, SourceTrack track) {
    final artistSlug =
        track.artists.isEmpty ? 'unknown' : _normalize(track.artists.first);
    return '${index}_${_normalize(track.title)}_$artistSlug'
        .replaceAll(' ', '_');
  }

  /// Returns the best available liked-at DateTime from a list of variants.
  /// NetEase/Kugou raw times are authoritative; QQ uses local ledger.
  static DateTime _bestLikedAt(List<SourceTrack> variants) {
    DateTime? providerExact;
    for (final track in variants) {
      if ((track.likedAtSource == LikedAtMetadata.sourceNeteaseRaw ||
              track.likedAtSource == LikedAtMetadata.sourceKugouRaw) &&
          track.likedAt != null) {
        if (providerExact == null || track.likedAt!.isAfter(providerExact)) {
          providerExact = track.likedAt;
        }
      }
    }
    if (providerExact != null) return providerExact;

    DateTime? best;
    for (final track in variants) {
      if (track.likedAt != null &&
          (best == null || track.likedAt!.isAfter(best))) {
        best = track.likedAt;
      }
    }
    return best ?? DateTime(1900);
  }
}

final class _FavoriteGroup {
  _FavoriteGroup(SourceTrack seed)
      : representative = seed,
        variants = [seed];

  final SourceTrack representative;
  final List<SourceTrack> variants;
}
