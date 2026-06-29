import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/demo_repository.dart';
import '../design/melo_tokens.dart';
import '../widgets/right_sidebar.dart';

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
    final repository = ref.watch(demoRepositoryProvider);
    final destinations = AppDestination.values;
    final current = _currentDestination(location);
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    if (!isWide) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _titleFor(current),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: MeloColors.textPrimary,
                ),
          ),
          elevation: 0,
          backgroundColor: MeloColors.surface,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: MeloColors.border),
          ),
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: current.index,
          onDestinationSelected: (index) {
            context.go(destinations[index].path);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: '全部喜欢',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              label: '搜索',
            ),
            NavigationDestination(
              icon: Icon(Icons.queue_music_outlined),
              selectedIcon: Icon(Icons.queue_music),
              label: '本地歌单',
            ),
            NavigationDestination(
              icon: Icon(Icons.download_outlined),
              selectedIcon: Icon(Icons.download),
              label: '离线下载',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'Provider / 我的',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: MeloColors.canvas,
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: MeloDimensions.desktopSidebarWidth,
              decoration: const BoxDecoration(
                color: MeloColors.surface,
                border: Border(
                  right: BorderSide(color: MeloColors.border),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MeloUnion',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: MeloColors.primary700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Flutter MVP · Phase 1-5',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 28),
                  for (final destination in destinations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _NavButton(
                        label: _titleFor(destination),
                        selected: destination == current,
                        icon: _iconFor(destination, destination == current),
                        onTap: () => context.go(destination.path),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    '当前状态',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _SidebarStat(
                    label: '可聚合来源',
                    value: repository.capabilityMatrix
                        .eligibleFavoritesEntries(repository.registry)
                        .length
                        .toString(),
                  ),
                  _SidebarStat(
                    label: '本地歌单',
                    value: repository.playlistList.length.toString(),
                  ),
                  _SidebarStat(
                    label: '队列条目',
                    value: repository.queue.entries.length.toString(),
                  ),
                  _SidebarStat(
                    label: '下载任务',
                    value: repository.downloadCoordinator.allTasks.length
                        .toString(),
                  ),
                  _SidebarStat(
                    label: '本地音频',
                    value: repository.downloadCoordinator.localItems.length
                        .toString(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MeloColors.surfaceMuted,
                      borderRadius: MeloRadii.sm,
                      border: Border.all(color: MeloColors.border),
                    ),
                    child: Text(
                      '页面行为只读取 capability、登录态和启用状态；没有 QQ/网易云特判。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MeloColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: MeloColors.canvas,
                child: child,
              ),
            ),
            const SizedBox(
              width: MeloDimensions.desktopNowPlayingWidth,
              child: RightSidebar(),
            ),
          ],
        ),
      ),
    );
  }

  static AppDestination _currentDestination(String location) {
    for (final destination in AppDestination.values) {
      if (location.startsWith(destination.path)) {
        return destination;
      }
    }
    return AppDestination.favorites;
  }

  static String _titleFor(AppDestination destination) => switch (destination) {
        AppDestination.favorites => '全部喜欢',
        AppDestination.search => '搜索',
        AppDestination.playlists => '本地歌单',
        AppDestination.downloads => '离线下载',
        AppDestination.providers => 'Provider / 我的',
      };

  static Widget _iconFor(AppDestination destination, bool selected) {
    return switch (destination) {
      AppDestination.favorites => Icon(
          selected ? Icons.favorite : Icons.favorite_outline,
        ),
      AppDestination.search => const Icon(Icons.search),
      AppDestination.playlists => Icon(
          selected ? Icons.queue_music : Icons.queue_music_outlined,
        ),
      AppDestination.downloads => Icon(
          selected ? Icons.download : Icons.download_outlined,
        ),
      AppDestination.providers => Icon(
          selected ? Icons.account_circle : Icons.account_circle_outlined,
        ),
    };
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? MeloColors.primary700 : MeloColors.textPrimary;
    final background = selected ? MeloColors.primary50 : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: MeloRadii.sm,
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          borderRadius: MeloRadii.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconTheme(data: IconThemeData(color: foreground, size: 20), child: icon),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarStat extends StatelessWidget {
  const _SidebarStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MeloColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: MeloColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
