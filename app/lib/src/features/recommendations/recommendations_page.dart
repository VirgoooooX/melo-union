import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../presentation/provider_presentation.dart';
import '../../presentation/shell_accent.dart';
import '../../widgets/melo_components.dart';
import '../../widgets/melo_track_row.dart';
import '../../widgets/provider_tabs.dart';

enum _ShelfTab { playlists, charts }

final _selectedProviderIdProvider = StateProvider<String>((ref) => '');
final _selectedShelfTabProvider = StateProvider<_ShelfTab?>((ref) => null);

final recommendationsFutureProvider =
    FutureProvider.family<List<SourceTrack>, ProviderId>((ref, providerId) {
  final repo = ref.watch(demoRepositoryProvider);
  final cached = repo.cachedRecommendations(providerId);
  if (cached != null && repo.hasFreshRecommendations) {
    return cached;
  }
  return repo.loadRecommendations(providerId);
});

final recommendedPlaylistsFutureProvider =
    FutureProvider.family<List<ProviderPlaylist>, ProviderId>(
        (ref, providerId) {
  final repo = ref.watch(demoRepositoryProvider);
  final cached = repo.cachedRecommendedPlaylists(providerId);
  if (cached != null && repo.hasFreshRecommendedPlaylists(providerId)) {
    return cached;
  }
  return repo.loadRecommendedPlaylists(providerId);
});

final chartPlaylistsFutureProvider =
    FutureProvider.family<List<ProviderPlaylist>, ProviderId>(
        (ref, providerId) {
  final repo = ref.watch(demoRepositoryProvider);
  final cached = repo.cachedChartPlaylists(providerId);
  if (cached != null && repo.hasFreshChartPlaylists(providerId)) {
    return cached;
  }
  return repo.loadChartPlaylists(providerId);
});

class RecommendationsPage extends ConsumerWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;
    final providerEntries = ref.watch(
      demoRepositoryProvider.select((r) => r.providerEntries),
    );
    final enabledProviders = providerEntries.where((entry) {
      if (!entry.isEnabled) return false;
      final canReadRecommendations = entry.provider.isAuthenticated &&
          entry.descriptor
              .supports(ProviderCapability.readDailyRecommendations);
      final canReadCharts =
          entry.descriptor.supports(ProviderCapability.readCharts);
      return canReadRecommendations || canReadCharts;
    }).toList(growable: false);

    final selectedState = ref.watch(_selectedProviderIdProvider);
    final selected = selectedState.isNotEmpty &&
            enabledProviders
                .any((item) => item.descriptor.id.value == selectedState)
        ? selectedState
        : (enabledProviders.isEmpty
            ? 'more'
            : enabledProviders.first.descriptor.id.value);

    final selectedProviderId = ProviderId(selected);

    return MeloShellAccentScope(
      providerId: selected,
      child: isMobile
          ? _MobileRecommendationsView(
              selected: selected,
              selectedProviderId: selectedProviderId,
              enabledProviders: enabledProviders,
            )
          : _DesktopRecommendationsView(
              selected: selected,
              selectedProviderId: selectedProviderId,
              enabledProviders: enabledProviders,
            ),
    );
  }
}

class _RecommendationsTabBar extends ConsumerWidget {
  const _RecommendationsTabBar({
    required this.selected,
    required this.enabledProviders,
  });

  final String selected;
  final List<ProviderRegistryEntry> enabledProviders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = <ProviderTabItem>[
      for (final entry in enabledProviders)
        ProviderTabItem(
          id: entry.descriptor.id.value,
          label: meloProviderPresentation(
            entry.descriptor.id,
            displayName: entry.descriptor.displayName,
          ).shortName,
          leading: MeloPlatformIcon(providerId: entry.descriptor.id),
        ),
    ];
    return ProviderTabs(
      items: tabs,
      selectedId: selected,
      onSelected: (id) {
        ref.read(_selectedProviderIdProvider.notifier).state = id;
      },
    );
  }
}

class _RecommendationsTracksGrid extends ConsumerWidget {
  const _RecommendationsTracksGrid({
    required this.selectedProviderId,
    required this.canShowPlaylists,
  });

  final ProviderId selectedProviderId;
  final bool canShowPlaylists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedProviderId.value == 'more') {
      return const Center(child: Text('当前来源暂未提供推荐内容。'));
    }
    if (!canShowPlaylists) {
      return const Center(child: Text('当前来源暂未提供每日推荐。'));
    }

    final currentRef = ref.watch(
      demoRepositoryProvider.select((r) => r.queue.current?.track.ref),
    );
    final recommendationsAsync =
        ref.watch(recommendationsFutureProvider(selectedProviderId));

    return recommendationsAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Center(child: Text('当前来源暂未提供推荐内容。'));
        }
        return Container(
          decoration: BoxDecoration(
            color: MeloColors.surface,
            borderRadius: MeloRadii.lg,
            border: Border.all(color: MeloColors.border),
            boxShadow: MeloShadows.card,
          ),
          child: ListView.separated(
            key: PageStorageKey<String>(
              'recommendation_tracks_${selectedProviderId.value}',
            ),
            itemCount: tracks.length,
            scrollCacheExtent: const ScrollCacheExtent.pixels(560),
            addAutomaticKeepAlives: false,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: MeloColors.border,
            ),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final selected = currentRef == track.ref;
              return MeloDesktopTrackRow(
                index: index + 1,
                title: track.title,
                artists: track.artists,
                artwork: track.artwork,
                album: track.album ?? '今日推荐',
                isActive: selected,
                onDoubleTap: track.isPlayable
                    ? () => ref
                        .read(demoRepositoryProvider)
                        .playOrToggleTrack(track)
                    : null,
                trailing: MeloTrackMoreMenu(track: track),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => MeloErrorState(message: '推荐加载失败：$error'),
    );
  }
}

class _RecommendationsPlaylistsGrid extends ConsumerWidget {
  const _RecommendationsPlaylistsGrid({
    required this.selectedProviderId,
    required this.selectedShelfTab,
    required this.shelfTabs,
  });

  final ProviderId selectedProviderId;
  final _ShelfTab? selectedShelfTab;
  final List<_ShelfTab> shelfTabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedProviderId.value == 'more' || selectedShelfTab == null) {
      return const SizedBox.shrink();
    }

    final playlistsAsync = ref.watch(
      selectedShelfTab == _ShelfTab.playlists
          ? recommendedPlaylistsFutureProvider(selectedProviderId)
          : chartPlaylistsFutureProvider(selectedProviderId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShelfTabSelector(
          tabs: shelfTabs,
          selected: selectedShelfTab!,
          onSelected: (tab) {
            ref.read(_selectedShelfTabProvider.notifier).state = tab;
          },
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 204,
          child: playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return Center(
                  child: Text(
                    selectedShelfTab == _ShelfTab.playlists
                        ? '当前来源没有可展示的推荐歌单。'
                        : '当前来源没有可展示的榜单。',
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: playlists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return MeloPlaylistCard(
                    width: 136,
                    compact: true,
                    title: playlist.name,
                    subtitle: _playlistMeta(playlist),
                    cover: playlist.cover,
                    onTap: () => _showPlaylistSheet(
                      context,
                      ref,
                      playlist.providerId,
                      playlist,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _DesktopRecommendationsView extends ConsumerWidget {
  const _DesktopRecommendationsView({
    required this.selected,
    required this.selectedProviderId,
    required this.enabledProviders,
  });

  final String selected;
  final ProviderId selectedProviderId;
  final List<ProviderRegistryEntry> enabledProviders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ProviderRegistryEntry? selectedEntry;
    for (final entry in enabledProviders) {
      if (entry.descriptor.id.value == selected) {
        selectedEntry = entry;
        break;
      }
    }
    final canShowPlaylists = selectedEntry?.descriptor
            .supports(ProviderCapability.readDailyRecommendations) ??
        false;
    final canShowCharts =
        selectedEntry?.descriptor.supports(ProviderCapability.readCharts) ??
            false;
    final shelfTabs = [
      if (canShowPlaylists) _ShelfTab.playlists,
      if (canShowCharts) _ShelfTab.charts,
    ];
    final selectedShelfState = ref.watch(_selectedShelfTabProvider);
    final selectedShelfTab =
        selectedShelfState != null && shelfTabs.contains(selectedShelfState)
            ? selectedShelfState
            : (shelfTabs.isEmpty ? null : shelfTabs.first);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RecommendationsTabBar(
            selected: selected,
            enabledProviders: enabledProviders,
          ),
          const SizedBox(height: 20),
          _RecommendationsPlaylistsGrid(
            selectedProviderId: selectedProviderId,
            selectedShelfTab: selectedShelfTab,
            shelfTabs: shelfTabs,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                '最近适合你',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: selected == 'more' || !canShowPlaylists
                    ? null
                    : () async {
                        final tracksAsync = ref.read(
                            recommendationsFutureProvider(selectedProviderId));
                        tracksAsync.whenData((tracks) async {
                          if (tracks.isNotEmpty) {
                            await ref
                                .read(demoRepositoryProvider)
                                .playTracks(tracks);
                          }
                        });
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('播放全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _RecommendationsTracksGrid(
              selectedProviderId: selectedProviderId,
              canShowPlaylists: canShowPlaylists,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRecommendationsView extends ConsumerWidget {
  const _MobileRecommendationsView({
    required this.selected,
    required this.selectedProviderId,
    required this.enabledProviders,
  });

  final String selected;
  final ProviderId selectedProviderId;
  final List<ProviderRegistryEntry> enabledProviders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ProviderRegistryEntry? selectedEntry;
    for (final entry in enabledProviders) {
      if (entry.descriptor.id.value == selected) {
        selectedEntry = entry;
        break;
      }
    }
    final canShowPlaylists = selectedEntry?.descriptor
            .supports(ProviderCapability.readDailyRecommendations) ??
        false;
    final canShowCharts =
        selectedEntry?.descriptor.supports(ProviderCapability.readCharts) ??
            false;
    final shelfTabs = [
      if (canShowPlaylists) _ShelfTab.playlists,
      if (canShowCharts) _ShelfTab.charts,
    ];
    final selectedShelfState = ref.watch(_selectedShelfTabProvider);
    final selectedShelfTab =
        selectedShelfState != null && shelfTabs.contains(selectedShelfState)
            ? selectedShelfState
            : (shelfTabs.isEmpty ? null : shelfTabs.first);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _RecommendationsTabBar(
              selected: selected,
              enabledProviders: enabledProviders,
            ),
          ),
          Expanded(
            child: ProviderTabSwipeRegion(
              items: <ProviderTabItem>[
                for (final entry in enabledProviders)
                  ProviderTabItem(
                    id: entry.descriptor.id.value,
                    label: meloProviderPresentation(
                      entry.descriptor.id,
                      displayName: entry.descriptor.displayName,
                    ).shortName,
                    leading: MeloPlatformIcon(providerId: entry.descriptor.id),
                  ),
              ],
              selectedId: selected,
              onSelected: (id) {
                ref.read(_selectedProviderIdProvider.notifier).state = id;
              },
              child: CustomScrollView(
                key: PageStorageKey<String>('mobile_recommendations_$selected'),
                scrollCacheExtent: const ScrollCacheExtent.pixels(240),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        children: [
                          _MobileRecommendationsPlaylistsGrid(
                            selectedProviderId: selectedProviderId,
                            selectedShelfTab: selectedShelfTab,
                            shelfTabs: shelfTabs,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '推荐歌曲',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: selected == 'more' ||
                                        !canShowPlaylists
                                    ? null
                                    : () async {
                                        final tracksAsync = ref.read(
                                            recommendationsFutureProvider(
                                                selectedProviderId));
                                        tracksAsync.whenData((tracks) async {
                                          if (tracks.isNotEmpty) {
                                            await ref
                                                .read(demoRepositoryProvider)
                                                .playTracks(tracks);
                                          }
                                        });
                                      },
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 18),
                                label: const Text('播放全部'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                  _MobileRecommendationsTracksGrid(
                    selectedProviderId: selectedProviderId,
                    canShowPlaylists: canShowPlaylists,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 156)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRecommendationsPlaylistsGrid extends ConsumerWidget {
  const _MobileRecommendationsPlaylistsGrid({
    required this.selectedProviderId,
    required this.selectedShelfTab,
    required this.shelfTabs,
  });

  final ProviderId selectedProviderId;
  final _ShelfTab? selectedShelfTab;
  final List<_ShelfTab> shelfTabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedProviderId.value == 'more' || selectedShelfTab == null) {
      return const SizedBox.shrink();
    }

    final playlistsAsync = ref.watch(
      selectedShelfTab == _ShelfTab.playlists
          ? recommendedPlaylistsFutureProvider(selectedProviderId)
          : chartPlaylistsFutureProvider(selectedProviderId),
    );

    return Column(
      children: [
        const SizedBox(height: 6),
        _ShelfTabSelector(
          tabs: shelfTabs,
          selected: selectedShelfTab!,
          onSelected: (tab) {
            ref.read(_selectedShelfTabProvider.notifier).state = tab;
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return const SizedBox.shrink();
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                scrollCacheExtent: const ScrollCacheExtent.pixels(360),
                addAutomaticKeepAlives: false,
                itemCount: playlists.length.clamp(0, 8),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return MeloPlaylistCard(
                    width: 154,
                    compact: true,
                    title: playlist.name,
                    subtitle: _playlistMeta(playlist),
                    cover: playlist.cover,
                    onTap: () => _showPlaylistSheet(
                      context,
                      ref,
                      playlist.providerId,
                      playlist,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _MobileRecommendationsTracksGrid extends ConsumerWidget {
  const _MobileRecommendationsTracksGrid({
    required this.selectedProviderId,
    required this.canShowPlaylists,
  });

  final ProviderId selectedProviderId;
  final bool canShowPlaylists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedProviderId.value == 'more') {
      return const SliverToBoxAdapter(
        child: _MobileRecommendationMessage(
          message: '当前来源暂未提供推荐内容。',
        ),
      );
    }
    if (!canShowPlaylists) {
      return const SliverToBoxAdapter(
        child: _MobileRecommendationMessage(
          message: '当前来源暂未提供每日推荐。',
        ),
      );
    }

    final currentRef = ref.watch(
      demoRepositoryProvider.select((r) => r.queue.current?.track.ref),
    );
    final recommendationsAsync =
        ref.watch(recommendationsFutureProvider(selectedProviderId));

    return recommendationsAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return const SliverToBoxAdapter(
            child: _MobileRecommendationMessage(message: '当前来源暂未提供推荐歌曲。'),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: tracks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final selected = currentRef == track.ref;
              return MeloMobileTrackRow(
                index: index + 1,
                title: track.title,
                artists: track.artists,
                artwork: track.artwork,
                duration: track.duration,
                isActive: selected,
                onTap: track.isPlayable
                    ? () => ref
                        .read(demoRepositoryProvider)
                        .playOrToggleTrack(track)
                    : null,
                trailing: MeloMobileTrackTrailing(
                  durationLabel: _formatRecommendationDuration(track.duration),
                  actions: [
                    MeloTrackMoreMenu(track: track),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: MeloErrorState(message: '推荐加载失败：$error'),
      ),
    );
  }
}

class _ShelfTabSelector extends ConsumerWidget {
  const _ShelfTabSelector({
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<_ShelfTab> tabs;
  final _ShelfTab selected;
  final ValueChanged<_ShelfTab> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double padding = 4;
    final int selectedIndex = tabs.indexOf(selected);
    final accentProviderId = ref.watch(meloShellAccentProviderIdProvider);
    final foreground = meloShellMobileDockForegroundColor(accentProviderId);
    final selectorFill = Color.lerp(
      meloShellTint(accentProviderId, 0.24),
      foreground,
      0.10,
    )!;
    final selectedFill = Colors.white.withValues(alpha: 0.65);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth && constraints.maxWidth < 960
            ? constraints.maxWidth
            : 260.0;
        final safeTabs = tabs.isEmpty ? 1 : tabs.length;
        final tabWidth = (width - (padding * 2)) / safeTabs;
        return Container(
          width: width,
          height: 44,
          decoration: BoxDecoration(
            color: selectorFill,
            borderRadius: MeloRadii.pill,
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F1C2736),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(padding),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: selectedIndex.clamp(0, safeTabs - 1) * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedFill,
                    borderRadius: MeloRadii.pill,
                    boxShadow: [
                      BoxShadow(
                        color: foreground.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _buildTab(
                        context,
                        tabs[i],
                        selectedIndex == i,
                        foreground,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(
    BuildContext context,
    _ShelfTab tab,
    bool isSelected,
    Color foreground,
  ) {
    final color = isSelected ? foreground : MeloColors.textSecondary;
    final beginColor = isSelected ? MeloColors.textSecondary : foreground;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(tab),
        child: Center(
          child: TweenAnimationBuilder<Color?>(
            duration: const Duration(milliseconds: 200),
            tween: ColorTween(begin: beginColor, end: color),
            builder: (context, animatedColor, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _shelfTabIcon(tab),
                    size: 16,
                    color: animatedColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _shelfTabLabel(tab),
                    style: (Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle())
                        .copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: animatedColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileRecommendationMessage extends StatelessWidget {
  const _MobileRecommendationMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
      ),
    );
  }
}

void _showPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  ProviderId providerId,
  ProviderPlaylist playlist,
) {
  final repository = ref.read(demoRepositoryProvider);
  final tracksFuture = repository.loadProviderPlaylistTracks(
    providerId: providerId,
    playlistId: playlist.playlistId,
  );
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: MeloColors.surface,
    builder: (context) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: FutureBuilder<List<SourceTrack>>(
          future: tracksFuture,
          builder: (context, snapshot) {
            final tracks = snapshot.data ?? const <SourceTrack>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 78,
                        height: 78,
                        child: MeloPlaylistCover(
                          title: playlist.name,
                          cover: playlist.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _playlistMeta(playlist),
                              style: const TextStyle(
                                color: MeloColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: tracks.isEmpty
                            ? null
                            : () => repository.playTracks(tracks),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('播放全部'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: MeloColors.border),
                Expanded(
                  child: switch (snapshot.connectionState) {
                    ConnectionState.done when snapshot.hasError =>
                      MeloErrorState(message: '歌单加载失败：${snapshot.error}'),
                    ConnectionState.done when tracks.isEmpty =>
                      const Center(child: Text('歌单暂无歌曲。')),
                    ConnectionState.done => Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: tracks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            return MeloMobileTrackRow(
                              index: index + 1,
                              title: track.title,
                              artists: track.artists,
                              artwork: track.artwork,
                              duration: track.duration,
                              isActive: false,
                              onTap: track.isPlayable
                                  ? () => ref
                                      .read(demoRepositoryProvider)
                                      .playOrToggleTrack(track)
                                  : null,
                              trailing: MeloMobileTrackTrailing(
                                durationLabel: _formatRecommendationDuration(
                                  track.duration,
                                ),
                                actions: [
                                  MeloTrackMoreMenu(track: track),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

String _playlistMeta(ProviderPlaylist playlist) {
  final playCount = playlist.playCount;
  if (playCount != null && playCount > 0) {
    return '${_compactCount(playCount)}次播放';
  }
  if (playlist.trackCount > 0) {
    return '${playlist.trackCount}首歌';
  }
  return playlist.creatorName ?? '推荐歌单';
}

String _shelfTabLabel(_ShelfTab tab) => switch (tab) {
      _ShelfTab.playlists => '推荐歌单',
      _ShelfTab.charts => '榜单',
    };

IconData _shelfTabIcon(_ShelfTab tab) => switch (tab) {
      _ShelfTab.playlists => Icons.queue_music_rounded,
      _ShelfTab.charts => Icons.leaderboard_rounded,
    };

String _compactCount(int value) {
  if (value >= 100000000) {
    return '${(value / 100000000).toStringAsFixed(1)}亿';
  }
  if (value >= 10000) {
    return '${(value / 10000).toStringAsFixed(1)}万';
  }
  return value.toString();
}

String _formatRecommendationDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
