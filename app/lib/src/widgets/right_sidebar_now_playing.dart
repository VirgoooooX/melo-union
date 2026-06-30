part of 'right_sidebar.dart';

class RightSidebar extends ConsumerWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final track = repository.queue.current?.track;
    return Material(
      color: MeloColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '正在播放',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '更多',
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _NowPlayingCard(track: track),
            const SizedBox(height: 22),
            Row(
              children: [
                Text(
                  '播放队列',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${repository.queue.entries.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: null,
                  child: const Text('清空'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Expanded(child: _QueuePreview()),
            if (track != null) ...[
              const Divider(color: MeloColors.border),
              _Meta(
                label: '来源 / 收藏状态',
                value:
                    '${_providerName(track)} · ${track.isFavorited ? '已收藏' : '未收藏'}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NowPlayingCard extends ConsumerWidget {
  const _NowPlayingCard({required this.track});
  final dynamic track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (track == null) {
      return _Panel(
          child: Text('播放一首歌后，这里会展示当前歌曲、来源和收藏状态。',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: MeloColors.textSecondary, height: 1.5)));
    }
    final name = _providerName(track);
    final isNetease = name == '网易云';
    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: track.artwork != null && track.artwork!.toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: MeloRadii.md,
                    child: Image.network(
                      track.artwork!.toString(),
                      fit: BoxFit.cover,
                      headers: const {
                        'User-Agent':
                            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                        'Referer': 'https://music.163.com',
                      },
                      errorBuilder: (_, __, ___) =>
                          _buildPlaceholder(track.title),
                    ),
                  )
                : _buildPlaceholder(track.title),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  track.artists.join(' / '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MeloColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _ProviderPill(label: name, isNetease: isNetease),
                    if (track.isFavorited)
                      const _StatusPill(
                        icon: Icons.favorite_rounded,
                        label: '已收藏',
                      ),
                  ],
                ),
              ],
            ),
          ),
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
        decoration: BoxDecoration(
            color: MeloColors.surface,
            borderRadius: MeloRadii.lg,
            border: Border.all(color: MeloColors.border),
            boxShadow: MeloShadows.card),
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
        decoration: BoxDecoration(
            color: isNetease
                ? MeloColors.neteaseBackground
                : MeloColors.qqBackground,
            borderRadius: MeloRadii.sm),
        child: Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isNetease
                    ? MeloColors.neteaseForeground
                    : MeloColors.qqForeground,
                fontWeight: FontWeight.w700)),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF1F3),
          borderRadius: MeloRadii.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: MeloColors.favorite),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MeloColors.favorite,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: MeloColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600))
        ]),
      );
}

String _providerName(dynamic track) {
  final providerId = track.ref.providerId.value;
  if (providerId.contains('aurora') || providerId.contains('netease')) {
    return '网易云';
  }
  if (providerId.contains('beacon')) return 'QQ音乐';
  return providerId;
}

Widget _buildPlaceholder(String seed) {
  final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: MeloRadii.md,
      gradient: LinearGradient(
        colors: [
          HSLColor.fromAHSL(1, hue.toDouble(), .52, .64).toColor(),
          HSLColor.fromAHSL(1, (hue + 42) % 360, .54, .42).toColor(),
        ],
      ),
    ),
    child: const Icon(Icons.graphic_eq_rounded, size: 54, color: Colors.white),
  );
}
