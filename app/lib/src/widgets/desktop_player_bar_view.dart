part of 'desktop_player_bar.dart';

class DesktopPlayerBar extends ConsumerWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final current = repository.queue.current?.track;
    return Container(
      height: MeloDimensions.desktopPlayerBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: MeloSpacing.xl),
      decoration: const BoxDecoration(
        color: MeloColors.surface,
        border: Border(top: BorderSide(color: MeloColors.border)),
      ),
      child: Row(
        children: [
          _PlayerArtwork(seed: current?.title ?? 'melo'),
          const SizedBox(width: MeloSpacing.sm),
          SizedBox(
            width: 210,
            child: current == null
                ? Text('从喜欢、歌单或推荐中选择歌曲', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MeloColors.textSecondary))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(current.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(current.artists.join(' / '), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MeloColors.textSecondary)),
                    ],
                  ),
          ),
          const Spacer(),
          IconButton(onPressed: current == null ? null : repository.queuePrevious, icon: const Icon(Icons.skip_previous_rounded)),
          FilledButton(
            onPressed: current == null ? null : repository.refreshPlaybackTicket,
            style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(10)),
            child: const Icon(Icons.play_arrow_rounded),
          ),
          IconButton(onPressed: current == null ? null : repository.queueNext, icon: const Icon(Icons.skip_next_rounded)),
          const SizedBox(width: MeloSpacing.md),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text('0:42', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                const Expanded(child: LinearProgressIndicator(value: .28, minHeight: 3, backgroundColor: MeloColors.primary100)),
                const SizedBox(width: 8),
                Text('3:10', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Spacer(),
          Badge(label: Text('${repository.queue.entries.length}'), isLabelVisible: repository.queue.entries.isNotEmpty, child: const Icon(Icons.queue_music_outlined)),
          const SizedBox(width: MeloSpacing.lg),
          const Icon(Icons.volume_up_outlined, color: MeloColors.textSecondary),
          SizedBox(width: 72, child: Slider(value: .7, onChanged: (_) {})),
        ],
      ),
    );
  }
}

class _PlayerArtwork extends StatelessWidget {
  const _PlayerArtwork({required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: MeloRadii.sm,
        gradient: LinearGradient(colors: [HSLColor.fromAHSL(1, hue.toDouble(), .55, .62).toColor(), HSLColor.fromAHSL(1, (hue + 50) % 360, .56, .38).toColor()]),
      ),
      child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
    );
  }
}
