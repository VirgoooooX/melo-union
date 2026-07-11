import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../bootstrap/demo_repository.dart';
import '../design/melo_tokens.dart';
import '../presentation/provider_presentation.dart';
import '../presentation/shell_accent.dart';
import 'melo_file_cached_image_provider.dart';

abstract final class MeloListMetrics {
  static const rowHeight = 64.0;
  static const compactRowHeight = 48.0;
  static const mobileTrackRowHeight = 68.0;
  static const trackCoverSize = 42.0;
  static const sourceColumnWidth = 132.0;
  static const actionColumnWidth = 84.0;
  static const rowHorizontalPadding = 16.0;
}

/// Shared headers for artwork image requests across music providers.
const meloArtworkHeaders = <String, String>{
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://music.163.com',
};

class MeloInteractiveRow extends StatefulWidget {
  const MeloInteractiveRow({
    required this.builder,
    this.onTap,
    this.onDoubleTap,
    this.selected = false,
    this.height = MeloListMetrics.rowHeight,
    this.padding = const EdgeInsets.symmetric(
      horizontal: MeloListMetrics.rowHorizontalPadding,
    ),
    super.key,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool selected;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  State<MeloInteractiveRow> createState() => _MeloInteractiveRowState();
}

class _MeloInteractiveRowState extends State<MeloInteractiveRow> {
  bool _hovered = false;
  DateTime? _lastPrimaryDownAt;
  Offset? _lastPrimaryDownPosition;

  @override
  Widget build(BuildContext context) {
    final background = widget.selected
        ? MeloColors.primary50
        : _hovered
            ? MeloColors.surfaceHover
            : Colors.transparent;
    final leftAccent =
        widget.selected ? MeloColors.primary500 : Colors.transparent;

    final row = AnimatedContainer(
      duration: Duration.zero,
      curve: Curves.easeOutCubic,
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          left: BorderSide(color: leftAccent, width: 3),
        ),
      ),
      child: widget.builder(context, _hovered),
    );

    Widget interactiveRow = row;
    if (widget.onTap != null) {
      interactiveRow = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: interactiveRow,
      );
    } else if (widget.onDoubleTap != null) {
      interactiveRow = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handlePointerDown,
        child: interactiveRow,
      );
    }

    return MouseRegion(
      cursor: widget.onTap == null && widget.onDoubleTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: interactiveRow,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    final onDoubleTap = widget.onDoubleTap;
    if (onDoubleTap == null || event.buttons != kPrimaryButton) return;

    final now = DateTime.now();
    final previousAt = _lastPrimaryDownAt;
    final previousPosition = _lastPrimaryDownPosition;
    _lastPrimaryDownAt = now;
    _lastPrimaryDownPosition = event.localPosition;
    if (previousAt == null || previousPosition == null) return;

    final elapsed = now.difference(previousAt);
    final distance = (event.localPosition - previousPosition).distance;
    if (elapsed <= const Duration(milliseconds: 320) && distance <= 12) {
      _lastPrimaryDownAt = null;
      _lastPrimaryDownPosition = null;
      onDoubleTap();
    }
  }
}

class MeloTapFeedback extends StatefulWidget {
  const MeloTapFeedback({
    required this.child,
    this.onTap,
    this.borderRadius = MeloRadii.sm,
    this.selected = false,
    this.animatePress = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final bool selected;
  final bool animatePress;

  @override
  State<MeloTapFeedback> createState() => _MeloTapFeedbackState();
}

class _MeloTapFeedbackState extends State<MeloTapFeedback> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final background =
        widget.selected ? MeloColors.primary50 : Colors.transparent;
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: widget.borderRadius,
      ),
      child: widget.child,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
          interactive && widget.animatePress ? (_) => _setPressed(true) : null,
      onTapCancel:
          interactive && widget.animatePress ? () => _setPressed(false) : null,
      onTapUp:
          interactive && widget.animatePress ? (_) => _setPressed(false) : null,
      onTap: interactive ? _handleTap : null,
      child: widget.animatePress
          ? AnimatedScale(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOutCubic,
              scale: _pressed ? .982 : 1,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 70),
                curve: Curves.easeOutCubic,
                opacity: _pressed ? .88 : 1,
                child: child,
              ),
            )
          : child,
    );
  }
}

class MeloTrackCover extends StatefulWidget {
  const MeloTrackCover({
    required this.seed,
    this.artwork,
    this.isActive = false,
    this.size = MeloListMetrics.trackCoverSize,
    this.borderRadius,
    super.key,
  });

  final String seed;
  final Uri? artwork;
  final bool isActive;
  final double size;
  final BorderRadius? borderRadius;

  @override
  State<MeloTrackCover> createState() => _MeloTrackCoverState();
}

class _MeloTrackCoverState extends State<MeloTrackCover> {
  late final DisposableBuildContext<_MeloTrackCoverState> _scrollAwareContext =
      DisposableBuildContext(this);

  @override
  void dispose() {
    _scrollAwareContext.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    if (artwork != null && artwork.toString().isNotEmpty) {
      final desktopLayout = MediaQuery.sizeOf(context).width >= 960;
      final displayPixels =
          (widget.size * MediaQuery.devicePixelRatioOf(context)).round();
      final cacheSize = (displayPixels * (desktopLayout ? 3.0 : 1.6))
          .round()
          .clamp(desktopLayout ? 144 : 128, desktopLayout ? 256 : 320)
          .toInt();
      final ImageProvider<Object> baseProvider = meloCachedArtworkProvider(
        artwork,
        targetPixels: desktopLayout ? 640 : cacheSize,
        highResolution: desktopLayout,
      );
      final imageProvider = ScrollAwareImageProvider<Object>(
        context: _scrollAwareContext,
        imageProvider: ResizeImage.resizeIfNeeded(
          cacheSize,
          cacheSize,
          baseProvider,
        ),
      );
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? MeloRadii.sm,
          boxShadow: widget.isActive ? MeloShadows.control : const [],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? MeloRadii.sm,
          clipBehavior: desktopLayout ? Clip.antiAlias : Clip.hardEdge,
          child: Image(
            image: imageProvider,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            filterQuality:
                desktopLayout ? FilterQuality.high : FilterQuality.medium,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return _placeholder(withShadow: false);
            },
            errorBuilder: (_, __, ___) => _placeholder(withShadow: false),
          ),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool withShadow = true}) {
    final hue =
        widget.seed.codeUnits.fold<int>(0, (total, value) => total + value) %
            360;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? MeloRadii.sm,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .54, .62).toColor(),
            HSLColor.fromAHSL(1, (hue + 48) % 360, .54, .40).toColor(),
          ],
        ),
        boxShadow:
            withShadow && widget.isActive ? MeloShadows.control : const [],
      ),
      child: Icon(
        widget.isActive ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
        color: Colors.white,
        size: widget.isActive ? widget.size * .42 : widget.size * .48,
      ),
    );
  }
}

/// Standalone artwork placeholder with deterministic HSL gradient.
///
/// Use across the app as a consistent fallback when artwork URL is
/// missing or fails to load. Color is derived from [seed] so the same
/// track always gets the same hue.
class MeloArtworkPlaceholder extends StatelessWidget {
  const MeloArtworkPlaceholder({
    required this.seed,
    this.size = MeloListMetrics.trackCoverSize,
    this.borderRadius,
    super.key,
  });

  final String seed;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? MeloRadii.sm,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .54, .62).toColor(),
            HSLColor.fromAHSL(1, (hue + 48) % 360, .54, .40).toColor(),
          ],
        ),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.white),
    );
  }
}

/// Standardized empty state view — icon, title, optional subtitle.
class MeloEmptyState extends StatelessWidget {
  const MeloEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: MeloColors.primary50,
              borderRadius: MeloRadii.lg,
            ),
            child: Icon(icon, color: MeloColors.primary700, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: MeloColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standardized error state — message with optional retry button.
class MeloErrorState extends StatelessWidget {
  const MeloErrorState({
    required this.message,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: MeloColors.textTertiary,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Play/pause button with built-in starting spinner and completed-handling.
///
/// Wraps [FilledButton] with [CircleBorder]. Shows a [CircularProgressIndicator]
/// when [starting] is true, play/pause icon otherwise. When [completed] is true,
/// pressing the button triggers [onCompletedTap] (defaults to seek-to-zero +
/// play) instead of [onPressed].
class MeloPlayButton extends StatelessWidget {
  const MeloPlayButton({
    required this.isPlaying,
    required this.isStarting,
    required this.isCompleted,
    required this.onPressed,
    this.onCompletedTap,
    this.enabled = true,
    this.size = 42,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final bool isPlaying;
  final bool isStarting;
  final bool isCompleted;
  final VoidCallback onPressed;
  final VoidCallback? onCompletedTap;
  final bool enabled;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled
          ? (isCompleted ? (onCompletedTap ?? onPressed) : onPressed)
          : null,
      style: FilledButton.styleFrom(
        fixedSize: Size.square(size),
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
      child: isStarting
          ? SizedBox.square(
              dimension: size * 0.42,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor ?? Colors.white,
              ),
            )
          : Icon(
              isPlaying && !isCompleted
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: size * 0.48,
            ),
    );
  }
}

class MeloSourceBadge extends StatelessWidget {
  const MeloSourceBadge({
    required this.providerId,
    this.label,
    this.minWidth = 44.0,
    this.maxWidth = 62.0,
    super.key,
  });

  final ProviderId providerId;
  final String? label;
  final double? minWidth;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final presentation = meloProviderPresentation(providerId);
    final text = label ?? presentation.shortName;
    return Container(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0.0,
        maxWidth: maxWidth ?? double.infinity,
      ),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: presentation.backgroundColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: presentation.foregroundColor.withValues(alpha: .28),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: presentation.foregroundColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
      ),
    );
  }
}

class MeloPlaylistCard extends StatefulWidget {
  const MeloPlaylistCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.cover,
    this.width,
    this.compact = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final Uri? cover;
  final VoidCallback onTap;
  final double? width;
  final bool compact;

  @override
  State<MeloPlaylistCard> createState() => _MeloPlaylistCardState();
}

class _MeloPlaylistCardState extends State<MeloPlaylistCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final content = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(widget.compact ? 4 : 10),
          decoration: BoxDecoration(
            color: _hovered
                ? MeloColors.surfaceHover
                : MeloColors.surfaceHover.withValues(alpha: 0),
            borderRadius: MeloRadii.md,
            border: Border.all(
              color: _hovered
                  ? MeloColors.borderStrong
                  : MeloColors.borderStrong.withValues(alpha: 0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: MeloPlaylistCover(
                  title: widget.title,
                  cover: widget.cover,
                ),
              ),
              SizedBox(height: widget.compact ? 8 : 10),
              SizedBox(
                height: 34,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MeloColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MeloColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.width == null) return content;
    return SizedBox(width: widget.width, child: content);
  }
}

class MeloPlaylistCover extends StatefulWidget {
  const MeloPlaylistCover({
    required this.title,
    this.cover,
    super.key,
  });

  final String title;
  final Uri? cover;

  @override
  State<MeloPlaylistCover> createState() => _MeloPlaylistCoverState();
}

class _MeloPlaylistCoverState extends State<MeloPlaylistCover> {
  late final DisposableBuildContext<_MeloPlaylistCoverState>
      _scrollAwareContext = DisposableBuildContext(this);

  @override
  void dispose() {
    _scrollAwareContext.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.cover;
    if (cover != null && cover.toString().isNotEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final desktopLayout = MediaQuery.sizeOf(context).width >= 960;
          final pixelRatio = MediaQuery.devicePixelRatioOf(context);
          final decodedWidth = constraints.maxWidth.isFinite
              ? (constraints.maxWidth *
                      pixelRatio *
                      (desktopLayout ? 6.0 : 1.0))
                  .round()
                  .clamp(desktopLayout ? 768 : 128, desktopLayout ? 1200 : 480)
                  .toInt()
              : null;
          final decodedHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight *
                      pixelRatio *
                      (desktopLayout ? 6.0 : 1.0))
                  .round()
                  .clamp(desktopLayout ? 768 : 128, desktopLayout ? 1200 : 480)
                  .toInt()
              : decodedWidth;
          final ImageProvider<Object> baseProvider = meloCachedArtworkProvider(
            cover,
            targetPixels: desktopLayout ? 1000 : decodedWidth ?? 480,
            highResolution: desktopLayout,
          );
          final imageProvider = ScrollAwareImageProvider<Object>(
            context: _scrollAwareContext,
            imageProvider: ResizeImage.resizeIfNeeded(
              decodedWidth,
              decodedHeight,
              baseProvider,
            ),
          );

          return ClipRRect(
            borderRadius: MeloRadii.md,
            child: Image(
              image: imageProvider,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              filterQuality:
                  desktopLayout ? FilterQuality.high : FilterQuality.medium,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
          );
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hue =
        widget.title.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
    return Container(
      decoration: BoxDecoration(
        borderRadius: MeloRadii.md,
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .48, .64).toColor(),
            HSLColor.fromAHSL(1, (hue + 36) % 360, .50, .42).toColor(),
          ],
        ),
      ),
      child: const Icon(Icons.queue_music_rounded, color: Colors.white),
    );
  }
}

ImageProvider<Object> meloCachedArtworkProvider(
  Uri artwork, {
  required int targetPixels,
  required bool highResolution,
  int? cacheWidth,
  int? cacheHeight,
}) {
  final provider = MeloFileCachedNetworkImageProvider(
    meloArtworkRequestUri(
      artwork,
      targetPixels,
      highResolution: highResolution,
    ).toString(),
    headers: meloArtworkHeaders,
  );
  return ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, provider);
}

Uri meloArtworkRequestUri(
  Uri artwork,
  int targetPixels, {
  required bool highResolution,
}) {
  final host = artwork.host.toLowerCase();
  if (host.endsWith('music.126.net')) {
    final thumbnailSize =
        targetPixels.clamp(160, highResolution ? 1000 : 320).toInt();
    return artwork.replace(
      queryParameters: {
        ...artwork.queryParameters,
        'param': '${thumbnailSize}y$thumbnailSize',
      },
    );
  }
  if (highResolution &&
      (host.endsWith('gtimg.cn') || host.endsWith('qq.com'))) {
    final size = targetPixels > 900 ? 1000 : 800;
    final upgraded = artwork.toString().replaceFirst(
          RegExp(r'T002R\d+x\d+M000'),
          'T002R${size}x${size}M000',
        );
    return Uri.parse(upgraded);
  }
  return artwork;
}

String meloProviderLabel(ProviderId id) {
  return meloProviderPresentation(id).shortName;
}

/// Unified SnackBar helper using the Melo design system.
///
/// White card with teal accent bar, styled via [SnackBarThemeData]
/// in [MeloTheme]. Hides any current SnackBar first to prevent stacking.
abstract final class MeloSnackbar {
  static OverlayEntry? _activeEntry;
  static Timer? _activeTimer;

  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    _activeTimer?.cancel();
    if (_activeEntry != null) {
      try {
        _activeEntry?.remove();
      } catch (_) {}
      _activeEntry = null;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) => _MeloToastWidget(
        message: message,
        duration: duration,
        onDismiss: () {
          if (_activeEntry != null) {
            try {
              _activeEntry?.remove();
            } catch (_) {}
            _activeEntry = null;
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _MeloToastWidget extends StatefulWidget {
  const _MeloToastWidget({
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_MeloToastWidget> createState() => _MeloToastWidgetState();
}

class _MeloToastWidgetState extends State<_MeloToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (_isDismissed || !mounted) return;
    _isDismissed = true;
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 16,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                      minWidth: 120,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: .06), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized track more menu (play next / add to playlist).
///
/// Use in any track row to provide consistent actions and feedback.
/// Pass [addToPlaylistDialog] to customize the "add to playlist" action.
/// When omitted, the shared local-playlist picker is used.
class MeloTrackMoreMenu extends ConsumerWidget {
  const MeloTrackMoreMenu({
    this.track,
    this.unifiedTrack,
    this.providerId,
    this.playlistId,
    this.onDelete,
    this.addToPlaylistDialog,
    super.key,
  }) : assert(track != null || unifiedTrack != null);

  final SourceTrack? track;
  final UnifiedFavoriteTrack? unifiedTrack;
  final String? providerId;
  final String? playlistId;
  final VoidCallback? onDelete;
  final Widget? addToPlaylistDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;

    final variants = unifiedTrack != null
        ? (providerId == null
            ? unifiedTrack!.variants
            : unifiedTrack!.variants
                .where((item) => item.ref.providerId.value == providerId)
                .toList(growable: false))
        : (track != null ? [track!] : <SourceTrack>[]);

    if (variants.isEmpty) return const SizedBox.shrink();
    final primaryTrack = variants.first;
    final repository = ref.watch(demoRepositoryProvider);

    final hasFavorite = variants.any((v) => v.isFavorited);
    final isFavorited = variants.length > 1 ? hasFavorite : primaryTrack.isFavorited;
    final showPlayNext = repository.queue.entries.length >= 2;

    if (isMobile) {
      return IconButton(
        tooltip: '操作',
        icon: const Icon(Icons.more_horiz_rounded, size: 22),
        onPressed: () => _showMobileBottomSheet(
          context: context,
          ref: ref,
          repository: repository,
          variants: variants,
          primaryTrack: primaryTrack,
          isFavorited: isFavorited,
          showPlayNext: showPlayNext,
        ),
      );
    }

    return PopupMenuButton<_TrackMenuAction>(
      tooltip: '操作',
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      offset: const Offset(0, 42),
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration.zero,
        reverseDuration: Duration.zero,
        curve: Curves.linear,
        reverseCurve: Curves.linear,
      ),
      onSelected: (action) async {
        await _handleMenuAction(
          context: context,
          ref: ref,
          repository: repository,
          action: action,
          variants: variants,
          primaryTrack: primaryTrack,
          isFavorited: isFavorited,
        );
      },
      itemBuilder: (context) => [
        if (variants.length > 1)
          PopupMenuItem(
            value: _TrackMenuAction.manageFavorites,
            child: const _MeloTrackMenuItem(
              icon: Icons.favorite_rounded,
              iconColor: MeloColors.favorite,
              label: '管理收藏来源',
            ),
          )
        else
          PopupMenuItem(
            value: _TrackMenuAction.favoriteToggle,
            child: _MeloTrackMenuItem(
              icon: isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              iconColor: isFavorited ? MeloColors.favorite : null,
              label: isFavorited ? '取消收藏' : '收藏',
            ),
          ),
        if (primaryTrack.isPlayable)
          const PopupMenuItem(
            value: _TrackMenuAction.appendToQueue,
            child: _MeloTrackMenuItem(
              icon: Icons.queue_music_rounded,
              label: '添加到队列末尾',
            ),
          ),
        if (showPlayNext)
          const PopupMenuItem(
            value: _TrackMenuAction.playNext,
            child: _MeloTrackMenuItem(
              icon: Icons.playlist_play_rounded,
              label: '添加到下一首播放',
            ),
          ),
        if (repository.canDownloadTrack(primaryTrack))
          const PopupMenuItem(
            value: _TrackMenuAction.download,
            child: _MeloTrackMenuItem(
              icon: Icons.download_rounded,
              label: '下载',
            ),
          ),
        PopupMenuItem(
          value: _TrackMenuAction.addToPlaylist,
          child: const _MeloTrackMenuItem(
            icon: Icons.playlist_add_rounded,
            label: '加入本地歌单',
          ),
        ),
        if (playlistId != null || onDelete != null)
          PopupMenuItem(
            value: _TrackMenuAction.delete,
            child: const _MeloTrackMenuItem(
              icon: Icons.delete_outline_rounded,
              iconColor: MeloColors.warning,
              label: '从歌单中删除',
            ),
          ),
      ],
    );
  }

  void _showMobileBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    required DemoRepository repository,
    required List<SourceTrack> variants,
    required SourceTrack primaryTrack,
    required bool isFavorited,
    required bool showPlayNext,
  }) {
    final title = unifiedTrack?.title ?? primaryTrack.title;
    final artists = unifiedTrack?.artists.join(' / ') ?? primaryTrack.artists.join(' / ');
    final artwork = unifiedTrack?.variants
            .firstWhere((v) => v.artwork != null, orElse: () => primaryTrack)
            .artwork ??
        primaryTrack.artwork;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: MeloColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    MeloTrackCover(
                      seed: title,
                      artwork: artwork,
                      size: 48,
                      borderRadius: MeloRadii.sm,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: MeloColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artists,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: MeloColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: MeloColors.border),
              if (variants.length > 1)
                _MeloBottomSheetItem(
                  icon: Icons.favorite_rounded,
                  color: MeloColors.favorite,
                  label: '管理收藏来源',
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_handleMenuAction(
                      context: context,
                      ref: ref,
                      repository: repository,
                      action: _TrackMenuAction.manageFavorites,
                      variants: variants,
                      primaryTrack: primaryTrack,
                      isFavorited: isFavorited,
                    ));
                  },
                )
              else
                _MeloBottomSheetItem(
                  icon: isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorited ? MeloColors.favorite : null,
                  label: isFavorited ? '取消收藏' : '收藏',
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_handleMenuAction(
                      context: context,
                      ref: ref,
                      repository: repository,
                      action: _TrackMenuAction.favoriteToggle,
                      variants: variants,
                      primaryTrack: primaryTrack,
                      isFavorited: isFavorited,
                    ));
                  },
                ),
              if (primaryTrack.isPlayable)
                _MeloBottomSheetItem(
                  icon: Icons.queue_music_rounded,
                  label: '添加到队列末尾',
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_handleMenuAction(
                      context: context,
                      ref: ref,
                      repository: repository,
                      action: _TrackMenuAction.appendToQueue,
                      variants: variants,
                      primaryTrack: primaryTrack,
                      isFavorited: isFavorited,
                    ));
                  },
                ),
              if (showPlayNext)
                _MeloBottomSheetItem(
                  icon: Icons.playlist_play_rounded,
                  label: '添加到下一首播放',
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_handleMenuAction(
                      context: context,
                      ref: ref,
                      repository: repository,
                      action: _TrackMenuAction.playNext,
                      variants: variants,
                      primaryTrack: primaryTrack,
                      isFavorited: isFavorited,
                    ));
                  },
                ),
              if (repository.canDownloadTrack(primaryTrack))
                _MeloBottomSheetItem(
                  icon: Icons.download_rounded,
                  label: '下载',
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_handleMenuAction(
                      context: context,
                      ref: ref,
                      repository: repository,
                      action: _TrackMenuAction.download,
                      variants: variants,
                      primaryTrack: primaryTrack,
                      isFavorited: isFavorited,
                    ));
                  },
                ),
              _MeloBottomSheetItem(
                icon: Icons.playlist_add_rounded,
                label: '加入本地歌单',
                onTap: () {
                  Navigator.pop(context);
                  unawaited(_handleMenuAction(
                    context: context,
                    ref: ref,
                    repository: repository,
                    action: _TrackMenuAction.addToPlaylist,
                    variants: variants,
                    primaryTrack: primaryTrack,
                    isFavorited: isFavorited,
                  ));
                },
              ),
              if (playlistId != null || onDelete != null)
                _MeloBottomSheetItem(
                  icon: Icons.delete_outline_rounded,
                  color: MeloColors.warning,
                  label: '从歌单中删除',
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_handleMenuAction(
                      context: context,
                      ref: ref,
                      repository: repository,
                      action: _TrackMenuAction.delete,
                      variants: variants,
                      primaryTrack: primaryTrack,
                      isFavorited: isFavorited,
                    ));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleMenuAction({
    required BuildContext context,
    required WidgetRef ref,
    required DemoRepository repository,
    required _TrackMenuAction action,
    required List<SourceTrack> variants,
    required SourceTrack primaryTrack,
    required bool isFavorited,
  }) async {
    switch (action) {
      case _TrackMenuAction.favoriteToggle:
        final newLiked = !isFavorited;
        try {
          await repository.toggleFavorite(
            track: primaryTrack,
            liked: newLiked,
          );
          if (context.mounted) {
            MeloSnackbar.show(
              context: context,
              message: newLiked ? '已收藏' : '已取消收藏',
              duration: const Duration(seconds: 1),
            );
          }
        } catch (error) {
          if (context.mounted) {
            final message = error is ProviderException ? error.message : '操作失败，请重试。';
            MeloSnackbar.show(context: context, message: message);
          }
        }
        break;
      case _TrackMenuAction.manageFavorites:
        if (unifiedTrack != null && context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => _FavoriteSourceDialog(
              track: unifiedTrack!,
              variants: variants,
            ),
          );
        }
        break;
      case _TrackMenuAction.appendToQueue:
        if (!primaryTrack.isPlayable) return;
        repository.enqueueTrack(primaryTrack);
        if (context.mounted) {
          MeloSnackbar.show(
            context: context,
            message: '已添加到播放队列末尾。',
          );
        }
        break;
      case _TrackMenuAction.playNext:
        if (unifiedTrack != null) {
          await repository.playUnifiedTrackNext(unifiedTrack!);
        } else {
          await repository.playTrackNext(primaryTrack);
        }
        if (context.mounted) {
          MeloSnackbar.show(
            context: context,
            message: '已设为下一首：${unifiedTrack?.title ?? primaryTrack.title}',
          );
        }
        break;
      case _TrackMenuAction.download:
        if (context.mounted) {
          await _downloadTrackFromMenu(context, repository, primaryTrack);
        }
        break;
      case _TrackMenuAction.addToPlaylist:
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (_) =>
                addToPlaylistDialog ?? MeloAddToPlaylistDialog(track: primaryTrack),
          );
        }
        break;
      case _TrackMenuAction.delete:
        if (onDelete != null) {
          onDelete!();
        } else if (playlistId != null) {
          repository.removeTrackFromPlaylist(
            playlistId: playlistId!,
            trackRef: primaryTrack.ref,
          );
          if (context.mounted) {
            MeloSnackbar.show(
              context: context,
              message: '已从歌单中删除：${unifiedTrack?.title ?? primaryTrack.title}',
            );
          }
        }
        break;
    }
  }
}

class _MeloBottomSheetItem extends StatelessWidget {
  const _MeloBottomSheetItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color ?? MeloColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteSourceDialog extends ConsumerWidget {
  const _FavoriteSourceDialog({
    required this.track,
    required this.variants,
  });

  final UnifiedFavoriteTrack track;
  final List<SourceTrack> variants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '管理收藏来源',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: MeloColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '同一首歌在多个来源中存在。每个来源的喜欢状态独立维护。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MeloColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 14),
              for (final variant in variants) ...[
                _FavoriteSourceItem(variant: variant),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteSourceItem extends ConsumerWidget {
  const _FavoriteSourceItem({required this.variant});

  final SourceTrack variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final liveVariant = repository.sourceTrackByRef(variant.ref) ?? variant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MeloColors.surfaceMuted,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: Row(
        children: [
          MeloSourceBadge(providerId: liveVariant.ref.providerId),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              liveVariant.isFavorited ? '已收藏到这个来源' : '尚未收藏到这个来源',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          MeloFavoriteButton(
            track: liveVariant,
            showSnackbar: false,
          ),
        ],
      ),
    );
  }
}

enum _TrackMenuAction {
  favoriteToggle,
  manageFavorites,
  appendToQueue,
  playNext,
  download,
  addToPlaylist,
  delete,
}

class MeloPlayNextButton extends StatelessWidget {
  const MeloPlayNextButton({
    required this.status,
    required this.onPressed,
    this.size = 20,
    this.showTooltip = true,
    super.key,
  });

  final PlayNextButtonStatus status;
  final VoidCallback? onPressed;
  final double size;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    if (status == PlayNextButtonStatus.hidden) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: showTooltip
          ? switch (status) {
              PlayNextButtonStatus.disabledCurrent => '当前正在播放',
              PlayNextButtonStatus.disabledAlreadyNext => '已经是下一首',
              PlayNextButtonStatus.disabledUnplayable => '当前歌曲不可播放',
              _ => '下一首播放',
            }
          : null,
      visualDensity: VisualDensity.compact,
      onPressed: status == PlayNextButtonStatus.enabled ? onPressed : null,
      icon: Icon(Icons.playlist_play_rounded, size: size),
    );
  }
}

class MeloTrackDownloadButton extends ConsumerWidget {
  const MeloTrackDownloadButton({
    required this.track,
    this.tooltip = '下载',
    this.lightweight = false,
    super.key,
  });

  final SourceTrack track;
  final String tooltip;
  final bool lightweight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    if (!repository.canDownloadTrack(track)) {
      return const SizedBox.shrink();
    }
    if (lightweight) {
      return _MeloLightweightIconButton(
        tooltip: tooltip,
        icon: Icons.download_rounded,
        onPressed: () => _downloadTrackFromMenu(context, repository, track),
      );
    }
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => _downloadTrackFromMenu(context, repository, track),
      icon: const Icon(Icons.download_rounded),
    );
  }
}

Future<void> _downloadTrackFromMenu(
  BuildContext context,
  DemoRepository repository,
  SourceTrack track,
) async {
  final quality = await _chooseDownloadQuality(context);
  if (quality == null || !context.mounted) return;
  MeloSnackbar.show(context: context, message: '开始下载：${track.title}');
  unawaited(
    repository.downloadTrack(track, quality: quality).then((status) {
      if (!context.mounted) return;
      final message = switch (status) {
        DownloadStatus.completed => '已下载到本地。',
        DownloadStatus.resolving ||
        DownloadStatus.downloading =>
          '正在下载：${track.title}',
        DownloadStatus.queued => '已开始下载。',
        DownloadStatus.paused => '下载已暂停。',
        DownloadStatus.failed => '下载失败，请在下载页重试。',
        DownloadStatus.cancelled => '下载已取消。',
        null => '当前来源暂不支持下载。',
      };
      MeloSnackbar.show(context: context, message: message);
    }),
  );
}

Future<AudioQuality?> _chooseDownloadQuality(BuildContext context) {
  return showDialog<AudioQuality>(
    context: context,
    animationStyle: const AnimationStyle(
      duration: Duration.zero,
      reverseDuration: Duration.zero,
    ),
    builder: (context) => SimpleDialog(
      title: const Text('选择下载音质'),
      children: [
        for (final quality in AudioQuality.values)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, quality),
            child: Row(
              children: [
                const Icon(Icons.high_quality_rounded, size: 18),
                const SizedBox(width: 10),
                Text(_audioQualityLabel(quality)),
              ],
            ),
          ),
      ],
    ),
  );
}

String _audioQualityLabel(AudioQuality quality) => switch (quality) {
      AudioQuality.low => '标准',
      AudioQuality.standard => '较高',
      AudioQuality.high => '极高',
      AudioQuality.lossless => '无损',
    };

class _MeloLightweightIconButton extends StatelessWidget {
  const _MeloLightweightIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = MeloColors.textTertiary,
    this.size = 21,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              icon,
              color: enabled ? color : MeloColors.textQuaternary,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

class MeloAddToPlaylistDialog extends ConsumerWidget {
  const MeloAddToPlaylistDialog({required this.track, super.key});

  final SourceTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final playlists = repository.playlistList;
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '加入本地歌单',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(child: Text('还没有本地歌单。')),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _MeloPlaylistChoice(
                      playlist: playlists[index],
                      onTap: () {
                        repository.addTrackToPlaylist(
                          playlistId: playlists[index].id,
                          track: track,
                        );
                        MeloSnackbar.show(
                          context: context,
                          message: '已加入“${playlists[index].name}”。',
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final name = await _askForPlaylistName(context);
                  if (name == null || name.trim().isEmpty) return;
                  repository.createPlaylist(name.trim());
                  final target = repository.selectedPlaylistId;
                  if (target != null) {
                    repository.addTrackToPlaylist(
                      playlistId: target,
                      track: track,
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('新建歌单并加入'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _askForPlaylistName(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => MeloDialogControllerWrapper(
        builder: (context, controller) => AlertDialog(
          title: const Text('新建本地歌单'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '歌单名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeloPlaylistChoice extends StatelessWidget {
  const _MeloPlaylistChoice({required this.playlist, required this.onTap});

  final LocalPlaylist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: MeloRadii.md,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: MeloColors.surfaceMuted,
          borderRadius: MeloRadii.md,
          border: Border.all(color: MeloColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: MeloColors.primary50,
                borderRadius: MeloRadii.sm,
              ),
              child: const Icon(
                Icons.playlist_play_rounded,
                color: MeloColors.primary700,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist.items.length} 首 · 本地歌单',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.add_rounded,
              color: MeloColors.primary700,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MeloTrackMenuItem extends StatelessWidget {
  const _MeloTrackMenuItem({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(overflow: TextOverflow.visible),
          ),
        ],
      );
}


/// Standardized favorite/unfavorite heart button.
///
/// - Optimistic local state: flips heart immediately on tap.
/// - Calls [DemoRepository.toggleFavorite] which auto-invalidates [allFavoritesProvider].
/// - Shows [MeloSnackbar] on success when [showSnackbar] is true;
///   shows error SnackBar on failure regardless.
/// - Reverts optimistic state on failure.
/// - Always uses [MeloColors.favorite] (red) for the liked state.
class MeloFavoriteButton extends ConsumerStatefulWidget {
  const MeloFavoriteButton({
    required this.track,
    this.showSnackbar = true,
    this.size = 21,
    this.lightweight = false,
    super.key,
  });

  final SourceTrack track;
  final bool showSnackbar;
  final double size;
  final bool lightweight;

  @override
  ConsumerState<MeloFavoriteButton> createState() => _MeloFavoriteButtonState();
}

class _MeloFavoriteButtonState extends ConsumerState<MeloFavoriteButton> {
  bool _optimisticLiked = false;
  ProviderTrackRef? _lastRef;

  @override
  void initState() {
    super.initState();
    _optimisticLiked = widget.track.isFavorited;
    _lastRef = widget.track.ref;
  }

  @override
  void didUpdateWidget(MeloFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.track.ref != oldWidget.track.ref) {
      _optimisticLiked = widget.track.isFavorited;
      _lastRef = widget.track.ref;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-sync on every build if a new track object is passed
    // (e.g. after allFavoritesProvider refresh).
    if (widget.track.ref != _lastRef) {
      _optimisticLiked = widget.track.isFavorited;
      _lastRef = widget.track.ref;
    }

    final liked = _optimisticLiked;
    final repository = ref.read(demoRepositoryProvider);
    final availability =
        repository.favoriteWriteAvailability(widget.track.ref.providerId);
    final tooltip = availability.reason ?? (liked ? '取消喜欢' : '喜欢');
    final icon = liked ? Icons.favorite_rounded : Icons.favorite_border_rounded;
    final color = liked ? MeloColors.favorite : MeloColors.textTertiary;
    final onPressed = availability.isEnabled
        ? () => _toggle(context, repository, liked)
        : null;

    if (widget.lightweight) {
      return _MeloLightweightIconButton(
        tooltip: tooltip,
        icon: icon,
        color: color,
        size: widget.size,
        onPressed: onPressed,
      );
    }

    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: color,
        size: widget.size,
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    DemoRepository repository,
    bool currentLiked,
  ) async {
    final newLiked = !currentLiked;

    // 1. Optimistic flip
    setState(() => _optimisticLiked = newLiked);

    try {
      // 2. Persist — repo handles allFavoritesProvider invalidation
      await repository.toggleFavorite(
        track: widget.track,
        liked: newLiked,
      );

      // 3. Success feedback
      if (widget.showSnackbar && mounted) {
        MeloSnackbar.show(
          context: this.context,
          message: newLiked ? '已收藏' : '已取消收藏',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (error) {
      // 4. Revert on failure — catches ProviderException, FormatException,
      //    SocketException, TimeoutException, etc.
      if (!mounted) return;
      setState(() => _optimisticLiked = !newLiked);
      if (widget.showSnackbar) {
        final message =
            error is ProviderException ? error.message : '操作失败，请重试。';
        MeloSnackbar.show(
          context: this.context,
          message: message,
        );
      }
    }
  }
}

class MeloPageGradientBackground extends StatelessWidget {
  const MeloPageGradientBackground({
    required this.providerId,
    required this.child,
    super.key,
  });

  final String providerId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = meloAccentColorForProvider(providerId);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.06), // Very subtle pale top
            color.withValues(alpha: 0.01),
            Colors.transparent, // Fade to transparent / canvas
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class MeloPlatformIcon extends StatelessWidget {
  const MeloPlatformIcon({required this.providerId, super.key});

  final ProviderId providerId;

  @override
  Widget build(BuildContext context) {
    final presentation = meloProviderPresentation(providerId);
    final value = providerId.value.toLowerCase();

    if (value == 'netease_cloud_music' ||
        value.contains('aurora') ||
        value.contains('netease')) {
      return Image.asset(
        'assets/images/netease_logo.png',
        width: 18,
        height: 18,
        fit: BoxFit.contain,
      );
    } else if (value == 'qq_music' ||
        value.contains('beacon') ||
        value.contains('qq')) {
      return Image.asset(
        'assets/images/qq_logo.png',
        width: 18,
        height: 18,
        fit: BoxFit.contain,
      );
    } else if (value == 'kugou' || value.contains('kugou')) {
      return Image.asset(
        'assets/images/kugou_logo.png',
        width: 18,
        height: 18,
        fit: BoxFit.contain,
      );
    }

    Color bgColor;
    IconData iconData;

    if (value.contains('local')) {
      bgColor = const Color(0xFF2563EB);
      iconData = Icons.folder_rounded;
    } else {
      bgColor = presentation.foregroundColor;
      iconData = presentation.icon;
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        iconData,
        size: 11,
        color: Colors.white,
      ),
    );
  }
}

/// Brand icon for Melo tabs — the MeloUnion logo mark.
class MeloBrandIcon extends StatelessWidget {
  const MeloBrandIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/melo_logo_inverse.png',
      width: 18,
      height: 18,
      fit: BoxFit.contain,
    );
  }
}

class MeloDialogControllerWrapper extends StatefulWidget {
  const MeloDialogControllerWrapper({
    super.key,
    this.initialText,
    required this.builder,
  });

  final String? initialText;
  final Widget Function(BuildContext context, TextEditingController controller)
      builder;

  @override
  State<MeloDialogControllerWrapper> createState() =>
      _MeloDialogControllerWrapperState();
}

class _MeloDialogControllerWrapperState
    extends State<MeloDialogControllerWrapper> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller);
  }
}
