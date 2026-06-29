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

class _ProviderTabButton extends StatelessWidget {
  const _ProviderTabButton({
    required this.item,
    required this.selected,
    required this.onSelected,
  });

  final ProviderTabItem item;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? MeloColors.primary700
        : item.enabled
            ? MeloColors.textSecondary
            : MeloColors.textTertiary;
    return InkWell(
      onTap: item.enabled ? () => onSelected(item.id) : null,
      borderRadius: MeloRadii.sm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? MeloColors.primary50 : Colors.transparent,
          borderRadius: MeloRadii.sm,
          border: Border.all(
            color: selected ? MeloColors.primary100 : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
            if (item.trailing != null) ...[
              const SizedBox(width: 4),
              Icon(item.trailing, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
