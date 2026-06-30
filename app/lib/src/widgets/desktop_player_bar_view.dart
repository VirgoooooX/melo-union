part of 'desktop_player_bar.dart';

class DesktopPlayerBar extends ConsumerWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final current = repository.queue.current?.track;
    final queue = repository.queue;
    return Container(
      height: MeloDimensions.desktopPlayerBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: MeloSpacing.xl),
      decoration: const BoxDecoration(
        color: MeloColors.surface,
        border: Border(top: BorderSide(color: MeloColors.border)),
      ),
      child: Row(
        children: [
          _PlayerArtwork(
            seed: current?.title ?? 'melo',
            artwork: current?.artwork,
          ),
          const SizedBox(width: MeloSpacing.sm),
          SizedBox(
            width: 210,
            child: current == null
                ? Text('从喜欢、歌单或推荐中选择歌曲',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: MeloColors.textSecondary))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(current.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(current.artists.join(' / '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: MeloColors.textSecondary)),
                    ],
                  ),
          ),
          const Spacer(),
          IconButton(
              onPressed: current == null ? null : repository.queuePrevious,
              icon: const Icon(Icons.skip_previous_rounded)),
          StreamBuilder<PlayerState>(
            stream: repository.playerStateStream,
            initialData: repository.audioPlayer.playerState,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final playing = state?.playing ?? repository.isPlaying;
              final completed =
                  state?.processingState == ProcessingState.completed;
              return FilledButton(
                onPressed: current == null
                    ? null
                    : completed
                        ? () => repository.seek(Duration.zero).then(
                              (_) => repository.togglePlayPause(),
                            )
                        : repository.togglePlayPause,
                style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10)),
                child: Icon(
                  playing && !completed
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              );
            },
          ),
          IconButton(
              onPressed: current == null ? null : repository.queueNext,
              icon: const Icon(Icons.skip_next_rounded)),
          const SizedBox(width: MeloSpacing.md),
          Expanded(
            flex: 3,
            child: _PlaybackProgress(repository: repository),
          ),
          const Spacer(),
          PopupMenuButton<AudioQuality>(
            tooltip: '音质',
            initialValue: repository.playbackQuality,
            onSelected: repository.setPlaybackQuality,
            itemBuilder: (context) => [
              for (final quality in AudioQuality.values)
                PopupMenuItem(
                  value: quality,
                  child: Row(
                    children: [
                      Icon(
                        quality == repository.playbackQuality
                            ? Icons.check_rounded
                            : Icons.graphic_eq_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(_qualityLabel(quality)),
                    ],
                  ),
                ),
            ],
            child: Chip(
              label: Text(_qualityLabel(repository.playbackQuality)),
              avatar: const Icon(Icons.high_quality_rounded, size: 17),
              side: const BorderSide(color: MeloColors.border),
              backgroundColor: MeloColors.surfaceMuted,
            ),
          ),
          const SizedBox(width: MeloSpacing.sm),
          IconButton(
            tooltip: '播放队列',
            onPressed:
                queue.entries.isEmpty ? null : () => _showQueue(context, ref),
            icon: Badge(
              label: Text('${queue.entries.length}'),
              isLabelVisible: queue.entries.isNotEmpty,
              child: const Icon(Icons.queue_music_outlined),
            ),
          ),
          const SizedBox(width: MeloSpacing.lg),
          const Icon(Icons.volume_up_outlined, color: MeloColors.textSecondary),
          SizedBox(
            width: 132,
            child: SliderTheme(
              data: _playerSliderTheme(context),
              child: Slider(
                value: repository.volume,
                onChanged: repository.setVolume,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQueue(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final repository = ref.read(demoRepositoryProvider);
        final queue = repository.queue;
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            itemCount: queue.entries.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: MeloColors.border),
            itemBuilder: (context, index) {
              final entry = queue.entries[index];
              final selected = index == queue.currentIndex;
              return ListTile(
                selected: selected,
                leading: QueueTrackCover(
                  seed: entry.track.title,
                  artwork: entry.track.artwork,
                  isPlaying: selected,
                ),
                title: Text(
                  entry.track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  entry.track.artists.join(' / '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(_formatDuration(entry.track.duration)),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(demoRepositoryProvider)
                      .selectTrackInQueue(entry.track.ref);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _PlaybackProgress extends StatelessWidget {
  const _PlaybackProgress({required this.repository});

  final DemoRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: repository.durationStream,
      initialData: repository.audioPlayer.duration,
      builder: (context, durationSnapshot) {
        final duration =
            durationSnapshot.data ?? repository.queue.current?.track.duration;
        return StreamBuilder<Duration>(
          stream: repository.positionStream,
          initialData: repository.audioPlayer.position,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final totalMs = duration?.inMilliseconds ?? 0;
            final positionMs = position.inMilliseconds.clamp(0, totalMs);
            return Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    _formatDuration(Duration(milliseconds: positionMs)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: _playerSliderTheme(context),
                    child: Slider(
                      value: totalMs == 0 ? 0 : positionMs.toDouble(),
                      min: 0,
                      max: totalMs == 0 ? 1 : totalMs.toDouble(),
                      onChanged: totalMs == 0
                          ? null
                          : (value) => repository.seek(
                                Duration(milliseconds: value.round()),
                              ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    _formatDuration(duration ?? Duration.zero),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PlayerArtwork extends StatelessWidget {
  const _PlayerArtwork({required this.seed, this.artwork});
  final String seed;
  final Uri? artwork;

  @override
  Widget build(BuildContext context) {
    if (artwork != null && artwork!.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: MeloRadii.sm,
        child: Image.network(
          artwork!.toString(),
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://music.163.com',
          },
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: MeloRadii.sm,
        gradient: LinearGradient(colors: [
          HSLColor.fromAHSL(1, hue.toDouble(), .55, .62).toColor(),
          HSLColor.fromAHSL(1, (hue + 50) % 360, .56, .38).toColor()
        ]),
      ),
      child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
    );
  }
}

String _qualityLabel(AudioQuality quality) => switch (quality) {
      AudioQuality.low => '标准',
      AudioQuality.standard => '较高',
      AudioQuality.high => '极高',
      AudioQuality.lossless => '无损',
    };

SliderThemeData _playerSliderTheme(BuildContext context) {
  return SliderTheme.of(context).copyWith(
    trackHeight: 4,
    activeTrackColor: MeloColors.primary600,
    inactiveTrackColor: MeloColors.primary100.withValues(alpha: .72),
    disabledActiveTrackColor: MeloColors.primary100,
    disabledInactiveTrackColor: MeloColors.border,
    thumbColor: MeloColors.primary600,
    overlayColor: MeloColors.primary100.withValues(alpha: .35),
    valueIndicatorColor: MeloColors.primary700,
  );
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
