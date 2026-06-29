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

    return Scaffold(
      backgroundColor: MeloColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _DesktopSidebar(current: current),
                  Expanded(child: ColoredBox(color: MeloColors.canvas, child: child)),
                  if (width >= 1180)
                    const SizedBox(
                      width: MeloDimensions.desktopNowPlayingWidth,
                      child: RightSidebar(),
                    ),
                ],
              ),
            ),
            const DesktopPlayerBar(),
          ],
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
        AppDestination.search => '推荐',
        AppDestination.downloads => '下载',
        AppDestination.providers => '设置',
      };

  static IconData iconFor(AppDestination destination, bool selected) => switch (destination) {
        AppDestination.favorites => selected ? Icons.favorite : Icons.favorite_outline,
        AppDestination.playlists => selected ? Icons.library_music : Icons.library_music_outlined,
        AppDestination.search => selected ? Icons.auto_awesome : Icons.auto_awesome_outlined,
        AppDestination.downloads => selected ? Icons.download : Icons.download_outlined,
        AppDestination.providers => selected ? Icons.settings : Icons.settings_outlined,
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
      AppDestination.search,
      AppDestination.downloads,
      AppDestination.providers,
    ];
    final selected = destinations.indexOf(current).clamp(0, destinations.length - 1);
    return Scaffold(
      appBar: AppBar(title: Text(AppShellScaffold.titleFor(current))),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
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
