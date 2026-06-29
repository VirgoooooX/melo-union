part of 'provider_tabs.dart';

class ProviderTabs extends StatelessWidget {
  const ProviderTabs({
    required this.items,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<ProviderTabItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MeloDimensions.desktopProviderTabsHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: MeloSpacing.xs),
        itemBuilder: (context, index) => _ProviderTabButton(
          item: items[index],
          selected: items[index].id == selectedId,
          onSelected: onSelected,
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
        : item.enabled
            ? MeloColors.textSecondary
            : MeloColors.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: MouseRegion(
        cursor: item.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: item.enabled ? () => widget.onSelected(item.id) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: selected
                  ? MeloColors.surfaceSelected
                  : _hovered && item.enabled
                      ? MeloColors.surfaceHover
                      : Colors.transparent,
              borderRadius: MeloRadii.md,
              border: Border.all(
                color: selected ? MeloColors.primary100 : Colors.transparent,
              ),
              boxShadow: selected ? MeloShadows.control : const [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.radio_button_checked_rounded,
                    size: 12,
                    color: MeloColors.primary600,
                  ),
                  const SizedBox(width: 7),
                ],
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
