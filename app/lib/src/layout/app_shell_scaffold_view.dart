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
    final accentProviderId = _accentProviderIdFor(
      current,
      ref.watch(meloShellAccentProviderIdProvider),
    );
    final width = MediaQuery.sizeOf(context).width;
    if (width < 960) {
      return _MobileShell(
        current: current,
        accentProviderId: accentProviderId,
        child: child,
      );
    }

    final widths = ref.watch(sidebarWidthsProvider);
    final leftWidth = widths.left;
    final rightWidth = widths.right;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DragToResizeArea(
        resizeEdgeSize: 6,
        child: Container(
          decoration: meloShellGradientDecoration(
            accentProviderId,
            borderRadius: MeloRadii.window,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: MeloRadii.window,
            border: Border.all(color: MeloColors.borderStrong),
          ),
          child: ClipRRect(
            borderRadius: MeloRadii.window,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  MeloTitleBar(providerId: accentProviderId),
                  Expanded(
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            _DesktopSidebar(
                              current: current,
                              width: leftWidth,
                            ),
                            Expanded(
                              child: child,
                            ),
                            if (width >= 1180)
                              Container(
                                width: rightWidth,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: MeloColors.border.withValues(
                                        alpha: 0.70,
                                      ),
                                    ),
                                  ),
                                ),
                                child: const RightSidebar(),
                              ),
                          ],
                        ),
                        Positioned(
                          left: leftWidth - 4,
                          top: 0,
                          bottom: 0,
                          width: 8,
                          child: _ResizeGrip(
                            isLeft: true,
                            onDrag: (delta) {
                              ref
                                  .read(sidebarWidthsProvider.notifier)
                                  .updateLeft(leftWidth + delta);
                            },
                          ),
                        ),
                        if (width >= 1180)
                          Positioned(
                            right: rightWidth - 4,
                            top: 0,
                            bottom: 0,
                            width: 8,
                            child: _ResizeGrip(
                              isLeft: false,
                              onDrag: (delta) {
                                ref
                                    .read(sidebarWidthsProvider.notifier)
                                    .updateRight(rightWidth - delta);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const DesktopPlayerBar(),
                ],
              ),
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

  static String _accentProviderIdFor(
    AppDestination destination,
    String providerId,
  ) {
    if (destination == AppDestination.downloads ||
        destination == AppDestination.settings) {
      return 'all';
    }
    return providerId;
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
  const _MobileShell({
    required this.current,
    required this.accentProviderId,
    required this.child,
  });

  final AppDestination current;
  final String accentProviderId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      AppDestination.recommendations,
      AppDestination.favorites,
      AppDestination.search,
      AppDestination.playlists,
      AppDestination.settings,
    ];
    final mobileCurrent =
        current == AppDestination.downloads ? AppDestination.settings : current;
    final selected = destinations.indexOf(mobileCurrent);
    final showMiniPlayer = current != AppDestination.settings &&
        current != AppDestination.downloads;
    final isImmersivePage = current == AppDestination.favorites ||
        current == AppDestination.recommendations ||
        current == AppDestination.playlists;

    final childWidget =
        isImmersivePage ? child : SafeArea(bottom: false, child: child);

    return Scaffold(
      extendBody: true,
      backgroundColor: MeloColors.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: meloShellGradientDecoration(accentProviderId),
              child: childWidget,
            ),
          ),
          if (showMiniPlayer)
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 76,
              child: const MeloMobileMiniPlayer(),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        backgroundColor: meloShellChromeColor(0.76),
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (index) => context.go(destinations[index].path),
        destinations: [
          for (final item in destinations)
            NavigationDestination(
              icon: Icon(_mobileIconFor(item, false)),
              selectedIcon: Icon(_mobileIconFor(item, true)),
              label: _mobileLabelFor(item),
            ),
        ],
      ),
    );
  }

  static String _mobileLabelFor(AppDestination destination) =>
      switch (destination) {
        AppDestination.recommendations => '推荐',
        AppDestination.favorites => '喜欢',
        AppDestination.search => '搜索',
        AppDestination.playlists => '歌单',
        AppDestination.settings => '我的',
        AppDestination.downloads => '下载',
      };

  static IconData _mobileIconFor(AppDestination destination, bool selected) =>
      switch (destination) {
        AppDestination.recommendations =>
          selected ? Icons.home_rounded : Icons.home_outlined,
        AppDestination.favorites =>
          selected ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
        AppDestination.search => Icons.search_rounded,
        AppDestination.playlists =>
          selected ? Icons.library_music_rounded : Icons.library_music_outlined,
        AppDestination.settings =>
          selected ? Icons.person_rounded : Icons.person_outline_rounded,
        AppDestination.downloads =>
          selected ? Icons.download_rounded : Icons.download_outlined,
      };
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
              width: 2,
              color: _hovered ? MeloColors.primary500 : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
