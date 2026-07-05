import 'package:flutter/material.dart';

import '../design/melo_tokens.dart';
import 'melo_components.dart';
import 'melo_file_cached_image_provider.dart';

class QueueTrackCover extends StatefulWidget {
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
  State<QueueTrackCover> createState() => _QueueTrackCoverState();
}

class _QueueTrackCoverState extends State<QueueTrackCover> {
  late final DisposableBuildContext<_QueueTrackCoverState> _scrollAwareContext =
      DisposableBuildContext(this);

  @override
  void dispose() {
    _scrollAwareContext.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _cover()),
          if (widget.isPlaying)
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: MeloColors.primary600,
                  borderRadius: MeloRadii.pill,
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
    final imageUri = widget.artwork;
    if (imageUri != null && imageUri.toString().isNotEmpty) {
      final baseProvider = MeloFileCachedNetworkImageProvider(
        imageUri.toString(),
        headers: meloArtworkHeaders,
      );
      final imageProvider = ScrollAwareImageProvider<Object>(
        context: _scrollAwareContext,
        imageProvider: baseProvider,
      );
      return ClipRRect(
        borderRadius: MeloRadii.sm,
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => MeloArtworkPlaceholder(seed: widget.seed),
        ),
      );
    }
    return MeloArtworkPlaceholder(seed: widget.seed);
  }
}
