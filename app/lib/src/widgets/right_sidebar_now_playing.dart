part of 'right_sidebar.dart';

class RightSidebar extends ConsumerWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final track = repository.queue.current?.track;
    return Container(
      color: MeloColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('正在播放', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: MeloSpacing.md),
          _NowPlayingCard(track: track),
          const SizedBox(height: MeloSpacing.xl),
          Row(
            children: [
              Text('播放队列', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${repository.queue.entries.length} 首', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MeloColors.textSecondary)),
            ],
          ),
          const SizedBox(height: MeloSpacing.sm),
          const Expanded(child: _QueuePreview()),
        ],
      ),
    );
  }
}

class _NowPlayingCard extends ConsumerWidget {
  const _NowPlayingCard({required this.track});
  final dynamic track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    if (track == null) {
      return _Panel(child: Text('播放一首歌后，这里会展示当前歌曲、来源和收藏状态。', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MeloColors.textSecondary, height: 1.5)));
    }
    final isNetease = track.ref.providerId.value.contains('aurora');
    final name = isNetease ? '网易云' : 'QQ音乐';
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 146,
            decoration: const BoxDecoration(borderRadius: MeloRadii.md, gradient: LinearGradient(colors: [Color(0xFF1EB5A7), Color(0xFF3172B8)])),
            child: const Icon(Icons.graphic_eq_rounded, size: 54, color: Colors.white),
          ),
          const SizedBox(height: MeloSpacing.md),
          Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(track.artists.join(' / '), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MeloColors.textSecondary)),
          const SizedBox(height: MeloSpacing.sm),
          _ProviderPill(label: name, isNetease: isNetease),
          const SizedBox(height: MeloSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: repository.queuePrevious, icon: const Icon(Icons.skip_previous_rounded)),
              FilledButton(onPressed: repository.refreshPlaybackTicket, style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(10)), child: const Icon(Icons.play_arrow_rounded)),
              IconButton(onPressed: repository.queueNext, icon: const Icon(Icons.skip_next_rounded)),
            ],
          ),
          const Divider(color: MeloColors.border),
          _Meta(label: '播放来源', value: name),
          _Meta(label: '收藏状态', value: track.isFavorited ? '已喜欢' : '未喜欢'),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MeloSpacing.md),
        decoration: BoxDecoration(color: MeloColors.surfaceMuted, borderRadius: MeloRadii.lg, border: Border.all(color: MeloColors.border)),
        child: child,
      );
}

class _ProviderPill extends StatelessWidget {
  const _ProviderPill({required this.label, required this.isNetease});
  final String label;
  final bool isNetease;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: isNetease ? MeloColors.neteaseBackground : MeloColors.qqBackground, borderRadius: MeloRadii.sm),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isNetease ? MeloColors.neteaseForeground : MeloColors.qqForeground, fontWeight: FontWeight.w700)),
      );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MeloColors.textSecondary)), const Spacer(), Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))]),
      );
}
