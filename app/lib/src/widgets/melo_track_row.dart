import 'package:flutter/material.dart';

import '../design/melo_tokens.dart';
import 'melo_components.dart';

class MeloMobileTrackRow extends StatelessWidget {
  const MeloMobileTrackRow({
    required this.index,
    required this.title,
    required this.artists,
    required this.artwork,
    required this.duration,
    this.isActive = false,
    this.onTap,
    this.trailing,
    super.key,
  });

  final int index;
  final String title;
  final List<String> artists;
  final Uri? artwork;
  final Duration duration;
  final bool isActive;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isActive ? MeloColors.mobileAccentSurface : MeloColors.mobileSurface;

    return MeloTapFeedback(
      onTap: onTap,
      selected: isActive,
      borderRadius: MeloRadii.md,
      animatePress: false,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: MeloRadii.md,
          border: Border.all(
            color: MeloColors.mobileSurfaceBorder,
          ),
          boxShadow: MeloShadows.card,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 28,
              child: Center(
                child: isActive
                    ? const Icon(
                        Icons.graphic_eq_rounded,
                        color: MeloColors.primary700,
                        size: 16,
                      )
                    : Text(
                        '$index',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MeloColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
              ),
            ),
            const SizedBox(width: MeloSpacing.xs),
            MeloTrackCover(
              seed: title,
              artwork: artwork,
              isActive: isActive,
              size: 48,
              borderRadius: MeloRadii.sm,
            ),
            const SizedBox(width: MeloSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isActive
                              ? MeloColors.primary700
                              : MeloColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artists.join(' / '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: MeloSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class MeloMobileTrackTrailing extends StatelessWidget {
  const MeloMobileTrackTrailing({
    this.providerIcon,
    this.durationLabel,
    this.duration,
    this.durationColor = MeloColors.textSecondary,
    this.durationFontWeight = FontWeight.w600,
    this.actions = const [],
    this.reserveProviderSlot = false,
    super.key,
  }) : assert(durationLabel != null || duration != null);

  static const providerSlotWidth = 24.0;
  static const durationSlotWidth = 42.0;
  static const actionSlotWidth = 40.0;
  static const slotHeight = 40.0;

  final Widget? providerIcon;
  final String? durationLabel;
  final Widget? duration;
  final Color durationColor;
  final FontWeight durationFontWeight;
  final List<Widget> actions;
  final bool reserveProviderSlot;

  @override
  Widget build(BuildContext context) {
    final durationChild = duration ??
        Text(
          durationLabel!,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: durationColor,
                fontSize: 11,
                fontWeight: durationFontWeight,
              ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (providerIcon != null || reserveProviderSlot)
          SizedBox(
            width: providerSlotWidth,
            height: slotHeight,
            child: Center(child: providerIcon),
          ),
        SizedBox(
          width: durationSlotWidth,
          height: slotHeight,
          child: Align(
            alignment: Alignment.centerRight,
            child: durationChild,
          ),
        ),
        for (final action in actions)
          SizedBox(
            width: actionSlotWidth,
            height: slotHeight,
            child: Center(child: action),
          ),
      ],
    );
  }
}

class MeloDesktopTrackRow extends StatelessWidget {
  const MeloDesktopTrackRow({
    required this.index,
    required this.title,
    required this.artists,
    required this.artwork,
    this.album,
    this.subtitle,
    this.isActive = false,
    this.onDoubleTap,
    this.trailing,
    super.key,
  });

  final int index;
  final String title;
  final List<String> artists;
  final Uri? artwork;
  final String? album;
  final String? subtitle;
  final bool isActive;
  final VoidCallback? onDoubleTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MeloColors.border),
        ),
      ),
      child: MeloInteractiveRow(
        selected: isActive,
        onTap: null,
        onDoubleTap: onDoubleTap,
        builder: (context, hovered) => Row(
          children: [
            SizedBox(
              width: 32,
              child: isActive
                  ? const Icon(
                      Icons.graphic_eq_rounded,
                      color: MeloColors.primary700,
                      size: 18,
                    )
                  : Text(
                      index.toString().padLeft(2, '0'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: hovered
                                ? MeloColors.primary700
                                : MeloColors.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
            const SizedBox(width: MeloSpacing.md),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  MeloTrackCover(
                    seed: title,
                    artwork: artwork,
                    isActive: isActive,
                  ),
                  const SizedBox(width: MeloSpacing.sm),
                  Expanded(
                    child: _TrackTitleBlock(
                      title: title,
                      artists: artists,
                      active: isActive,
                    ),
                  ),
                ],
              ),
            ),
            if (subtitle != null)
              Expanded(
                flex: 3,
                child: Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MeloColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              )
            else if (album != null)
              Expanded(
                flex: 3,
                child: Text(
                  album!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MeloColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            if (trailing != null)
              trailing!,
          ],
        ),
      ),
    );
  }
}

class _TrackTitleBlock extends StatelessWidget {
  const _TrackTitleBlock({
    required this.title,
    required this.artists,
    required this.active,
  });

  final String title;
  final List<String> artists;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: active ? MeloColors.primary700 : MeloColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          artists.join(' / '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MeloColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
