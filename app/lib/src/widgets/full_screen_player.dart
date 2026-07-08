import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:window_manager/window_manager.dart';

import '../bootstrap/demo_repository.dart';
import '../design/melo_tokens.dart';
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

class MeloFullScreenPlayer extends ConsumerStatefulWidget {
  const MeloFullScreenPlayer({super.key});

  @override
  ConsumerState<MeloFullScreenPlayer> createState() =>
      _MeloFullScreenPlayerState();
}

class _MeloFullScreenPlayerState extends ConsumerState<MeloFullScreenPlayer> {
  int? _lastArtworkPrecacheSignature;
  _ArtworkPalette _palette = _ArtworkPalette.fallback;
  String? _paletteArtworkKey;
  int _paletteRequestId = 0;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final queue = repository.queue;
    final track = queue.current?.track;
    final mode = ref.watch(rightSidebarModeProvider);
    final useWindowChrome = MediaQuery.sizeOf(context).width >= 960;
    final windowRadius = useWindowChrome ? MeloRadii.window : BorderRadius.zero;
    _scheduleArtworkPrecache(repository);
    _schedulePaletteExtraction(track);

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
              DragToMoveArea(
                child: _DynamicBackdrop(
                  track: track,
                  palette: _palette,
                  isPlaying: repository.isPlaybackActive,
                ),
              ),
              SafeArea(
                bottom: useWindowChrome,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 780;
                    final content = narrow
                        ? _MobileFullScreenLayout(
                            track: track,
                            repository: repository,
                            palette: _palette,
                          )
                        : _DesktopFullScreenLayout(
                            track: track,
                            repository: repository,
                            mode: mode,
                            palette: _palette,
                          );
                    return Column(
                      children: [
                        _FullScreenHeader(
                          track: track,
                        ),
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

  void _scheduleArtworkPrecache(DemoRepository repository) {
    final tracks = _fullscreenPrecacheTracks(repository);
    final precachePixels = _fullscreenDecodedPixels(
      context,
      MediaQuery.sizeOf(context).longestSide,
      scale: 1.15,
    );
    final signature = Object.hashAll(
      tracks.expand(
        (track) => [
          track.ref.providerId.value,
          track.ref.trackId,
          track.artwork?.toString() ?? '',
        ],
      ),
    );
    if (_lastArtworkPrecacheSignature == signature) return;
    _lastArtworkPrecacheSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final track in tracks) {
        final artwork = track.artwork;
        if (artwork == null || artwork.toString().isEmpty) continue;
        unawaited(
          precacheImage(
            _fullscreenArtworkProvider(
              artwork,
              targetPixels: precachePixels,
              cacheWidth: precachePixels,
              cacheHeight: precachePixels,
            ),
            context,
          ).catchError((Object _) {}),
        );
      }
    });
  }

  List<SourceTrack> _fullscreenPrecacheTracks(DemoRepository repository) {
    final queue = repository.queue;
    final entries = queue.entries;
    final currentIndex = queue.currentIndex;
    if (currentIndex < 0 || currentIndex >= entries.length) {
      return const [];
    }

    final tracks = <SourceTrack>[entries[currentIndex].track];
    final nextIndex = currentIndex + 1;
    if (nextIndex < entries.length) {
      tracks.add(entries[nextIndex].track);
    } else if (repository.repeatMode == PlaybackRepeatMode.all &&
        entries.length > 1) {
      tracks.add(entries.first.track);
    }
    return tracks;
  }

  void _schedulePaletteExtraction(SourceTrack? track) {
    final artwork = track?.artwork;
    final key = artwork?.toString();
    if (_paletteArtworkKey == key) return;
    _paletteArtworkKey = key;

    if (artwork == null || key == null || key.isEmpty) {
      _palette = _ArtworkPalette.fallbackFor(track?.title ?? 'melo');
      return;
    }

    final requestId = ++_paletteRequestId;
    unawaited(
      _extractArtworkPalette(artwork).then((palette) {
        if (!mounted || requestId != _paletteRequestId) return;
        setState(() => _palette = palette);
      }).catchError((Object _) {
        if (!mounted || requestId != _paletteRequestId) return;
        setState(() => _palette = _ArtworkPalette.fallbackFor(track?.title));
      }),
    );
  }
}

Future<_ArtworkPalette> _extractArtworkPalette(Uri artwork) async {
  final provider = meloCachedArtworkProvider(
    artwork,
    targetPixels: 96,
    highResolution: false,
    cacheWidth: 96,
    cacheHeight: 96,
  );
  final imageInfo = await _resolveArtworkImage(provider);
  try {
    final image = imageInfo.image;
    final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
    if (byteData == null) return _ArtworkPalette.fallback;
    return _ArtworkPalette.fromPixels(
      byteData.buffer.asUint8List(),
      image.width,
      image.height,
    );
  } finally {
    imageInfo.dispose();
  }
}

Future<ImageInfo> _resolveArtworkImage(ImageProvider<Object> provider) {
  final completer = Completer<ImageInfo>();
  final stream = provider.resolve(
    const ImageConfiguration(size: Size(96, 96), devicePixelRatio: 1),
  );
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (image, _) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(image);
    },
    onError: (error, stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    },
  );
  stream.addListener(listener);
  return completer.future.timeout(const Duration(seconds: 4));
}

final class _ArtworkPalette {
  const _ArtworkPalette({
    required this.base,
    required this.dark,
    required this.deep,
    required this.glow,
    required this.accent,
    required this.disc,
  });

  static const fallback = _ArtworkPalette(
    base: Color(0xFF0A4F73),
    dark: Color(0xFF041426),
    deep: Color(0xFF020817),
    glow: Color(0xFF13D7E4),
    accent: Color(0xFF66F4E8),
    disc: Color(0xFF0A315C),
  );

  final Color base;
  final Color dark;
  final Color deep;
  final Color glow;
  final Color accent;
  final Color disc;

  static _ArtworkPalette fallbackFor(String? seed) {
    final value =
        (seed ?? 'melo').codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final hue = (value % 360).toDouble();
    return _ArtworkPalette.fromColor(
      HSLColor.fromAHSL(1, hue, .54, .46).toColor(),
    );
  }

  static _ArtworkPalette fromPixels(Uint8List pixels, int width, int height) {
    if (pixels.isEmpty || width <= 0 || height <= 0) return fallback;

    var red = 0.0;
    var green = 0.0;
    var blue = 0.0;
    var total = 0.0;
    final pixelCount = width * height;
    final step = (pixelCount / 2400).ceil().clamp(1, 18);

    for (var pixel = 0; pixel < pixelCount; pixel += step) {
      final offset = pixel * 4;
      if (offset + 3 >= pixels.length) break;
      final alpha = pixels[offset + 3];
      if (alpha < 96) continue;

      final r = pixels[offset];
      final g = pixels[offset + 1];
      final b = pixels[offset + 2];
      final color = Color.fromARGB(255, r, g, b);
      final hsl = HSLColor.fromColor(color);
      final saturation = hsl.saturation;
      final lightness = hsl.lightness;
      var weight = .2 + saturation;
      if (lightness < .12 || lightness > .9) weight *= .35;
      red += r * weight;
      green += g * weight;
      blue += b * weight;
      total += weight;
    }

    if (total <= 0) return fallback;
    return _ArtworkPalette.fromColor(
      Color.fromARGB(
        255,
        (red / total).round().clamp(0, 255),
        (green / total).round().clamp(0, 255),
        (blue / total).round().clamp(0, 255),
      ),
    );
  }

  static _ArtworkPalette fromColor(Color source) {
    final hsl = HSLColor.fromColor(source);
    final saturation = (hsl.saturation * 1.28).clamp(.34, .82).toDouble();
    final hue = hsl.hue;
    final base = hsl
        .withSaturation(saturation)
        .withLightness(hsl.lightness.clamp(.34, .54).toDouble())
        .toColor();
    final dark = hsl
        .withSaturation((saturation * .92).clamp(.28, .72).toDouble())
        .withLightness(.16)
        .toColor();
    final deep = hsl
        .withSaturation((saturation * .72).clamp(.22, .58).toDouble())
        .withLightness(.055)
        .toColor();
    final glow = hsl
        .withHue((hue + 16) % 360)
        .withSaturation((saturation * 1.12).clamp(.42, .9).toDouble())
        .withLightness(.58)
        .toColor();
    final accent = hsl
        .withHue((hue + 34) % 360)
        .withSaturation((saturation * 1.18).clamp(.48, .92).toDouble())
        .withLightness(.66)
        .toColor();
    final disc = hsl
        .withSaturation((saturation * .72).clamp(.24, .6).toDouble())
        .withLightness(.24)
        .toColor();
    return _ArtworkPalette(
      base: base,
      dark: dark,
      deep: deep,
      glow: glow,
      accent: accent,
      disc: disc,
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
  const _DynamicBackdrop({
    required this.track,
    required this.palette,
    required this.isPlaying,
  });

  final SourceTrack? track;
  final _ArtworkPalette palette;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final currentTrack = track;
    final artwork = currentTrack?.artwork;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Stack(
        key: ValueKey(artwork?.toString() ?? currentTrack?.title ?? 'empty'),
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
              child: Transform.scale(
                scale: 1.18,
                child: artwork == null || artwork.toString().isEmpty
                    ? _BackdropPlaceholder(seed: currentTrack?.title ?? 'melo')
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final backdropPixels = _fullscreenDecodedPixels(
                            context,
                            constraints.biggest.longestSide,
                            scale: 1.15,
                          );
                          return Image(
                            image: _fullscreenArtworkProvider(
                              artwork,
                              targetPixels: backdropPixels,
                              cacheWidth: backdropPixels,
                              cacheHeight: backdropPixels,
                            ),
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.low,
                            gaplessPlayback: true,
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              if (wasSynchronouslyLoaded || frame != null) {
                                return child;
                              }
                              return _BackdropPlaceholder(
                                seed: currentTrack?.title ?? 'melo',
                              );
                            },
                            errorBuilder: (_, __, ___) => _BackdropPlaceholder(
                              seed: currentTrack?.title ?? 'melo',
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 720),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.deep.withValues(alpha: .9),
                  palette.dark.withValues(alpha: .76),
                  palette.base.withValues(alpha: .48),
                  palette.deep.withValues(alpha: .92),
                ],
                stops: const [0, .34, .68, 1],
              ),
            ),
          ),
          _BackdropMotionOverlay(palette: palette, isPlaying: isPlaying),
          AnimatedContainer(
            duration: const Duration(milliseconds: 720),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: .24),
                  palette.dark.withValues(alpha: .12),
                  Colors.black.withValues(alpha: .48),
                ],
                stops: const [0, .52, 1],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 720),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-.74, -.54),
                radius: 1.05,
                colors: [
                  palette.accent.withValues(alpha: .17),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 720),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(.82, .12),
                radius: .86,
                colors: [
                  palette.glow.withValues(alpha: .13),
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

class _BackdropMotionOverlay extends StatefulWidget {
  const _BackdropMotionOverlay({
    required this.palette,
    required this.isPlaying,
  });

  final _ArtworkPalette palette;
  final bool isPlaying;

  @override
  State<_BackdropMotionOverlay> createState() => _BackdropMotionOverlayState();
}

class _BackdropMotionOverlayState extends State<_BackdropMotionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _BackdropMotionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: SweepGradient(
                  center: Alignment.center,
                  transform: GradientRotation(_controller.value * 2 * math.pi),
                  colors: [
                    Colors.transparent,
                    widget.palette.glow.withValues(alpha: .18),
                    Colors.transparent,
                    widget.palette.accent.withValues(alpha: .11),
                    Colors.transparent,
                  ],
                  stops: const [0, .18, .36, .62, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(.1, .82),
                  radius: .94,
                  colors: [
                    widget.palette.glow.withValues(
                      alpha: widget.isPlaying ? .36 : .2,
                    ),
                    widget.palette.base.withValues(alpha: .14),
                    Colors.transparent,
                  ],
                  stops: const [0, .42, 1],
                ),
              ),
            ),
          ],
        );
      },
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

class _MobileFullscreenBackButton extends StatelessWidget {
  const _MobileFullscreenBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '返回',
      child: Semantics(
        button: true,
        label: '返回',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .09),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Transform.translate(
              offset: const Offset(-2, 0),
              child: Icon(
                Icons.chevron_left_rounded,
                color: Colors.white.withValues(alpha: .72),
                size: 30,
              ),
            ),
          ),
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
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _MobileFullscreenBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Text(
                '正在播放',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: .88),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
              ),
            ],
          ),
        ),
      );
    }

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
    required this.palette,
  });

  final SourceTrack? track;
  final DemoRepository repository;
  final RightSidebarMode mode;
  final _ArtworkPalette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final drawerWidth = constraints.maxWidth < 1180
            ? constraints.maxWidth * .42
            : constraints.maxWidth * .34;
        final recordSize = (constraints.maxHeight - 410).clamp(160.0, 360.0);
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
                          recordSize: recordSize,
                          palette: palette,
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

/// 为全屏封面舞台构建专辑封面 widget。
Widget _fullscreenArtwork(
  BuildContext context,
  SourceTrack track, {
  required double displaySize,
}) {
  final url = track.artwork;
  if (url != null && url.toString().isNotEmpty) {
    final decodedPixels = _fullscreenDecodedPixels(context, displaySize);
    return Image(
      image: _fullscreenArtworkProvider(
        url,
        targetPixels: decodedPixels,
        cacheWidth: decodedPixels,
        cacheHeight: decodedPixels,
      ),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _ArtworkPlaceholder(seed: track.title);
      },
      errorBuilder: (_, __, ___) => _ArtworkPlaceholder(seed: track.title),
    );
  }
  return _ArtworkPlaceholder(seed: track.title);
}

int _fullscreenDecodedPixels(
  BuildContext context,
  double displaySize, {
  double scale = 1.35,
}) {
  final effectiveSize =
      displaySize.isFinite && displaySize > 0 ? displaySize : 640.0;
  return (effectiveSize * MediaQuery.devicePixelRatioOf(context) * scale)
      .round()
      .clamp(320, 1000)
      .toInt();
}

ImageProvider<Object> _fullscreenArtworkProvider(
  Uri artwork, {
  int targetPixels = 1000,
  int? cacheWidth,
  int? cacheHeight,
}) {
  return meloCachedArtworkProvider(
    artwork,
    targetPixels: targetPixels,
    highResolution: true,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
  );
}

class _FullscreenArtworkStage extends StatefulWidget {
  const _FullscreenArtworkStage({
    required this.track,
    required this.palette,
    required this.isPlaying,
    required this.size,
    super.key,
  });

  final SourceTrack track;
  final _ArtworkPalette palette;
  final bool isPlaying;
  final double size;

  @override
  State<_FullscreenArtworkStage> createState() =>
      _FullscreenArtworkStageState();
}

class _FullscreenArtworkStageState extends State<_FullscreenArtworkStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _FullscreenArtworkStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final stageSize = size + 42;
    final coverSize = (size * .76).clamp(176.0, 292.0);
    final radius = BorderRadius.circular(coverSize * .105);

    return SizedBox(
      width: stageSize,
      height: stageSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final pulse = widget.isPlaying
              ? .88 + math.sin(_controller.value * math.pi * 2) * .12
              : .58;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _FullscreenArtworkHaloPainter(
                    palette: widget.palette,
                    progress: _controller.value,
                    pulse: pulse,
                    isPlaying: widget.isPlaying,
                  ),
                ),
              ),
              Transform.scale(
                scale: widget.isPlaying ? 1 + (pulse - .88) * .025 : 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: widget.palette.deep.withValues(alpha: .54),
                        blurRadius: 44,
                        offset: const Offset(0, 24),
                      ),
                      BoxShadow(
                        color: widget.palette.glow.withValues(
                          alpha: widget.isPlaying ? .34 : .18,
                        ),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: SizedBox.square(
                      dimension: coverSize,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _fullscreenArtwork(
                            context,
                            widget.track,
                            displaySize: coverSize,
                          ),
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: radius,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .18),
                                  width: 1.2,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: .16),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: .18),
                                  ],
                                  stops: const [0, .38, 1],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  size: Size.square(coverSize + 34),
                  painter: _FullscreenCoverNeedlePainter(
                    color: widget.palette.accent.withValues(
                      alpha: widget.isPlaying ? .52 : .26,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FullscreenArtworkHaloPainter extends CustomPainter {
  const _FullscreenArtworkHaloPainter({
    required this.palette,
    required this.progress,
    required this.pulse,
    required this.isPlaying,
  });

  final _ArtworkPalette palette;
  final double progress;
  final double pulse;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .42;

    final fog = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.glow.withValues(alpha: .2 * pulse),
          palette.base.withValues(alpha: .1 * pulse),
          Colors.transparent,
        ],
        stops: const [0, .52, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.32));
    canvas.drawCircle(center, radius * 1.32, fog);

    final disc = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.disc.withValues(alpha: .18),
          palette.deep.withValues(alpha: .5),
          Colors.black.withValues(alpha: .28),
        ],
        stops: const [0, .62, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, disc);

    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75;
    for (var i = 0; i < 16; i++) {
      final t = i / 15;
      groovePaint.color = Color.lerp(palette.accent, Colors.white, .22)!
          .withValues(alpha: (.035 + t * .08) * pulse);
      canvas.drawCircle(center, radius * (.42 + t * .52), groovePaint);
    }

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(progress * math.pi * 2),
        colors: [
          Colors.transparent,
          palette.accent.withValues(alpha: isPlaying ? .72 : .34),
          palette.glow.withValues(alpha: isPlaying ? .4 : .2),
          Colors.transparent,
        ],
        stops: const [0, .18, .29, .46],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 2));
    canvas.drawCircle(center, radius + 2, sweep);
  }

  @override
  bool shouldRepaint(covariant _FullscreenArtworkHaloPainter oldDelegate) {
    return oldDelegate.palette != palette ||
        oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.isPlaying != isPlaying;
  }
}

class _FullscreenCoverNeedlePainter extends CustomPainter {
  const _FullscreenCoverNeedlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 2),
      -math.pi * .78,
      math.pi * .32,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FullscreenCoverNeedlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DesktopAlbumStage extends StatelessWidget {
  const _DesktopAlbumStage({
    required this.track,
    required this.repository,
    required this.recordSize,
    required this.palette,
  });

  final SourceTrack? track;
  final DemoRepository repository;
  final double recordSize;
  final _ArtworkPalette palette;

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

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FullscreenArtworkStage(
              size: recordSize,
              isPlaying: repository.isPlaybackActive,
              track: current,
              palette: palette,
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
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MeloSpacing.xs,
              runSpacing: MeloSpacing.xs,
              children: [
                _MobileProviderBadge(providerId: current.ref.providerId),
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
        ),
      ),
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
    required this.palette,
  });

  final SourceTrack? track;
  final DemoRepository repository;
  final _ArtworkPalette palette;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final bottomPadding = bottomInset + 8;
        final availableHeight =
            (constraints.maxHeight - MeloSpacing.xs - bottomPadding)
                .clamp(0, double.infinity)
                .toDouble();
        final maxArtworkByWidth =
            (constraints.maxWidth - (MeloSpacing.md * 2) - 68)
                .clamp(196, 344)
                .toDouble();
        final maxArtworkByHeight =
            (constraints.maxHeight * .42).clamp(224, 344).toDouble();
        final coverSize = maxArtworkByWidth < maxArtworkByHeight
            ? maxArtworkByWidth
            : maxArtworkByHeight;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            MeloSpacing.md,
            MeloSpacing.xs,
            MeloSpacing.md,
            bottomPadding,
          ),
          child: SizedBox(
            height: availableHeight,
            child: _PrimaryPlayerPanel(
              track: widget.track,
              repository: widget.repository,
              coverSize: coverSize,
              palette: widget.palette,
              compact: true,
              showLyrics: _showLyrics,
              onLyricsToggle: widget.track == null
                  ? null
                  : () => setState(() => _showLyrics = !_showLyrics),
              onQueuePressed: widget.track == null ? null : _showQueue,
            ),
          ),
        );
      },
    );
  }
}

class _PrimaryPlayerPanel extends StatelessWidget {
  const _PrimaryPlayerPanel({
    required this.track,
    required this.repository,
    required this.coverSize,
    required this.palette,
    this.compact = false,
    this.showLyrics = false,
    this.onLyricsToggle,
    this.onQueuePressed,
  });

  final SourceTrack? track;
  final DemoRepository repository;
  final double coverSize;
  final _ArtworkPalette palette;
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

    final artworkSize =
        compact ? coverSize.clamp(220, 318).toDouble() : coverSize;
    final artworkHeight = compact ? artworkSize + 78 : artworkSize + 116;
    if (compact) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
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
                        : _FullscreenArtworkStage(
                            key: const ValueKey('mobile-artwork-stage'),
                            size: artworkSize.clamp(220, 318),
                            isPlaying: repository.isPlaybackActive,
                            track: track!,
                            palette: palette,
                          ),
                  ),
                  const SizedBox(height: 42),
                  Text(
                    track!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          height: 1.02,
                          letterSpacing: 0,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          track!.artists.join(' / '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: .68),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MobileProviderBadge(providerId: track!.ref.providerId),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _FullscreenProgress(repository: repository),
          const SizedBox(height: 12),
          _FullscreenTransport(
            repository: repository,
            track: track!,
            compact: true,
          ),
          const SizedBox(height: 12),
          _SecondaryControls(
            repository: repository,
            track: track!,
            compact: true,
            showLyrics: showLyrics,
            onLyricsToggle: onLyricsToggle,
            onQueuePressed: onQueuePressed,
          ),
        ],
      );
    }

    final children = [
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
            : _FullscreenArtworkStage(
                key: const ValueKey('mobile-artwork-stage'),
                size: artworkSize,
                isPlaying: repository.isPlaybackActive,
                track: track!,
                palette: palette,
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
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: MeloSpacing.xs,
          runSpacing: MeloSpacing.xs,
          children: [
            _MobileProviderBadge(providerId: track!.ref.providerId),
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
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
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
            tooltip: repository.shuffleEnabled ? '关闭随机播放' : '随机播放',
            icon: Icons.shuffle_rounded,
            active: repository.shuffleEnabled,
            buttonSize: 44,
            iconSize: 23,
            onPressed: repository.toggleShuffle,
          ),
          const SizedBox(width: 8),
          _GlassIconButton(
            tooltip: '上一首',
            icon: Icons.skip_previous_rounded,
            buttonSize: 50,
            iconSize: 30,
            onPressed: repository.queuePrevious,
          ),
          const SizedBox(width: 10),
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
          const SizedBox(width: 10),
          _GlassIconButton(
            tooltip: '下一首',
            icon: Icons.skip_next_rounded,
            buttonSize: 50,
            iconSize: 30,
            onPressed: repository.queueNext,
          ),
          const SizedBox(width: 8),
          _GlassIconButton(
            tooltip: _repeatTooltip(repository.repeatMode),
            icon: repository.repeatMode == PlaybackRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            active: repository.repeatMode != PlaybackRepeatMode.off,
            buttonSize: 44,
            iconSize: 23,
            onPressed: repository.cycleRepeatMode,
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
        _GlassIconButton(
          tooltip: '加入本地歌单',
          icon: Icons.playlist_add_rounded,
          buttonSize: compact ? 44 : null,
          iconSize: compact ? 24 : null,
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) => MeloAddToPlaylistDialog(track: track),
            );
          },
        ),
        if (onLyricsToggle != null)
          _GlassIconButton(
            tooltip: showLyrics ? '返回唱片' : '显示歌词',
            icon: showLyrics ? Icons.album_rounded : Icons.subtitles_rounded,
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
          minimumSize: Size.square(size),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class _MobileProviderBadge extends StatelessWidget {
  const _MobileProviderBadge({required this.providerId});

  final ProviderId providerId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF062C4D).withValues(alpha: .54),
        border: Border.all(
          color: const Color(0xFF13E8F2).withValues(alpha: .62),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF13E8F2).withValues(alpha: .24),
            blurRadius: 10,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Transform.scale(
        scale: .72,
        child: MeloPlatformIcon(providerId: providerId),
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
