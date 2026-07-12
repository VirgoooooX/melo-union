part of 'app_shell_scaffold.dart';

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.current,
    required this.width,
  });

  final AppDestination current;
  final double width;

  List<AppDestination> get _main => [
        AppDestination.favorites,
        AppDestination.playlists,
        if (defaultTargetPlatform == TargetPlatform.windows)
          AppDestination.local,
        AppDestination.recommendations,
        AppDestination.search,
      ];
  static const _utility = [
    AppDestination.downloads,
    AppDestination.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: meloShellChromeColor(0.38),
        border: Border(
          right: BorderSide(
            color: MeloColors.border.withValues(alpha: 0.70),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SidebarBrand(),
          const SizedBox(height: 28),
          for (final item in _main) ...[
            _SidebarItem(destination: item, selected: item == current),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 34),
          Container(height: 1, color: MeloColors.border),
          const SizedBox(height: 26),
          for (final item in _utility) ...[
            _SidebarItem(destination: item, selected: item == current),
            const SizedBox(height: 16),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: MeloLogoMark(size: 76),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({required this.destination, required this.selected});

  final AppDestination destination;
  final bool selected;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final foreground =
        selected ? MeloColors.primary700 : MeloColors.textPrimary;
    final background = selected
        ? MeloColors.surfaceSelected
        : _hovered
            ? MeloColors.surfaceHover
            : Colors.transparent;

    return Semantics(
      button: true,
      selected: selected,
      label: AppShellScaffold.titleFor(widget.destination),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.destination.path),
          child: AnimatedContainer(
            duration: Duration.zero,
            curve: Curves.easeOutCubic,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: MeloRadii.sm,
              border: Border.all(
                color: selected ? MeloColors.primary100 : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                if (widget.destination == AppDestination.local)
                  MeloLocalMark(size: 23, color: foreground)
                else
                  Icon(
                    AppShellScaffold.iconFor(widget.destination, selected),
                    color: foreground,
                    size: 23,
                  ),
                const SizedBox(width: 16),
                Text(
                  AppShellScaffold.titleFor(widget.destination),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
