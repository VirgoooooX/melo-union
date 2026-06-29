import 'package:music_domain/music_domain.dart';

import 'demo_repository.dart';

extension UnifiedQueuePlayback on DemoRepository {
  /// Creates a single queue from the currently visible unified tracks.
  ///
  /// The first playable source is selected for each unified track; source-level
  /// fallback remains available when a track is played individually.
  Future<void> playUnifiedTracks(
    List<UnifiedFavoriteTrack> tracks,
  ) async {
    final firstSources = <SourceTrack>[
      for (final track in tracks)
        if (track.variants.isNotEmpty) track.variants.first,
    ];
    if (firstSources.isEmpty) return;

    await playTrack(firstSources.first);
    for (final track in firstSources.skip(1)) {
      enqueueTrack(track);
    }
  }
}
