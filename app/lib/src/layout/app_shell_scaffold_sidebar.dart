part of 'app_shell_scaffold.dart';

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.current});

  final AppDestination current;

  static const _main = [
    AppDestination.favorites,
    AppDestination.playlists,
    AppDestination.recommendations,
  ];
  static const _utility = [
    AppDestination.downloads,
    AppDestination.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MeloDimensions.desktopSidebarWidth,
      decoration: const BoxDecoration(
        color: MeloColors.surface,
        border: Border(right: BorderSide(color: MeloColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MeloUnion',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: MeloColors.primary700,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                ),
              ),
              IconButton(
                tooltip: '搜索 · Ctrl+K',
                onPressed: () => context.go(AppDestination.search.path),
                icon: Icon(
                  Icons.search_rounded,
                  color: current == AppDestination.search
                      ? MeloColors.primary700
                      : MeloColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          for (final item in _main) ...[
            _SidebarItem(destination: item, selected: item == current),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          const Divider(color: MeloColors.border),
          const SizedBox(height: 12),
          for (final item in _utility) ...[
            _SidebarItem(destination: item, selected: item == current),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.destination, required this.selected});

  final AppDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? MeloColors.primary700 : MeloColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(destination.path),
        borderRadius: MeloRadii.sm,
        child: Ink(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? MeloColors.primary50 : Colors.transparent,
            borderRadius: MeloRadii.sm,
          ),
          child: Row(
            children: [
              Icon(
                AppShellScaffold.iconFor(destination, selected),
                color: foreground,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                AppShellScaffold.titleFor(destination),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
