import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:window_manager/window_manager.dart';

import '../bootstrap/demo_repository.dart';
import '../design/melo_tokens.dart';
import '../presentation/provider_presentation.dart';
import 'lyrics_provider.dart';
import 'melo_components.dart';
import 'right_sidebar.dart';

Future<void> showMeloFullScreenPlayer(
  BuildContext context, {
  RightSidebarMode initialMode = RightSidebarMode.lyrics,
}) {
  ProviderScope.containerOf(context, listen: false)
      .read(rightSidebarModeProvider.notifier)
      .state = initialMode;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭全屏播放器',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, __) => const MeloFullScreenPlayer(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class MeloFullScreenPlayer extends ConsumerWidget {
  const MeloFullScreenPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final track = repository.queue.current?.track;
    final mode = ref.watch(rightSidebarModeProvider);
    final useWindowChrome = MediaQuery.sizeOf(context).width >= 960;
    final windowRadius = useWindowChrome ? MeloRadii.window : BorderRadius.zero;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: windowRadius,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 420) {
              Navigator.of(context).maybePop();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              DragToMoveArea(child: _DynamicBackdrop(track: track)),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 780;
                    final content = narrow
                        ? _MobileFullScreenLayout(
                            track: track,
                            repository: repository,
                          )
                        : _DesktopFullScreenLayout(
                            track: track,
                            repository: repository,
                            mode: mode,
                          );
                    return Column(
                      children: [
                        _FullScreenHeader(track: track),
                        Expanded(child: content),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeloMobileMiniPlayer extends ConsumerWidget {
  const MeloMobileMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final track = repository.queue.current?.track;
    if (track == null) return const SizedBox.shrink();
    final issue = repository.playbackIssue;
    final hasIssue = issue?.trackRef == track.ref;

    return ClipRRect(
      borderRadius: MeloRadii.lg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: MeloColors.surface.withValues(alpha: .68),
            borderRadius: MeloRadii.lg,
            border: Border.all(
              color: hasIssue
                  ? MeloColors.favorite.withValues(alpha: .28)
                  : Colors.white.withValues(alpha: .54),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x241C2736),
                blurRadius: 34,
                offset: Offset(0, 16),
              ),
              BoxShadow(
                color: Color(0x0F087C76),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => showMeloFullScreenPlayer(context),
                          onVerticalDragEnd: (details) {
                            if ((details.primaryVelocity ?? 0) < -260) {
                              showMeloFullScreenPlayer(context);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MeloSpacing.md,
                            ),
                            child: Row(
                              children: [
                                MeloTrackCover(
                                  seed: track.title,
                                  artwork: track.artwork,
                                  isActive:
                                      repository.isPlaybackActive && !hasIssue,
                                  size: 40,
                                ),
                                const SizedBox(width: MeloSpacing.sm),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasIssue
                                            ? (issue?.title ?? '播放失败')
                                            : track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: hasIssue
                                                  ? MeloColors.favorite
                                                  : MeloColors.textPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hasIssue
                                            ? (issue?.message ?? '请稍后重试')
                                            : track.artists.join(' / '),
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
                    ),
                    hasIssue
                        ? IconButton.filledTonal(
                            tooltip: '重试播放',
                            onPressed: repository.retryCurrentPlayback,
                            icon: const Icon(Icons.refresh_rounded),
                          )
                        : _MiniPlayButton(repository: repository),
                    IconButton(
                      tooltip: '播放队列',
                      onPressed: () {
                        showMeloFullScreenPlayer(
                          context,
                          initialMode: RightSidebarMode.queue,
                        );
                      },
                      icon: Badge(
                        label: Text('${repository.queue.entries.length}'),
                        isLabelVisible: repository.queue.entries.isNotEmpty,
                        child: const Icon(Icons.queue_music_rounded),
                      ),
                    ),
                    const SizedBox(width: MeloSpacing.xs),
                  ],
                ),
              ),
              _MiniPlayerProgress(repository: repository),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerProgress extends StatelessWidget {
  const _MiniPlayerProgress({required this.repository});

  final DemoRepository repository;

  @override
  Widget build(BuildContext context) {
    if (repository.hasPlaybackIssue) {
      return SizedBox(
        height: 3,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
          child: const ColoredBox(color: MeloColors.favorite),
        ),
      );
    }
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
            final totalMs = duration?.inMilliseconds ?? 0;
            final position = positionSnapshot.data ?? Duration.zero;
            final positionMs = position.inMilliseconds.clamp(0, totalMs);
            final value = totalMs <= 0 ? 0.0 : positionMs / totalMs;
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: value,
                color: MeloColors.primary600,
                backgroundColor: MeloColors.primary100.withValues(alpha: .56),
              ),
            );
          },
        );
      },
    );
  }
}

class _DynamicBackdrop extends StatelessWidget {
  const _DynamicBackdrop({required this.track});

  final SourceTrack? track;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Stack(
        key: ValueKey(track?.artwork?.toString() ?? track?.title ?? 'empty'),
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Transform.scale(
                scale: 1.12,
                child: track?.artwork == null
                    ? _BackdropPlaceholder(seed: track?.title ?? 'melo')
                    : Image.network(
                        track!.artwork!.toString(),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        headers: meloArtworkHeaders,
                        errorBuilder: (_, __, ___) =>
                            _BackdropPlaceholder(seed: track?.title ?? 'melo'),
                      ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF05070B).withValues(alpha: .72),
                  const Color(0xFF0A0E14).withValues(alpha: .62),
                  const Color(0xFF030509).withValues(alpha: .86),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-.45, -.55),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: .12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropPlaceholder extends StatelessWidget {
  const _BackdropPlaceholder({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .45, .46).toColor(),
            HSLColor.fromAHSL(1, (hue + 42) % 360, .50, .24).toColor(),
            const Color(0xFF080B10),
          ],
        ),
      ),
    );
  }
}

class _FullScreenHeader extends StatelessWidget {
  const _FullScreenHeader({required this.track});

  final SourceTrack? track;

  @override
  Widget build(BuildContext context) {
    final currentTrack = track;
    final compact = MediaQuery.sizeOf(context).width < 780;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? MeloSpacing.md : MeloSpacing.xl,
        compact ? 4 : MeloSpacing.md,
        compact ? MeloSpacing.md : MeloSpacing.xl,
        compact ? 0 : MeloSpacing.xs,
      ),
      child: Row(
        children: [
          _GlassIconButton(
            tooltip: '收起',
            icon: Icons.keyboard_arrow_down_rounded,
            buttonSize: compact ? 36 : null,
            iconSize: compact ? 22 : null,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          SizedBox(width: compact ? MeloSpacing.xs : MeloSpacing.md),
          Expanded(
            child: DragToMoveArea(
              child: SizedBox(
                height: compact ? 36 : 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currentTrack == null
                        ? 'MeloUnion'
                        : '${currentTrack.title} · 正在播放',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: compact ? 12 : null,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopFullScreenLayout extends StatelessWidget {
  const _DesktopFullScreenLayout({
    required this.track,
    required this.repository,
    required this.mode,
  });

  final SourceTrack? track;
  final DemoRepository repository;
  final RightSidebarMode mode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final drawerWidth = constraints.maxWidth < 1180
            ? constraints.maxWidth * .42
            : constraints.maxWidth * .34;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(54, 6, 54, 28),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _DesktopAlbumStage(
                          track: track,
                          repository: repository,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 56),
                  Expanded(
                    flex: 6,
                    child: _DesktopLyricsStage(
                      track: track,
                      repository: repository,
                      mode: mode,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 22,
              right: 32,
              bottom: 22,
              width: drawerWidth.clamp(420, 560).toDouble(),
              child: IgnorePointer(
                ignoring: mode != RightSidebarMode.queue,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  offset: mode == RightSidebarMode.queue
                      ? Offset.zero
                      : const Offset(.12, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: mode == RightSidebarMode.queue ? 1 : 0,
                    child: _QueueDrawer(repository: repository),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DesktopAlbumStage extends StatelessWidget {
  const _DesktopAlbumStage({
    required this.track,
    required this.repository,
  });

  final SourceTrack? track;
  final DemoRepository repository;

  @override
  Widget build(BuildContext context) {
    final current = track;
    if (current == null) {
      return _GlassPanel(
        padding: const EdgeInsets.all(MeloSpacing.xl),
        child: Text(
          '从喜欢、歌单或推荐中选择歌曲',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: .82),
              ),
        ),
      );
    }

    final presentation = meloProviderPresentation(current.ref.providerId);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RotatingArtwork(
          track: current,
          repository: repository,
          size: 360,
        ),
        const SizedBox(height: 18),
        Text(
          current.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.08,
                letterSpacing: 0,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          current.artists.join(' / '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: .58),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: MeloSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: MeloSpacing.xs,
          runSpacing: MeloSpacing.xs,
          children: [
            _GlassPill(label: presentation.shortName),
            _GlassPill(label: _qualityLabel(repository.playbackQuality)),
            if (current.isFavorited)
              const _GlassPill(
                label: '已收藏',
                icon: Icons.favorite_rounded,
                accent: MeloColors.favorite,
              ),
          ],
        ),
        const SizedBox(height: MeloSpacing.lg),
        _FullscreenProgress(repository: repository),
        const SizedBox(height: MeloSpacing.md),
        _FullscreenTransport(repository: repository, track: current),
        const SizedBox(height: MeloSpacing.sm),
        _SecondaryControls(repository: repository, track: current),
      ],
    );
  }
}

class _DesktopLyricsStage extends StatelessWidget {
  const _DesktopLyricsStage({
    required this.track,
    required this.repository,
    required this.mode,
  });

  final SourceTrack? track;
  final DemoRepository repository;
  final RightSidebarMode mode;

  @override
  Widget build(BuildContext context) {
    final current = track;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 34, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (current != null) ...[
            Text(
              current.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '歌手：${current.artists.join(' / ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .52),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 34),
          ],
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: mode == RightSidebarMode.queue ? .28 : 1,
              child: _FullscreenLyrics(track: track, repository: repository),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileFullScreenLayout extends StatefulWidget {
  const _MobileFullScreenLayout({
    required this.track,
    required this.repository,
  });

  final SourceTrack? track;
  final DemoRepository repository;

  @override
  State<_MobileFullScreenLayout> createState() =>
      _MobileFullScreenLayoutState();
}

class _MobileFullScreenLayoutState extends State<_MobileFullScreenLayout> {
  bool _showLyrics = false;

  void _showQueue() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .28),
      builder: (context) => _MobileQueueSheet(repository: widget.repository),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MeloSpacing.md,
        MeloSpacing.xs,
        MeloSpacing.md,
        MeloSpacing.sm,
      ),
      children: [
        _PrimaryPlayerPanel(
          track: widget.track,
          repository: widget.repository,
          coverSize: 238,
          compact: true,
          showLyrics: _showLyrics,
          onLyricsToggle: widget.track == null
              ? null
              : () => setState(() => _showLyrics = !_showLyrics),
          onQueuePressed: widget.track == null ? null : _showQueue,
        ),
      ],
    );
  }
}

class _PrimaryPlayerPanel extends StatelessWidget {
  const _PrimaryPlayerPanel({
    required this.track,
    required this.repository,
    required this.coverSize,
    this.compact = false,
    this.showLyrics = false,
    this.onLyricsToggle,
    this.onQueuePressed,
  });

  final SourceTrack? track;
  final DemoRepository repository;
  final double coverSize;
  final bool compact;
  final bool showLyrics;
  final VoidCallback? onLyricsToggle;
  final VoidCallback? onQueuePressed;

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return _GlassPanel(
        padding: const EdgeInsets.all(MeloSpacing.xl),
        child: Text(
          '从喜欢、歌单或推荐中选择歌曲',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: .82),
              ),
        ),
      );
    }

    final presentation = meloProviderPresentation(track!.ref.providerId);
    final artworkSize =
        compact ? coverSize.clamp(210, 264).toDouble() : coverSize;
    final artworkHeight = compact ? artworkSize + 78 : artworkSize + 116;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: showLyrics
              ? SizedBox(
                  key: const ValueKey('mobile-lyrics-stage'),
                  width: double.infinity,
                  height: artworkHeight,
                  child: _FullscreenLyrics(
                    track: track,
                    repository: repository,
                    compact: true,
                  ),
                )
              : _RotatingArtwork(
                  key: const ValueKey('mobile-artwork-stage'),
                  track: track!,
                  repository: repository,
                  size: artworkSize,
                  compact: compact,
                ),
        ),
        SizedBox(height: compact ? 16 : MeloSpacing.xl),
        Text(
          track!.title,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontSize: compact ? 26 : null,
                fontWeight: FontWeight.w900,
                height: compact ? 1.08 : 1.12,
                letterSpacing: 0,
              ),
        ),
        SizedBox(height: compact ? 5 : MeloSpacing.xs),
        Text(
          track!.artists.join(' / '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: .68),
                fontSize: compact ? 15 : null,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (!compact) ...[
          const SizedBox(height: MeloSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: MeloSpacing.xs,
            runSpacing: MeloSpacing.xs,
            children: [
              _GlassPill(label: presentation.shortName),
              _GlassPill(label: _qualityLabel(repository.playbackQuality)),
              if (track!.isFavorited)
                const _GlassPill(
                  label: '已收藏',
                  icon: Icons.favorite_rounded,
                  accent: MeloColors.favorite,
                ),
            ],
          ),
        ],
        SizedBox(height: compact ? 16 : MeloSpacing.lg),
        _FullscreenProgress(repository: repository),
        SizedBox(height: compact ? 12 : MeloSpacing.md),
        _FullscreenTransport(
          repository: repository,
          track: track!,
          compact: compact,
        ),
        SizedBox(height: compact ? 14 : MeloSpacing.sm),
        _SecondaryControls(
          repository: repository,
          track: track!,
          compact: compact,
          showLyrics: showLyrics,
          onLyricsToggle: onLyricsToggle,
          onQueuePressed: onQueuePressed,
        ),
      ],
    );
  }
}

class _RotatingArtwork extends StatefulWidget {
  const _RotatingArtwork({
    required this.track,
    required this.repository,
    required this.size,
    this.compact = false,
    super.key,
  });

  final SourceTrack track;
  final DemoRepository repository;
  final double size;
  final bool compact;

  @override
  State<_RotatingArtwork> createState() => _RotatingArtworkState();
}

class _RotatingArtworkState extends State<_RotatingArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  StreamSubscription<PlayerState>? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 86),
    );
    _sync(widget.repository.audioPlayer.playerState);
    _subscription = widget.repository.playerStateStream.listen(_sync);
  }

  @override
  void didUpdateWidget(covariant _RotatingArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _subscription?.cancel();
      _subscription = widget.repository.playerStateStream.listen(_sync);
      _sync(widget.repository.audioPlayer.playerState);
    }
  }

  void _sync(PlayerState state) {
    final active = state.playing &&
        state.processingState != ProcessingState.completed &&
        state.processingState != ProcessingState.idle;
    if (active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diameter = widget.size;
    final frameWidth = widget.compact ? diameter + 68 : diameter + 92;
    final frameHeight = widget.compact ? diameter + 78 : diameter + 116;
    final tonearmWidth = widget.compact ? diameter * .38 : diameter * .42;
    final tonearmHeight = widget.compact ? diameter * .48 : diameter * .56;
    return RepaintBoundary(
      child: SizedBox(
        width: frameWidth,
        height: frameHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              child: RotationTransition(
                turns: _controller,
                child: Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF2E3331),
                        Color(0xFF141716),
                        Color(0xFF050606),
                      ],
                      stops: [.0, .58, 1],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .42),
                        blurRadius: 46,
                        offset: const Offset(0, 30),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: .08),
                        blurRadius: 20,
                        offset: const Offset(-10, -10),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _VinylGroovePainter(),
                    child: Center(
                      child: Container(
                        width: diameter * .57,
                        height: diameter * .57,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: .42),
                            width: 8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .42),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child:
                            ClipOval(child: _LargeArtwork(track: widget.track)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: frameWidth * (widget.compact ? .48 : .45),
              child: CustomPaint(
                size: Size(tonearmWidth, tonearmHeight),
                painter: _TonearmPainter(),
              ),
            ),
            Positioned(
              bottom: diameter * .275,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .32),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VinylGroovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 28; i++) {
      final radius = size.width * (.31 + i * .011);
      paint.color = i.isEven
          ? Colors.white.withValues(alpha: .035)
          : Colors.black.withValues(alpha: .16);
      canvas.drawCircle(center, radius, paint);
    }
    final sheen = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: .0),
          Colors.white.withValues(alpha: .08),
          Colors.white.withValues(alpha: .0),
        ],
        stops: const [.0, .12, .26],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, size.width / 2, sheen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TonearmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final arm = Paint()
      ..color = Colors.white.withValues(alpha: .92)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: .20)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * .10, size.height * .08)
      ..cubicTo(
        size.width * .18,
        size.height * .34,
        size.width * .20,
        size.height * .52,
        size.width * .42,
        size.height * .66,
      )
      ..lineTo(size.width * .70, size.height * .86);
    canvas.drawPath(path.shift(const Offset(2, 3)), shadow);
    canvas.drawPath(path, arm);

    final basePaint = Paint()..color = Colors.white.withValues(alpha: .96);
    canvas.drawCircle(
        Offset(size.width * .10, size.height * .08), 18, basePaint);
    canvas.drawCircle(
      Offset(size.width * .10, size.height * .08),
      8,
      Paint()..color = const Color(0xFFD9DEDB),
    );

    final cartridge = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * .72, size.height * .88),
        width: 34,
        height: 18,
      ),
      const Radius.circular(5),
    );
    canvas.save();
    canvas.translate(size.width * .72, size.height * .88);
    canvas.rotate(.72);
    canvas.translate(-size.width * .72, -size.height * .88);
    canvas.drawRRect(
      cartridge,
      Paint()..color = Colors.white.withValues(alpha: .96),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LargeArtwork extends StatelessWidget {
  const _LargeArtwork({required this.track});

  final SourceTrack track;

  @override
  Widget build(BuildContext context) {
    final artwork = track.artwork;
    if (artwork != null && artwork.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: MeloRadii.xl,
        child: Image.network(
          artwork.toString(),
          fit: BoxFit.cover,
          headers: meloArtworkHeaders,
          errorBuilder: (_, __, ___) => _ArtworkPlaceholder(seed: track.title),
        ),
      );
    }
    return _ArtworkPlaceholder(seed: track.title);
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
    return Container(
      decoration: BoxDecoration(
        borderRadius: MeloRadii.xl,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .55, .64).toColor(),
            HSLColor.fromAHSL(1, (hue + 48) % 360, .58, .35).toColor(),
          ],
        ),
      ),
      child: const Icon(
        Icons.graphic_eq_rounded,
        color: Colors.white,
        size: 88,
      ),
    );
  }
}

class _FullscreenLyrics extends ConsumerStatefulWidget {
  const _FullscreenLyrics({
    required this.track,
    required this.repository,
    this.compact = false,
  });

  final SourceTrack? track;
  final DemoRepository repository;
  final bool compact;

  @override
  ConsumerState<_FullscreenLyrics> createState() => _FullscreenLyricsState();
}

class _FullscreenLyricsState extends ConsumerState<_FullscreenLyrics> {
  final _scrollController = ScrollController();
  final _itemKeys = <GlobalKey>[];
  DateTime _autoScrollPausedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastActiveIndex = -1;
  bool _hasInitialScrolled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive(int index, {bool force = false}) {
    if (index == _lastActiveIndex && !force) return;
    if (DateTime.now().isBefore(_autoScrollPausedUntil) && !force) {
      return;
    }
    _lastActiveIndex = index;
    if (index < 0 || index >= _itemKeys.length) return;

    final itemContext = _itemKeys[index].currentContext;
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: .44,
      );
    } else if (_scrollController.hasClients) {
      // Fallback: estimate scroll offset if itemContext is null (off-screen)
      final targetOffset = (index * 50.0) - 140.0;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    if (track == null) return const _EmptyGlassMessage(message: '暂无播放歌曲');

    final lyricsAsync = ref.watch(lyricsProvider(track.ref));
    return lyricsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white.withValues(alpha: .86),
        ),
      ),
      error: (error, _) => _EmptyGlassMessage(message: '获取歌词失败: $error'),
      data: (lyrics) {
        if (lyrics == null || lyrics.trim().isEmpty) {
          return const _EmptyGlassMessage(message: '暂无歌词');
        }

        final lines = _parseLyrics(lyrics);
        if (lines.isEmpty) return const _EmptyGlassMessage(message: '暂无歌词');

        if (_itemKeys.length != lines.length) {
          _itemKeys
            ..clear()
            ..addAll(List.generate(lines.length, (_) => GlobalKey()));
        }

        return StreamBuilder<Duration>(
          stream: widget.repository.positionStream,
          initialData: widget.repository.audioPlayer.position,
          builder: (context, snapshot) {
            final activeIndex = _activeLyricIndex(
              lines,
              snapshot.data ?? Duration.zero,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_hasInitialScrolled) {
                _hasInitialScrolled = true;
                // Delay to allow full-screen slide-up transition (280ms) and list layout to settle
                Future.delayed(const Duration(milliseconds: 350), () {
                  if (mounted) {
                    _scrollToActive(activeIndex, force: true);
                  }
                });
              } else {
                _scrollToActive(activeIndex);
              }
            });

            return NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction != ScrollDirection.idle) {
                  _autoScrollPausedUntil =
                      DateTime.now().add(const Duration(seconds: 4));
                }
                return false;
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    vertical: widget.compact ? 62 : 128,
                  ),
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final active = index == activeIndex;
                    return _LyricRow(
                      key: _itemKeys[index],
                      line: line,
                      active: active,
                      compact: widget.compact,
                      onTap: line.seekable
                          ? () {
                              widget.repository.seek(line.time);
                              _autoScrollPausedUntil =
                                  DateTime.fromMillisecondsSinceEpoch(0);
                            }
                          : null,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LyricRow extends StatelessWidget {
  const _LyricRow({
    required this.line,
    required this.active,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final _LyricLine line;
  final bool active;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? MeloSpacing.sm : MeloSpacing.lg,
            vertical: compact ? (active ? 12 : 8) : (active ? 16 : 10),
          ),
          alignment: Alignment.center,
          child: Text(
            line.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: .46),
                  fontSize: compact ? (active ? 22 : 16) : (active ? 24 : 16),
                  height: compact ? 1.28 : 1.35,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 0,
                ),
          ),
        ),
      ),
    );
  }
}

class _QueueDrawer extends ConsumerWidget {
  const _QueueDrawer({required this.repository});

  final DemoRepository repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = repository.queue;
    return ClipRRect(
      borderRadius: MeloRadii.xl,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: MeloRadii.xl,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 42,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 18, 10),
                child: Row(
                  children: [
                    Text(
                      '播放队列',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF182233),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${queue.entries.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8A94A6),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '返回歌词',
                      onPressed: () => ref
                          .read(rightSidebarModeProvider.notifier)
                          .state = RightSidebarMode.lyrics,
                      icon: const Icon(Icons.format_list_bulleted_rounded),
                    ),
                    IconButton(
                      tooltip: '清空',
                      onPressed: null,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
              if (queue.entries.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      '队列为空',
                      style: TextStyle(
                        color: MeloColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
                    itemCount: queue.entries.length,
                    itemBuilder: (context, index) {
                      final entry = queue.entries[index];
                      return _QueueDrawerRow(
                        track: entry.track,
                        selected: index == queue.currentIndex,
                        onPlay: () =>
                            repository.playOrToggleQueueTrack(entry.track.ref),
                        onRemove: () => repository.removeQueueEntry(index),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileQueueSheet extends ConsumerWidget {
  const _MobileQueueSheet({required this.repository});

  final DemoRepository repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(demoRepositoryProvider);
    final queue = repo.queue;
    return DraggableScrollableSheet(
      initialChildSize: .68,
      minChildSize: .36,
      maxChildSize: .88,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: Colors.white.withValues(alpha: .95),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MeloColors.borderStrong,
                      borderRadius: MeloRadii.pill,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      children: [
                        Text(
                          '当前播放列表',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: MeloColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${queue.entries.length}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: MeloColors.textTertiary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: '关闭',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  if (queue.entries.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          '队列为空',
                          style: TextStyle(
                            color: MeloColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: queue.entries.length,
                        itemBuilder: (context, index) {
                          final entry = queue.entries[index];
                          return _QueueDrawerRow(
                            track: entry.track,
                            selected: index == queue.currentIndex,
                            onPlay: () =>
                                repo.playOrToggleQueueTrack(entry.track.ref),
                            onRemove: () => repo.removeQueueEntry(index),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QueueDrawerRow extends StatefulWidget {
  const _QueueDrawerRow({
    required this.track,
    required this.selected,
    required this.onPlay,
    required this.onRemove,
  });

  final SourceTrack track;
  final bool selected;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  @override
  State<_QueueDrawerRow> createState() => _QueueDrawerRowState();
}

class _QueueDrawerRowState extends State<_QueueDrawerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = MeloColors.primary600;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onPlay,
        onSecondaryTap: widget.onRemove,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFFE7EBEA)
                : _hovered
                    ? const Color(0xFFF4F6F8)
                    : Colors.transparent,
            borderRadius: MeloRadii.md,
          ),
          child: Row(
            children: [
              MeloTrackCover(
                seed: widget.track.title,
                artwork: widget.track.artwork,
                isActive: widget.selected,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: widget.selected
                                      ? activeColor
                                      : MeloColors.textPrimary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if (widget.track.isFavorited)
                          const Icon(
                            Icons.favorite_rounded,
                            color: MeloColors.favorite,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.track.artists.join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.selected
                                ? activeColor
                                : MeloColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _hovered || widget.selected ? 1 : 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: widget.selected ? '暂停/播放' : '播放这首',
                      onPressed: widget.onPlay,
                      icon: Icon(
                        widget.selected
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: '移出队列',
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenProgress extends StatelessWidget {
  const _FullscreenProgress({required this.repository});

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
            return Column(
              children: [
                SliderTheme(
                  data: _darkSliderTheme(context),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(Duration(milliseconds: positionMs)),
                        style: _timeStyle(context),
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(duration ?? Duration.zero),
                        style: _timeStyle(context),
                      ),
                    ],
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

class _FullscreenTransport extends StatelessWidget {
  const _FullscreenTransport({
    required this.repository,
    required this.track,
    this.compact = false,
  });

  final DemoRepository repository;
  final SourceTrack track;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GlassIconButton(
            tooltip: '上一首',
            icon: Icons.skip_previous_rounded,
            buttonSize: 52,
            iconSize: 32,
            onPressed: repository.queuePrevious,
          ),
          const SizedBox(width: 18),
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
                size: 64,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0A0E14),
                onPressed: repository.togglePlayPause,
                onCompletedTap: () => repository.seek(Duration.zero).then(
                      (_) => repository.togglePlayPause(),
                    ),
              );
            },
          ),
          const SizedBox(width: 18),
          _GlassIconButton(
            tooltip: '下一首',
            icon: Icons.skip_next_rounded,
            buttonSize: 52,
            iconSize: 32,
            onPressed: repository.queueNext,
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GlassIconButton(
          tooltip: repository.shuffleEnabled ? '关闭随机播放' : '随机播放',
          icon: Icons.shuffle_rounded,
          active: repository.shuffleEnabled,
          onPressed: repository.toggleShuffle,
        ),
        const SizedBox(width: MeloSpacing.sm),
        _GlassIconButton(
          tooltip: '上一首',
          icon: Icons.skip_previous_rounded,
          large: true,
          onPressed: repository.queuePrevious,
        ),
        const SizedBox(width: MeloSpacing.md),
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
              size: 68,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A0E14),
              onPressed: repository.togglePlayPause,
              onCompletedTap: () => repository.seek(Duration.zero).then(
                    (_) => repository.togglePlayPause(),
                  ),
            );
          },
        ),
        const SizedBox(width: MeloSpacing.md),
        _GlassIconButton(
          tooltip: '下一首',
          icon: Icons.skip_next_rounded,
          large: true,
          onPressed: repository.queueNext,
        ),
        const SizedBox(width: MeloSpacing.sm),
        _GlassIconButton(
          tooltip: _repeatTooltip(repository.repeatMode),
          icon: repository.repeatMode == PlaybackRepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          active: repository.repeatMode != PlaybackRepeatMode.off,
          onPressed: repository.cycleRepeatMode,
        ),
      ],
    );
  }
}

class _SecondaryControls extends ConsumerWidget {
  const _SecondaryControls({
    required this.repository,
    required this.track,
    this.compact = false,
    this.showLyrics = false,
    this.onLyricsToggle,
    this.onQueuePressed,
  });

  final DemoRepository repository;
  final SourceTrack track;
  final bool compact;
  final bool showLyrics;
  final VoidCallback? onLyricsToggle;
  final VoidCallback? onQueuePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(rightSidebarModeProvider);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: MeloSpacing.sm,
      runSpacing: MeloSpacing.xs,
      children: [
        _FullscreenFavoriteButton(track: track, repository: repository),
        if (onLyricsToggle != null)
          _GlassIconButton(
            tooltip: showLyrics ? '返回唱片' : '显示歌词',
            icon: showLyrics
                ? Icons.album_rounded
                : Icons.subtitles_rounded,
            buttonSize: compact ? 44 : null,
            iconSize: compact ? 24 : null,
            active: showLyrics,
            onPressed: onLyricsToggle,
          ),
        if (onQueuePressed != null)
          _GlassIconButton(
            tooltip: '当前播放列表',
            icon: Icons.queue_music_rounded,
            buttonSize: compact ? 44 : null,
            iconSize: compact ? 24 : null,
            onPressed: onQueuePressed,
          )
        else if (onLyricsToggle == null)
          _GlassIconButton(
            tooltip: mode == RightSidebarMode.queue ? '关闭播放队列' : '播放队列',
            icon: Icons.queue_music_rounded,
            active: mode == RightSidebarMode.queue,
            onPressed: () {
              ref.read(rightSidebarModeProvider.notifier).state =
                  mode == RightSidebarMode.queue
                      ? RightSidebarMode.lyrics
                      : RightSidebarMode.queue;
            },
          ),
        if (!compact)
          SizedBox(
            width: 178,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white.withValues(alpha: .62),
                  size: 20,
                ),
                Expanded(
                  child: SliderTheme(
                    data: _darkSliderTheme(context),
                    child: Slider(
                      value: repository.volume,
                      onChanged: repository.setVolume,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FullscreenFavoriteButton extends ConsumerStatefulWidget {
  const _FullscreenFavoriteButton({
    required this.track,
    required this.repository,
  });

  final SourceTrack track;
  final DemoRepository repository;

  @override
  ConsumerState<_FullscreenFavoriteButton> createState() =>
      _FullscreenFavoriteButtonState();
}

class _FullscreenFavoriteButtonState
    extends ConsumerState<_FullscreenFavoriteButton> {
  late bool _liked = widget.track.isFavorited;
  late ProviderTrackRef _lastRef = widget.track.ref;

  @override
  Widget build(BuildContext context) {
    if (_lastRef != widget.track.ref) {
      _liked = widget.track.isFavorited;
      _lastRef = widget.track.ref;
    }

    return _GlassIconButton(
      tooltip: _liked ? '取消喜欢' : '喜欢',
      icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      active: _liked,
      activeColor: MeloColors.favorite,
      onPressed: () async {
        final availability = widget.repository.favoriteWriteAvailability(
          widget.track.ref.providerId,
        );
        if (!availability.isEnabled) {
          MeloSnackbar.show(
            context: context,
            message: availability.reason ?? '此来源无法写回收藏。',
          );
          return;
        }

        final newLiked = !_liked;
        setState(() => _liked = newLiked);
        try {
          await widget.repository.toggleFavorite(
            track: widget.track,
            liked: newLiked,
          );
          // allFavoritesProvider is auto-invalidated by the repository.
        } on ProviderException catch (error) {
          if (!mounted) return;
          setState(() => _liked = !newLiked);
          MeloSnackbar.show(
            context: this.context,
            message: error.message,
          );
        }
      },
    );
  }
}

class _MiniPlayButton extends StatelessWidget {
  const _MiniPlayButton({required this.repository});

  final DemoRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: repository.playerStateStream,
      initialData: repository.audioPlayer.playerState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? repository.isPlaying;
        final completed = state?.processingState == ProcessingState.completed;
        return IconButton.filled(
          tooltip: playing && !completed ? '暂停' : '播放',
          style: IconButton.styleFrom(
            backgroundColor: MeloColors.primary600,
            foregroundColor: Colors.white,
            disabledBackgroundColor: MeloColors.primary100,
            disabledForegroundColor: MeloColors.primary700,
          ),
          onPressed: completed
              ? () => repository.seek(Duration.zero).then(
                    (_) => repository.togglePlayPause(),
                  )
              : repository.togglePlayPause,
          icon: Icon(
            playing && !completed
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
          ),
        );
      },
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: MeloRadii.xl,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .10),
            borderRadius: MeloRadii.xl,
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.large = false,
    this.activeColor,
    this.buttonSize,
    this.iconSize,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final bool large;
  final Color? activeColor;
  final double? buttonSize;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ?? Colors.white)
        : Colors.white.withValues(alpha: .72);
    final size = buttonSize ?? (large ? 54.0 : 44.0);
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        iconSize: iconSize ?? (large ? 34 : 24),
        style: IconButton.styleFrom(
          fixedSize: Size.square(size),
          backgroundColor: active
              ? (activeColor ?? Colors.white).withValues(alpha: .18)
              : Colors.white.withValues(alpha: .09),
          foregroundColor: color,
          disabledForegroundColor: Colors.white.withValues(alpha: .24),
          shape: const CircleBorder(),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.label,
    this.icon,
    this.accent,
  });

  final String label;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.white;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: accent == null ? .11 : .16),
        borderRadius: MeloRadii.pill,
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: accent == null ? .78 : .96),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGlassMessage extends StatelessWidget {
  const _EmptyGlassMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: .62),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LyricLine {
  const _LyricLine({
    required this.time,
    required this.text,
    required this.seekable,
  });

  final Duration time;
  final String text;
  final bool seekable;
}

List<_LyricLine> _parseLyrics(String lyrics) {
  final parsed = <_LyricLine>[];
  final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');
  for (final rawLine in lyrics.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final matches = regex.allMatches(line).toList();
    final text = line.replaceAll(regex, '').trim();
    if (text.isEmpty) continue;
    if (matches.isEmpty) {
      parsed.add(_LyricLine(time: Duration.zero, text: text, seekable: false));
      continue;
    }
    for (final match in matches) {
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final ms = int.parse(match.group(3)!.padRight(3, '0').substring(0, 3));
      parsed.add(
        _LyricLine(
          time: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: ms,
          ),
          text: text,
          seekable: true,
        ),
      );
    }
  }
  parsed.sort((a, b) => a.time.compareTo(b.time));
  return parsed;
}

int _activeLyricIndex(List<_LyricLine> lines, Duration position) {
  var active = 0;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].seekable && lines[i].time <= position) {
      active = i;
    } else if (lines[i].seekable) {
      break;
    }
  }
  return active;
}

SliderThemeData _darkSliderTheme(BuildContext context) {
  return SliderTheme.of(context).copyWith(
    trackHeight: 4,
    activeTrackColor: Colors.white,
    inactiveTrackColor: Colors.white.withValues(alpha: .18),
    disabledActiveTrackColor: Colors.white.withValues(alpha: .18),
    disabledInactiveTrackColor: Colors.white.withValues(alpha: .10),
    thumbColor: Colors.white,
    overlayColor: Colors.white.withValues(alpha: .16),
    valueIndicatorColor: Colors.white,
    valueIndicatorTextStyle: const TextStyle(color: Color(0xFF0A0E14)),
  );
}

TextStyle? _timeStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: .55),
        fontWeight: FontWeight.w700,
      );
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

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
