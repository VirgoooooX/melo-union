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

  /// Best available liked-at metadata across all variants.
  /// Prefers app_action (exact) over sync_detected (approximate) over anything else.
  LikedAtMetadata? get bestLikedAt {
    LikedAtMetadata? best;
    for (final variant in variants) {
      final candidate = _metadataFromTrack(variant);
      if (candidate == null) continue;
      if (best == null || _rank(candidate) > _rank(best)) {
        best = candidate;
      }
    }
    return best;
  }

  static int _rank(LikedAtMetadata m) {
    if (m.source == LikedAtMetadata.sourceAppAction &&
        m.precision == LikedAtMetadata.precisionExact) {
      return 4;
    }
    if (m.source == LikedAtMetadata.sourceAppAction) return 3;
    if (m.source == LikedAtMetadata.sourceNeteaseRaw) return 3;
    if (m.source == LikedAtMetadata.sourceSyncDetected) return 2;
    if (m.source == LikedAtMetadata.sourceQqImport) return 1;
    return 0;
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

    final groups = <_FavoriteGroup>[];

    // Sync QQ / external-source liked-at to the registry:
    //   First detection → record current time as likedAt (qq_import / sync_detected).
    //   Already seen → do nothing (registry keeps the original detection time).
    if (overrides != null) {
      final now = DateTime.now().toUtc();
      for (final snapshot in snapshots) {
        for (final track in snapshot.tracks) {
          if (track.likedAtSource == 'qq_import' ||
              track.likedAtSource == null) {
            final existing = overrides.likedAtFor(track.ref);
            if (existing == null) {
              // First time we've seen this track → freeze the current time.
              overrides.recordLikedAt(
                track.ref,
                LikedAtMetadata(
                  likedAt: now,
                  source: LikedAtMetadata.sourceQqImport,
                  precision: LikedAtMetadata.precisionUnknown,
                ),
              );
            }
          }
        }
      }
    }
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

    // Apply registry liked-at overrides to SourceTrack variants
    for (final group in groups) {
      for (var i = 0; i < group.variants.length; i++) {
        final variant = group.variants[i];
        final regMeta = overrides?.likedAtFor(variant.ref);
        if (regMeta != null) {
          // Registry data (app_action or sync_detected) takes precedence
          // over what the provider returned (qq_import / unknown).
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

    return UnifiedFavoritesResult(tracks: tracks, failures: failures);
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
}

final class _FavoriteGroup {
  _FavoriteGroup(SourceTrack seed)
      : representative = seed,
        variants = [seed];

  final SourceTrack representative;
  final List<SourceTrack> variants;
}
