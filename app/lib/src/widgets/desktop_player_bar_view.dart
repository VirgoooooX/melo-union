part of 'desktop_player_bar.dart';

class DesktopPlayerBar extends ConsumerWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    final current = ref.watch(
      demoRepositoryProvider.select((r) => r.queue.current?.track),
    );
    final queue = ref.watch(
      demoRepositoryProvider.select((r) => r.queue),
    );
    return Container(
      height: MeloDimensions.desktopPlayerBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: MeloSpacing.xl),
      decoration: const BoxDecoration(
        color: MeloColors.surface,
        border: Border(top: BorderSide(color: MeloColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          return Row(
            children: [
              SizedBox(
                width: compact ? 226 : 276,
                child: _CurrentTrackSummary(
                  current: current,
                ),
              ),
              const SizedBox(width: MeloSpacing.md),
              const SizedBox(
                height: 46,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: MeloColors.border,
                ),
              ),
              const SizedBox(width: MeloSpacing.md),
              Expanded(
                child: Row(
                  children: [
                    _TransportControls(
                      current: current,
                      compact: compact,
                      repository: repository,
                    ),
                    const SizedBox(width: MeloSpacing.md),
                    Expanded(child: _PlaybackProgress(repository: repository)),
                  ],
                ),
              ),
              const SizedBox(width: MeloSpacing.md),
              _QualityMenuButton(repository: repository),
              const SizedBox(width: MeloSpacing.sm),
              _VolumeControl(
                repository: repository,
                width: compact ? 108 : 148,
              ),
              const SizedBox(width: MeloSpacing.xs),
              (() {
                final mode = ref.watch(rightSidebarModeProvider);
                return IconButton(
                  tooltip: mode == RightSidebarMode.queue ? '显示歌词' : '显示播放队列',
                  onPressed: () {
                    ref.read(rightSidebarModeProvider.notifier).update(
                        (state) => state == RightSidebarMode.queue
                            ? RightSidebarMode.lyrics
                            : RightSidebarMode.queue);
                  },
                  icon: Badge(
                    label: Text('${queue.entries.length}'),
                    isLabelVisible: queue.entries.isNotEmpty,
                    child: Icon(
                      mode == RightSidebarMode.queue
                          ? Icons.queue_music_outlined
                          : Icons.lyrics_outlined,
                    ),
                  ),
                );
              })(),
            ],
          );
        },
      ),
    );
  }
}

class _CurrentTrackSummary extends StatelessWidget {
  const _CurrentTrackSummary({
    required this.current,
  });

  final SourceTrack? current;

  @override
  Widget build(BuildContext context) {
    final track = current;
    return Row(
      children: [
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showMeloFullScreenPlayer(context),
              child: Row(
                children: [
                  _PlayerArtwork(
                    seed: track?.title ?? 'melo',
                    artwork: track?.artwork,
                    size: 52,
                  ),
                  const SizedBox(width: MeloSpacing.sm),
                  Expanded(
                    child: track == null
                        ? Text(
                            '从喜欢、歌单或推荐中选择歌曲',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: MeloColors.textSecondary,
                                    ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artists.join(' / '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: MeloColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: MeloSpacing.xs),
        if (track != null) MeloFavoriteButton(track: track),
      ],
    );
  }
}

class _TransportControls extends ConsumerWidget {
  const _TransportControls({
    required this.current,
    required this.compact,
    required this.repository,
  });

  final SourceTrack? current;
  final bool compact;
  final DemoRepository repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shuffleEnabled =
        ref.watch(demoRepositoryProvider.select((r) => r.shuffleEnabled));
    final repeatMode =
        ref.watch(demoRepositoryProvider.select((r) => r.repeatMode));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact)
          IconButton(
            tooltip: shuffleEnabled ? '关闭随机播放' : '随机播放',
            onPressed: current == null ? null : repository.toggleShuffle,
            icon: Icon(
              Icons.shuffle_rounded,
              color: shuffleEnabled
                  ? MeloColors.primary700
                  : MeloColors.textSecondary,
            ),
          ),
        IconButton(
          tooltip: '上一首',
          onPressed: current == null ? null : repository.queuePrevious,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        StreamBuilder<PlayerState>(
          stream: repository.playerStateStream,
          initialData: repository.audioPlayer.playerState,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final playing = state?.playing ?? repository.isPlaying;
            final completed =
                state?.processingState == ProcessingState.completed;
            final starting = repository.isPlaybackStarting && !completed;
            return MeloPlayButton(
              isPlaying: playing,
              isStarting: starting,
              isCompleted: completed,
              enabled: current != null,
              size: 42,
              onPressed: repository.togglePlayPause,
              onCompletedTap: () => repository.seek(Duration.zero).then(
                    (_) => repository.togglePlayPause(),
                  ),
            );
          },
        ),
        IconButton(
          tooltip: '下一首',
          onPressed: current == null ? null : repository.queueNext,
          icon: const Icon(Icons.skip_next_rounded),
        ),
        if (!compact)
          IconButton(
            tooltip: _repeatTooltip(repeatMode),
            onPressed: current == null ? null : repository.cycleRepeatMode,
            icon: Icon(
              repeatMode == PlaybackRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: repeatMode == PlaybackRepeatMode.off
                  ? MeloColors.textSecondary
                  : MeloColors.primary700,
            ),
          ),
      ],
    );
  }
}

class _QualityMenuButton extends ConsumerWidget {
  const _QualityMenuButton({required this.repository});

  final DemoRepository repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackQuality = ref.watch(
      demoRepositoryProvider.select((r) => r.playbackQuality),
    );

    return PopupMenuButton<AudioQuality>(
      tooltip: '音质',
      initialValue: playbackQuality,
      onSelected: repository.setPlaybackQuality,
      itemBuilder: (context) => [
        for (final quality in AudioQuality.values)
          PopupMenuItem(
            value: quality,
            child: Row(
              children: [
                Icon(
                  quality == playbackQuality
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
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: MeloColors.surfaceMuted,
          border: Border.all(color: MeloColors.border),
          borderRadius: MeloRadii.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.high_quality_rounded, size: 17),
            const SizedBox(width: 6),
            Text(
              _qualityLabel(playbackQuality),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeControl extends ConsumerWidget {
  const _VolumeControl({
    required this.repository,
    required this.width,
  });

  final DemoRepository repository;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(
      demoRepositoryProvider.select((r) => r.volume),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.volume_up_outlined, color: MeloColors.textSecondary),
        SizedBox(
          width: width,
          child: SliderTheme(
            data: _playerSliderTheme(context),
            child: Slider(
              value: volume,
              onChanged: repository.setVolume,
            ),
          ),
        ),
      ],
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
  const _PlayerArtwork({
    required this.seed,
    required this.size,
    this.artwork,
  });

  final String seed;
  final Uri? artwork;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (artwork != null && artwork!.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: MeloRadii.sm,
        child: Image.network(
          artwork!.toString(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          headers: meloArtworkHeaders,
          errorBuilder: (_, __, ___) => MeloArtworkPlaceholder(
            seed: seed,
            size: size,
          ),
        ),
      );
    }
    return MeloArtworkPlaceholder(seed: seed, size: size);
  }
}

String _qualityLabel(AudioQuality quality) => switch (quality) {
      AudioQuality.low => '标准',
      AudioQuality.standard => '较高',
      AudioQuality.high => '极高',
      AudioQuality.lossless => '无损',
    };

String _repeatTooltip(PlaybackRepeatMode mode) => switch (mode) {
      PlaybackRepeatMode.off => '开启列表循环',
      PlaybackRepeatMode.all => '切换到单曲循环',
      PlaybackRepeatMode.one => '关闭循环播放',
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
