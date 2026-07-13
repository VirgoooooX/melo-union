import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import 'demo_repository.dart';

extension UnifiedQueuePlayback on DemoRepository {
  /// Builds a queue from the currently visible unified favorites.
  ///
  /// Each unified row contributes its first playable source. Individual row
  /// playback is intentionally single-track; it must not enqueue the visible
  /// list unless the user explicitly presses play-all.
  Future<void> playUnifiedTracks(List<UnifiedFavoriteTrack> tracks) async {
    final sources = <SourceTrack>[
      for (final track in tracks)
        if (selectUnifiedPlaybackSource(track) case final source?) source,
    ];
    await playTracks(sources);
  }

  Future<void> playUnifiedTracksFrom(
    List<UnifiedFavoriteTrack> _,
    UnifiedFavoriteTrack selected, {
    String? providerId,
  }) async {
    final source =
        selectUnifiedPlaybackSource(selected, providerId: providerId);
    if (source != null) await playTrack(source);
  }
}
