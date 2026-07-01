import 'package:flutter/material.dart';

import '../design/melo_tokens.dart';
import 'melo_components.dart';

class QueueTrackCover extends StatelessWidget {
  const QueueTrackCover({
    super.key,
    required this.seed,
    this.artwork,
    this.isPlaying = false,
  });

  final String seed;
  final Uri? artwork;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _cover()),
          if (isPlaying)
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: MeloColors.primary600,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: MeloColors.surface, width: 2),
                ),
                child: const Icon(
                  Icons.equalizer_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cover() {
    final imageUri = artwork;
    if (imageUri != null && imageUri.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: MeloRadii.sm,
        child: Image.network(
          imageUri.toString(),
          fit: BoxFit.cover,
          headers: meloArtworkHeaders,
          errorBuilder: (_, __, ___) => MeloArtworkPlaceholder(seed: seed),
        ),
      );
    }
    return MeloArtworkPlaceholder(seed: seed);
  }
}
