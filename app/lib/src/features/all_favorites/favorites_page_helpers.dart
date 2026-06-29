part of 'all_favorites_page.dart';

class _TrackCover extends StatelessWidget {
  const _TrackCover({required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    final hue =
        seed.codeUnits.fold<int>(0, (total, value) => total + value) % 360;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: MeloRadii.sm,
        gradient: LinearGradient(colors: [
          HSLColor.fromAHSL(1, hue.toDouble(), .58, .62).toColor(),
          HSLColor.fromAHSL(1, (hue + 60) % 360, .58, .4).toColor()
        ]),
      ),
      child:
          const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.provider});
  final ProviderId provider;

  @override
  Widget build(BuildContext context) {
    final isNetease = provider.value.contains('aurora');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: isNetease
              ? MeloColors.neteaseBackground
              : MeloColors.qqBackground,
          borderRadius: MeloRadii.sm),
      child: Text(
        providerLabel(provider),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isNetease
                ? MeloColors.neteaseForeground
                : MeloColors.qqForeground,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

String providerLabel(ProviderId id) {
  if (id.value.contains('aurora')) return '网易云';
  if (id.value.contains('beacon')) return 'QQ音乐';
  return id.value;
}

String formatDuration(Duration value) {
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${value.inMinutes}:$seconds';
}
