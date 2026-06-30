part of 'app_shell_scaffold.dart';

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.current});

  final AppDestination current;

  static const _main = [
    AppDestination.favorites,
    AppDestination.playlists,
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
      width: MeloDimensions.desktopSidebarWidth,
      decoration: const BoxDecoration(
        color: MeloColors.canvasSoft,
        border: Border(right: BorderSide(color: MeloColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandLockup(),
          const SizedBox(height: 34),
          for (final item in _main) ...[
            _SidebarItem(destination: item, selected: item == current),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          Container(height: 1, color: MeloColors.border),
          const SizedBox(height: 14),
          for (final item in _utility) ...[
            _SidebarItem(destination: item, selected: item == current),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: MeloColors.primary700,
            borderRadius: MeloRadii.sm,
            boxShadow: MeloShadows.control,
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'MeloUnion',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: MeloColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.45,
                ),
          ),
        ),
      ],
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
            height: 42,
            padding: const EdgeInsets.only(left: 0, right: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: MeloRadii.sm,
              border: Border.all(
                color: Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 3,
                  height: selected ? 22 : 0,
                  decoration: const BoxDecoration(
                    color: MeloColors.primary600,
                    borderRadius: MeloRadii.pill,
                  ),
                ),
                const SizedBox(width: 9),
                AnimatedContainer(
                  duration: Duration.zero,
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected
                        ? MeloColors.surface
                        : _hovered
                            ? MeloColors.primary50
                            : Colors.transparent,
                    borderRadius: MeloRadii.sm,
                  ),
                  child: Icon(
                    AppShellScaffold.iconFor(widget.destination, selected),
                    color: foreground,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppShellScaffold.titleFor(widget.destination),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
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
