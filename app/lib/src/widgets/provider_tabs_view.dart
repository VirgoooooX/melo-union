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
