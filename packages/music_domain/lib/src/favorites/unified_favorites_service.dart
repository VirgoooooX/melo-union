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

    groups.sort((left, right) {
      final byTitle = left.representative.title.toLowerCase().compareTo(
            right.representative.title.toLowerCase(),
          );
      if (byTitle != 0) {
        return byTitle;
      }
      return left.representative.artists.join(',').toLowerCase().compareTo(
            right.representative.artists.join(',').toLowerCase(),
          );
    });

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
