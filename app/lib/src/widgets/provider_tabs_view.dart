part of 'provider_tabs.dart';

class ProviderTabs extends StatelessWidget {
  const ProviderTabs({
    required this.items,
    required this.selectedId,
    required this.onSelected,
    this.onMorePressed,
    super.key,
  });

  final List<ProviderTabItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MeloDimensions.desktopProviderTabsHeight,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MeloColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: MeloSpacing.xs),
        itemBuilder: (context, index) => _ProviderTabButton(
          item: items[index],
          selected: items[index].id == selectedId,
          onSelected: (id) {
            if (id == 'more' && onMorePressed != null) {
              onMorePressed!();
            } else {
              onSelected(id);
            }
          },
        ),
      ),
    );
  }
}

class ProviderTabSwipeRegion extends StatefulWidget {
  const ProviderTabSwipeRegion({
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.child,
    super.key,
  });

  final List<ProviderTabItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final Widget child;

  @override
  State<ProviderTabSwipeRegion> createState() => _ProviderTabSwipeRegionState();
}

class _ProviderTabSwipeRegionState extends State<ProviderTabSwipeRegion> {
  double _dragDistance = 0;
  int _slideDirection = 1;

  @override
  void didUpdateWidget(covariant ProviderTabSwipeRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId == widget.selectedId) return;

    final previousIndex = _tabIndex(oldWidget.items, oldWidget.selectedId);
    final nextIndex = _tabIndex(widget.items, widget.selectedId);
    if (previousIndex >= 0 && nextIndex >= 0) {
      _slideDirection = nextIndex > previousIndex ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 960) return widget.child;

    final swipableIds = [
      for (final item in widget.items)
        if (item.enabled && item.id != 'more') item.id,
    ];
    if (swipableIds.length < 2) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dragDistance = 0,
      onHorizontalDragUpdate: (details) {
        _dragDistance += details.primaryDelta ?? 0;
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final useVelocity = velocity.abs() >= 320;
        final useDistance = _dragDistance.abs() >= 64;
        if (!useVelocity && !useDistance) return;

        final currentIndex = swipableIds.indexOf(widget.selectedId);
        if (currentIndex < 0) return;

        final direction = useVelocity ? velocity : _dragDistance;
        final nextIndex = direction < 0 ? currentIndex + 1 : currentIndex - 1;
        if (nextIndex < 0 || nextIndex >= swipableIds.length) return;
        widget.onSelected(swipableIds[nextIndex]);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        reverseDuration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final isIncoming = child.key == ValueKey(widget.selectedId);
          final direction = isIncoming ? _slideDirection : -_slideDirection;
          final offset = Tween<Offset>(
            begin: Offset(direction * .12, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(widget.selectedId),
          child: widget.child,
        ),
      ),
    );
  }

  static int _tabIndex(List<ProviderTabItem> items, String id) {
    return [
      for (final item in items)
        if (item.enabled && item.id != 'more') item.id,
    ].indexOf(id);
  }
}

class _ProviderTabButton extends StatefulWidget {
  const _ProviderTabButton({
    required this.item,
    required this.selected,
    required this.onSelected,
  });

  final ProviderTabItem item;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  State<_ProviderTabButton> createState() => _ProviderTabButtonState();
}

class _ProviderTabButtonState extends State<_ProviderTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final item = widget.item;
    final color = selected
        ? MeloColors.primary700
        : _hovered && item.enabled
            ? MeloColors.textPrimary
            : item.enabled
                ? MeloColors.textSecondary
                : MeloColors.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: MouseRegion(
        cursor: item.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: item.enabled ? () => widget.onSelected(item.id) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? MeloColors.primary700 : Colors.transparent,
                  width: 3.0,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.leading != null) ...[
                  item.leading!,
                  const SizedBox(width: 8),
                ],
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
                if (item.trailing != null) ...[
                  const SizedBox(width: 4),
                  Icon(item.trailing, color: color, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
