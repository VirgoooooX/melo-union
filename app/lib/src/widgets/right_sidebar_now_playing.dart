part of 'right_sidebar.dart';

class RightSidebar extends ConsumerWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final track = repository.queue.current?.track;
    final mode = ref.watch(rightSidebarModeProvider);
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
            Container(
              height: 40,
              alignment: Alignment.centerLeft,
              child: mode == RightSidebarMode.queue
                  ? Row(
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
                          onPressed: repository.queue.entries.isEmpty
                              ? null
                              : repository.clearQueue,
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('清空'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Text(
                          '歌词',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: mode == RightSidebarMode.queue
                  ? const _QueuePreview()
                  : _LyricsView(track: track),
            ),
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
          child: Text('播放一首歌后，这里会展示当前歌曲、歌词和播放队列。',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: MeloColors.textSecondary, height: 1.5)));
    }
    final presentation = meloProviderPresentation(track.ref.providerId);
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
                    _ProviderPill(presentation: presentation),
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
  const _ProviderPill({required this.presentation});
  final MeloProviderPresentation presentation;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: presentation.backgroundColor, borderRadius: MeloRadii.sm),
        child: Text(presentation.shortName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: presentation.foregroundColor,
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

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

List<LyricLine> _parseLyrics(String lyrics) {
  final List<LyricLine> list = [];
  final lines = lyrics.split('\n');
  final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');
  for (final line in lines) {
    final match = regex.firstMatch(line);
    if (match != null) {
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final msStr = match.group(3)!;
      final milliseconds = int.parse(msStr.padRight(3, '0').substring(0, 3));
      final time = Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
      final text = line.substring(match.end).trim();
      list.add(LyricLine(time: time, text: text));
    } else {
      final cleanText =
          line.replaceAll(RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]'), '').trim();
      if (cleanText.isNotEmpty) {
        list.add(LyricLine(time: Duration.zero, text: cleanText));
      }
    }
  }
  list.sort((a, b) => a.time.compareTo(b.time));
  return list;
}

int _getActiveIndex(List<LyricLine> lines, Duration position) {
  int activeIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].time <= position) {
      activeIndex = i;
    } else {
      break;
    }
  }
  return activeIndex == -1 ? 0 : activeIndex;
}

class _LyricsView extends ConsumerStatefulWidget {
  const _LyricsView({required this.track});
  final dynamic track;

  @override
  ConsumerState<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<_LyricsView> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive(int index) {
    if (index == _lastActiveIndex) return;
    _lastActiveIndex = index;
    if (index >= 0 && index < _itemKeys.length) {
      final context = _itemKeys[index].currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      } else if (_scrollController.hasClients) {
        final targetOffset = (index * 48.0) - 100.0;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.track == null) {
      return const Center(child: Text('暂无播放歌曲'));
    }

    final repository = ref.watch(demoRepositoryProvider);
    final lyricsAsync = ref.watch(lyricsProvider(widget.track.ref));

    return lyricsAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => Center(child: Text('获取歌词失败: $error')),
      data: (lyrics) {
        if (lyrics == null || lyrics.trim().isEmpty) {
          return const Center(child: Text('暂无歌词'));
        }

        final parsedLines = _parseLyrics(lyrics);

        if (_itemKeys.length != parsedLines.length) {
          _itemKeys.clear();
          for (int i = 0; i < parsedLines.length; i++) {
            _itemKeys.add(GlobalKey());
          }
        }

        return StreamBuilder<Duration>(
          stream: repository.positionStream,
          initialData: repository.audioPlayer.position,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final activeIndex = _getActiveIndex(parsedLines, position);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToActive(activeIndex);
            });

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: parsedLines.length,
              itemBuilder: (context, index) {
                final line = parsedLines[index];
                final isActive = index == activeIndex;
                return Container(
                  key: _itemKeys[index],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  alignment: Alignment.center,
                  child: Text(
                    line.text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isActive
                              ? MeloColors.primary700
                              : MeloColors.textSecondary,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: isActive ? 16 : 14,
                        ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
