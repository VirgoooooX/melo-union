import 'package:flutter/material.dart';
import 'package:provider_contract/provider_contract.dart';

import '../design/melo_tokens.dart';

abstract final class MeloListMetrics {
  static const rowHeight = 64.0;
  static const compactRowHeight = 48.0;
  static const trackCoverSize = 42.0;
  static const sourceColumnWidth = 132.0;
  static const actionColumnWidth = 84.0;
  static const rowHorizontalPadding = 16.0;
}

class MeloInteractiveRow extends StatefulWidget {
  const MeloInteractiveRow({
    required this.builder,
    this.onTap,
    this.selected = false,
    this.height = MeloListMetrics.rowHeight,
    this.padding = const EdgeInsets.symmetric(
      horizontal: MeloListMetrics.rowHorizontalPadding,
    ),
    super.key,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;
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
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
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
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://music.163.com',
            },
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
    final isNetease = providerId.value.contains('aurora') ||
        providerId.value.contains('netease');
    final foreground =
        isNetease ? MeloColors.neteaseForeground : MeloColors.qqForeground;
    final background =
        isNetease ? MeloColors.neteaseBackground : MeloColors.qqBackground;
    final text = label ?? meloProviderLabel(providerId);
    return Container(
      constraints: const BoxConstraints(minWidth: 44, maxWidth: 62),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: foreground.withValues(alpha: .28)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
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
      return ClipRRect(
        borderRadius: MeloRadii.md,
        child: Image.network(
          cover!.toString(),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://music.163.com',
          },
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
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
  if (id.value.contains('aurora') || id.value.contains('netease')) {
    return '网易云';
  }
  if (id.value.contains('beacon')) return 'QQ音乐';
  return id.value;
}
