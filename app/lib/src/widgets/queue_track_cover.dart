import 'package:flutter/material.dart';

import '../design/melo_tokens.dart';

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
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://music.163.com',
          },
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
    return Container(
      decoration: BoxDecoration(
        borderRadius: MeloRadii.sm,
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .52, .64).toColor(),
            HSLColor.fromAHSL(1, (hue + 42) % 360, .54, .42).toColor(),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
