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
        if (track.variants.isNotEmpty) track.variants.first,
    ];
    await playTracks(sources);
  }
}
