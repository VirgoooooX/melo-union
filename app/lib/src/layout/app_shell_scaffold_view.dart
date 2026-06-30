part of 'app_shell_scaffold.dart';

class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = _destinationFor(location);
    final width = MediaQuery.sizeOf(context).width;
    if (width < 960) return _MobileShell(current: current, child: child);

    final widths = ref.watch(sidebarWidthsProvider);
    final leftWidth = widths.left;
    final rightWidth = widths.right;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: MeloColors.surface,
            borderRadius: MeloRadii.window,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: MeloRadii.window,
            border: Border.all(color: MeloColors.borderStrong),
          ),
          child: ClipRRect(
            borderRadius: MeloRadii.window,
            child: Column(
              children: [
                const MeloTitleBar(),
                Expanded(
                  child: Row(
                    children: [
                      _DesktopSidebar(current: current, width: leftWidth),
                      _ResizeGrip(
                        isLeft: true,
                        onDrag: (delta) {
                          ref
                              .read(sidebarWidthsProvider.notifier)
                              .updateLeft(leftWidth + delta);
                        },
                      ),
                      Expanded(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                MeloColors.canvasSoft,
                                MeloColors.canvas,
                              ],
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      if (width >= 1180) ...[
                        _ResizeGrip(
                          isLeft: false,
                          onDrag: (delta) {
                            ref
                                .read(sidebarWidthsProvider.notifier)
                                .updateRight(rightWidth - delta);
                          },
                        ),
                        Container(
                          width: rightWidth,
                          decoration: const BoxDecoration(
                            color: MeloColors.surface,
                            border: Border(
                              left: BorderSide(color: MeloColors.border),
                            ),
                          ),
                          child: const RightSidebar(),
                        ),
                      ],
                    ],
                  ),
                ),
                const DesktopPlayerBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static AppDestination _destinationFor(String location) {
    for (final item in AppDestination.values) {
      if (location.startsWith(item.path)) return item;
    }
    return AppDestination.favorites;
  }

  static String titleFor(AppDestination destination) => switch (destination) {
        AppDestination.favorites => '喜欢',
        AppDestination.playlists => '歌单',
        AppDestination.recommendations => '推荐',
        AppDestination.search => '搜索',
        AppDestination.downloads => '下载',
        AppDestination.settings => '设置',
      };

  static IconData iconFor(AppDestination destination, bool selected) =>
      switch (destination) {
        AppDestination.favorites =>
          selected ? Icons.favorite : Icons.favorite_outline,
        AppDestination.playlists =>
          selected ? Icons.library_music : Icons.library_music_outlined,
        AppDestination.recommendations =>
          selected ? Icons.auto_awesome : Icons.auto_awesome_outlined,
        AppDestination.search => Icons.search_rounded,
        AppDestination.downloads =>
          selected ? Icons.download : Icons.download_outlined,
        AppDestination.settings =>
          selected ? Icons.settings : Icons.settings_outlined,
      };
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.current, required this.child});

  final AppDestination current;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      AppDestination.favorites,
      AppDestination.playlists,
      AppDestination.recommendations,
      AppDestination.search,
      AppDestination.settings,
    ];
    final selected = destinations.indexOf(current);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppShellScaffold.titleFor(current)),
        actions: [
          if (current != AppDestination.search)
            IconButton(
              tooltip: '搜索',
              onPressed: () => context.go(AppDestination.search.path),
              icon: const Icon(Icons.search_rounded),
            ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (index) => context.go(destinations[index].path),
        destinations: [
          for (final item in destinations)
            NavigationDestination(
              icon: Icon(AppShellScaffold.iconFor(item, false)),
              selectedIcon: Icon(AppShellScaffold.iconFor(item, true)),
              label: AppShellScaffold.titleFor(item),
            ),
        ],
      ),
    );
  }
}

class _ResizeGrip extends StatefulWidget {
  const _ResizeGrip({required this.isLeft, required this.onDrag});

  final bool isLeft;
  final ValueChanged<double> onDrag;

  @override
  State<_ResizeGrip> createState() => _ResizeGripState();
}

class _ResizeGripState extends State<_ResizeGrip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) {
          widget.onDrag(details.delta.dx);
        },
        child: Container(
          width: 8,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _hovered ? 2 : 1,
              color: _hovered ? MeloColors.primary500 : MeloColors.border,
            ),
          ),
        ),
      ),
    );
  }
}
