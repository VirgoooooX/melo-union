import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_contract/provider_contract.dart';

import '../bootstrap/demo_repository.dart';
import '../design/melo_tokens.dart';
import '../presentation/provider_presentation.dart';

abstract final class MeloListMetrics {
  static const rowHeight = 64.0;
  static const compactRowHeight = 48.0;
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

  @override
  Widget build(BuildContext context) {
    final background = widget.selected
        ? MeloColors.primary50
        : _hovered
            ? MeloColors.surfaceHover
            : Colors.transparent;
    final leftAccent =
        widget.selected ? MeloColors.primary500 : Colors.transparent;

    return MouseRegion(
      cursor: widget.onTap == null && widget.onDoubleTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedContainer(
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
        ),
      ),
    );
  }
}

class MeloTrackCover extends StatelessWidget {
  const MeloTrackCover({
    required this.seed,
    this.artwork,
    this.isActive = false,
    this.size = MeloListMetrics.trackCoverSize,
    super.key,
  });

  final String seed;
  final Uri? artwork;
  final bool isActive;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (artwork != null && artwork!.toString().isNotEmpty) {
      final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: MeloRadii.sm,
          boxShadow: isActive ? MeloShadows.control : const [],
        ),
        child: ClipRRect(
          borderRadius: MeloRadii.sm,
          child: Image.network(
            artwork!.toString(),
            width: size,
            height: size,
            fit: BoxFit.cover,
            headers: meloArtworkHeaders,
            cacheWidth: cacheSize,
            cacheHeight: cacheSize,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hue =
        seed.codeUnits.fold<int>(0, (total, value) => total + value) % 360;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: MeloRadii.sm,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .54, .62).toColor(),
            HSLColor.fromAHSL(1, (hue + 48) % 360, .54, .40).toColor(),
          ],
        ),
        boxShadow: isActive ? MeloShadows.control : const [],
      ),
      child: Icon(
        isActive ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
        color: Colors.white,
        size: isActive ? size * .42 : size * .48,
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
    super.key,
  });

  final ProviderId providerId;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final presentation = meloProviderPresentation(providerId);
    final text = label ?? presentation.shortName;
    return Container(
      constraints: const BoxConstraints(minWidth: 44, maxWidth: 62),
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
            color: _hovered ? const Color(0xFFFAFCFD) : MeloColors.surface,
            borderRadius: MeloRadii.md,
            border: Border.all(
              color: _hovered ? MeloColors.borderStrong : Colors.transparent,
            ),
          ),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
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
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MeloColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
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
        ),
      ),
    );
    if (widget.width == null) return content;
    return SizedBox(width: widget.width, child: content);
  }
}

class MeloPlaylistCover extends StatelessWidget {
  const MeloPlaylistCover({
    required this.title,
    this.cover,
    super.key,
  });

  final String title;
  final Uri? cover;

  @override
  Widget build(BuildContext context) {
    if (cover != null && cover!.toString().isNotEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final pixelRatio = MediaQuery.devicePixelRatioOf(context);
          final cacheWidth = constraints.maxWidth.isFinite
              ? (constraints.maxWidth * pixelRatio).round()
              : null;
          final cacheHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight * pixelRatio).round()
              : cacheWidth;
          return ClipRRect(
            borderRadius: MeloRadii.md,
            child: Image.network(
              cover!.toString(),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              headers: meloArtworkHeaders,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
          );
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hue = title.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
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
/// Pass [addToPlaylistDialog] to enable the "add to playlist" action; when
/// omitted the menu item shows a placeholder SnackBar.
class MeloTrackMoreMenu extends ConsumerWidget {
  const MeloTrackMoreMenu({
    required this.track,
    this.addToPlaylistDialog,
    super.key,
  });

  final SourceTrack track;
  final Widget? addToPlaylistDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    return PopupMenuButton<_TrackMenuAction>(
      tooltip: '更多操作',
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      offset: const Offset(0, 42),
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 80),
        reverseDuration: Duration(milliseconds: 60),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      onSelected: (action) async {
        if (action == _TrackMenuAction.playNext) {
          repository.enqueueTrack(track);
          MeloSnackbar.show(
            context: context,
            message: '已添加到播放队列末尾。',
          );
          return;
        }
        if (action == _TrackMenuAction.addToPlaylist) {
          if (addToPlaylistDialog != null) {
            await showDialog<void>(
              context: context,
              builder: (_) => addToPlaylistDialog!,
            );
          } else {
            MeloSnackbar.show(
              context: context,
              message: '加入本地歌单操作将在下个交互迭代接入。',
            );
          }
          return;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _TrackMenuAction.playNext,
          child: _MeloTrackMenuItem(
            icon: Icons.queue_music_rounded,
            label: '加入播放队列',
          ),
        ),
        PopupMenuItem(
          value: _TrackMenuAction.addToPlaylist,
          child: const _MeloTrackMenuItem(
            icon: Icons.playlist_add_rounded,
            label: '加入本地歌单',
          ),
        ),
      ],
    );
  }
}

enum _TrackMenuAction { playNext, addToPlaylist }

class _MeloTrackMenuItem extends StatelessWidget {
  const _MeloTrackMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(label),
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
    super.key,
  });

  final SourceTrack track;
  final bool showSnackbar;
  final double size;

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

    return IconButton(
      tooltip: availability.reason ?? (liked ? '取消喜欢' : '喜欢'),
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
      onPressed: availability.isEnabled
          ? () => _toggle(context, repository, liked)
          : null,
      icon: Icon(
        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: liked ? MeloColors.favorite : MeloColors.textTertiary,
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
