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
    //   Real exact likedAt from track -> update registry with exact precision.
    //   No likedAt -> fallback to sync detection estimation.
    if (overrides != null) {
      for (final snapshot in snapshots) {
        final tracksToEstimate = <SourceTrack>[];
        for (final track in snapshot.tracks) {
          if (track.likedAtSource == 'qq_import') {
            final existing = overrides.likedAtTracking[track.ref];
            if (track.likedAt != null) {
              // If we have a real precise likedAt from QQ Music, we can update or set it.
              // Overwrite if not in registry, or if it is in registry but was estimated (precision != exact).
              if (existing == null ||
                  existing.precision != LikedAtMetadata.precisionExact) {
                overrides.recordLikedAt(
                  track.ref,
                  LikedAtMetadata(
                    likedAt: track.likedAt!,
                    source: LikedAtMetadata.sourceQqImport,
                    precision: LikedAtMetadata.precisionExact,
                  ),
                );
              }
            } else {
              // Fallback: estimate if not in registry.
              if (existing == null) {
                tracksToEstimate.add(track);
              }
            }
          }
        }
        if (tracksToEstimate.isEmpty) continue;

        // Determine span: from last sync to now.
        // The last sync time ≈ the newest registry entry's likedAt for QQ.
        final now = DateTime.now().toUtc();
        DateTime? lastSync;
        for (final entry in overrides.likedAtTracking.entries) {
          if (entry.value.source == LikedAtMetadata.sourceQqImport &&
              entry.value.likedAt != null) {
            if (lastSync == null || entry.value.likedAt!.isAfter(lastSync)) {
              lastSync = entry.value.likedAt;
            }
          }
        }
        final refTime = lastSync ?? now.subtract(const Duration(days: 180));
        final span = now.difference(refTime);
        if (span.inSeconds <= 0) {
          // All get now if no elapsed time.
          for (var i = 0; i < tracksToEstimate.length; i++) {
            overrides.recordLikedAt(
              tracksToEstimate[i].ref,
              LikedAtMetadata(
                likedAt: now,
                source: LikedAtMetadata.sourceQqImport,
                precision: LikedAtMetadata.precisionUnknown,
              ),
            );
          }
        } else {
          final interval = Duration(
            seconds: (span.inSeconds ~/ tracksToEstimate.length)
                .clamp(1, 86400 * 180),
          );
          for (var i = 0; i < tracksToEstimate.length; i++) {
            overrides.recordLikedAt(
              tracksToEstimate[i].ref,
              LikedAtMetadata(
                likedAt: now.subtract(interval * i),
                source: LikedAtMetadata.sourceQqImport,
                precision: LikedAtMetadata.precisionUnknown,
              ),
            );
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

  /// Returns the best available liked-at DateTime from a list of variants.
  /// Picks the latest (newest) DateTime; no liked-at → DateTime(1900) → end.
  /// For merged groups (same song from multiple providers), netease_raw
  /// timestamp takes precedence over qq_import.
  static DateTime _bestLikedAt(List<SourceTrack> variants) {
    // Priority 1: netease_raw (authoritative when same song exists on QQ too)
    for (final track in variants) {
      if (track.likedAtSource == 'netease_raw' && track.likedAt != null) {
        return track.likedAt!;
      }
    }
    // Priority 2: app_action (user liked via this client)
    for (final track in variants) {
      if (track.likedAtSource == 'app_action' && track.likedAt != null) {
        return track.likedAt!;
      }
    }
    // Fallback: latest DateTime across all variants
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
