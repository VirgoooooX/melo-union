part of 'all_favorites_page.dart';

class _TrackCover extends StatelessWidget {
  const _TrackCover({
    required this.seed,
    required this.isPlaying,
    this.artwork,
  });

  final String seed;
  final bool isPlaying;
  final Uri? artwork;

  @override
  Widget build(BuildContext context) {
    if (artwork != null && artwork!.toString().isNotEmpty) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: MeloRadii.md,
          boxShadow: isPlaying ? MeloShadows.control : const [],
        ),
        child: ClipRRect(
          borderRadius: MeloRadii.md,
          child: Image.network(
            artwork!.toString(),
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            headers: const {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://music.163.com',
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('TRACK IMAGE ERROR: $error for url: $artwork');
              return _buildPlaceholder();
            },
          ),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final hue =
        seed.codeUnits.fold<int>(0, (total, value) => total + value) % 360;
    final first = HSLColor.fromAHSL(1, hue.toDouble(), .58, .62).toColor();
    final second = HSLColor.fromAHSL(1, (hue + 58) % 360, .58, .37).toColor();
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: MeloRadii.md,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [first, second],
        ),
        boxShadow: isPlaying ? MeloShadows.control : const [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -8,
            top: -10,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .24)),
            ),
            child: Icon(
              isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
              color: Colors.white,
              size: isPlaying ? 16 : 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.provider});

  final ProviderId provider;

  @override
  Widget build(BuildContext context) {
    final isNetease = provider.value.contains('aurora') || provider.value.contains('netease');
    final foreground =
        isNetease ? MeloColors.neteaseForeground : MeloColors.qqForeground;
    final background =
        isNetease ? MeloColors.neteaseBackground : MeloColors.qqBackground;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: MeloRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration:
                BoxDecoration(color: foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            providerLabel(provider),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

String providerLabel(ProviderId id) {
  if (id.value.contains('aurora') || id.value.contains('netease')) return '网易云';
  if (id.value.contains('beacon')) return 'QQ音乐';
  return id.value;
}

String formatDuration(Duration value) {
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${value.inMinutes}:$seconds';
}
