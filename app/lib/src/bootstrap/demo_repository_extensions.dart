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
        if (track.variants.any((variant) => variant.isPlayable))
          track.variants.firstWhere((variant) => variant.isPlayable),
    ];
    await playTracks(sources);
  }

  Future<void> playUnifiedTracksFrom(
    List<UnifiedFavoriteTrack> _,
    UnifiedFavoriteTrack selected, {
    String? providerId,
  }) async {
    List<SourceTrack> playableVariantsFor(UnifiedFavoriteTrack track) {
      final variants = providerId == null
          ? track.variants
          : track.variants.where(
              (variant) => variant.ref.providerId.value == providerId,
            );
      return variants.where((variant) => variant.isPlayable).toList();
    }

    final selectedVariants = playableVariantsFor(selected);
    if (selectedVariants.isEmpty) {
      return;
    }

    await playTrack(selectedVariants.first);
  }
}
