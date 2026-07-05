import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import 'demo_repository.dart';

extension UnifiedQueuePlayback on DemoRepository {
  /// Builds a queue from the currently visible unified favorites.
  ///
  /// Each unified row contributes its first playable source. Individual row
  /// playback still retains the full source-variant queue used for fallback.
  Future<void> playUnifiedTracks(List<UnifiedFavoriteTrack> tracks) async {
    final sources = <SourceTrack>[
      for (final track in tracks)
        if (track.variants.any((variant) => variant.isPlayable))
          track.variants.firstWhere((variant) => variant.isPlayable),
    ];
    await playTracks(sources);
  }

  Future<void> playUnifiedTracksFrom(
    List<UnifiedFavoriteTrack> tracks,
    UnifiedFavoriteTrack selected, {
    String? providerId,
  }) async {
    SourceTrack? sourceFor(UnifiedFavoriteTrack track) {
      final variants = providerId == null
          ? track.variants
          : track.variants
              .where((variant) => variant.ref.providerId.value == providerId);
      for (final variant in variants) {
        if (variant.isPlayable) return variant;
      }
      return null;
    }

    final sources = <SourceTrack>[
      for (final track in tracks)
        if (sourceFor(track) case final source?) source,
    ];
    final selectedSource = sourceFor(selected);
    if (selectedSource == null) {
      return;
    }
    await playTracksFrom(sources, selectedSource.ref);
  }
}
