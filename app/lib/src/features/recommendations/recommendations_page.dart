import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../presentation/provider_presentation.dart';
import '../../widgets/melo_components.dart';
import '../../widgets/provider_tabs.dart';

enum _ShelfTab { playlists, charts }

class RecommendationsPage extends ConsumerStatefulWidget {
  const RecommendationsPage({super.key});

  @override
  ConsumerState<RecommendationsPage> createState() =>
      _RecommendationsPageState();
}

class _RecommendationsPageState extends ConsumerState<RecommendationsPage> {
  String? _selectedProvider;
  _ShelfTab? _selectedShelfTab;
  final Map<String, Future<List<SourceTrack>>> _recommendationFutures = {};
  final Map<String, Future<List<ProviderPlaylist>>> _playlistFutures = {};
  final Map<String, Future<List<ProviderPlaylist>>> _chartFutures = {};

  Future<List<SourceTrack>> _recommendationsFuture(ProviderId providerId) {
    final repo = ref.read(demoRepositoryProvider);
    final cached = repo.cachedRecommendations(providerId);
    if (cached != null && repo.hasFreshRecommendations) {
      return Future.value(cached);
    }
    return _recommendationFutures.putIfAbsent(
      providerId.value,
      () => repo.loadRecommendations(providerId),
    );
  }

  Future<List<ProviderPlaylist>> _recommendedPlaylistsFuture(
    ProviderId providerId,
  ) {
    final repo = ref.read(demoRepositoryProvider);
    final cached = repo.cachedRemotePlaylists(providerId);
    if (cached != null && repo.hasFreshRemotePlaylists(providerId)) {
      return Future.value(cached);
    }
    return _playlistFutures.putIfAbsent(
      providerId.value,
      () => repo.loadRecommendedPlaylists(providerId),
    );
  }

  Future<List<ProviderPlaylist>> _chartPlaylistsFuture(ProviderId providerId) {
    final repo = ref.read(demoRepositoryProvider);
    final cached = repo.cachedRemotePlaylists(providerId);
    if (cached != null && repo.hasFreshRemotePlaylists(providerId)) {
      return Future.value(cached);
    }
    return _chartFutures.putIfAbsent(
      providerId.value,
      () => repo.loadChartPlaylists(providerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final currentRef = ref.watch(
      demoRepositoryProvider.select((r) => r.queue.current?.track.ref),
    );
    final providers = repository.providerEntries.where((entry) {
      if (!entry.isEnabled) return false;
      final canReadRecommendations = entry.provider.isAuthenticated &&
          entry.descriptor
              .supports(ProviderCapability.readDailyRecommendations);
      final canReadCharts =
          entry.descriptor.supports(ProviderCapability.readCharts);
      return canReadRecommendations || canReadCharts;
    }).toList(growable: false);
    final tabs = <ProviderTabItem>[
      for (final entry in providers)
        ProviderTabItem(
          id: entry.descriptor.id.value,
          label: meloProviderPresentation(
            entry.descriptor.id,
            displayName: entry.descriptor.displayName,
          ).shortName,
          leading: MeloPlatformIcon(providerId: entry.descriptor.id),
        ),
      const ProviderTabItem(
        id: 'more',
        label: '更多平台',
        trailing: Icons.keyboard_arrow_down_rounded,
      ),
    ];
    final selected = _selectedProvider != null &&
            tabs.any((item) => item.id == _selectedProvider)
        ? _selectedProvider!
        : (providers.isEmpty ? 'more' : providers.first.descriptor.id.value);
    final selectedProviderId = ProviderId(selected);
    ProviderRegistryEntry? selectedEntry;
    for (final entry in providers) {
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
    final selectedShelfTab =
        _selectedShelfTab != null && shelfTabs.contains(_selectedShelfTab)
            ? _selectedShelfTab!
            : (shelfTabs.isEmpty ? null : shelfTabs.first);
    final isMobile = MediaQuery.sizeOf(context).width < 960;
    if (isMobile) {
      return _MobileRecommendationsView(
        tabs: tabs,
        selected: selected,
        selectedProviderId: selectedProviderId,
        selectedShelfTab: selectedShelfTab,
        shelfTabs: shelfTabs,
        canShowPlaylists: canShowPlaylists,
        selectedEntry: selectedEntry,
        currentRef: currentRef,
        repository: repository,
        recommendationsFuture: selected == 'more' || !canShowPlaylists
            ? null
            : _recommendationsFuture(selectedProviderId),
        playlistsFuture: selected == 'more' || selectedShelfTab == null
            ? null
            : selectedShelfTab == _ShelfTab.playlists
                ? _recommendedPlaylistsFuture(selectedProviderId)
                : _chartPlaylistsFuture(selectedProviderId),
        onTabSelected: (id) => setState(() => _selectedProvider = id),
        onShelfSelected: (tab) => setState(() => _selectedShelfTab = tab),
        onMorePressed: () {
          MeloSnackbar.show(
            context: context,
            message: '后续接入的推荐来源会显示在这里。',
          );
        },
        onPlaylistSelected: (playlist) => _showPlaylistSheet(
          context,
          ref,
          playlist.providerId,
          playlist,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProviderTabs(
            items: tabs,
            selectedId: selected,
            onSelected: (id) => setState(() => _selectedProvider = id),
            onMorePressed: () {
              MeloSnackbar.show(
                context: context,
                message: '后续接入的推荐来源会显示在这里。',
              );
            },
          ),
          const SizedBox(height: 20),
          if (selected != 'more' && selectedShelfTab != null) ...[
            _ShelfTabSelector(
              tabs: shelfTabs,
              selected: selectedShelfTab,
              onSelected: (tab) => setState(() => _selectedShelfTab = tab),
            ),
            const SizedBox(height: 14),
            _PlaylistShelf(
              selectedTab: selectedShelfTab,
              emptyLabel: selectedShelfTab == _ShelfTab.playlists
                  ? '当前来源没有可展示的推荐歌单。'
                  : '当前来源没有可展示的榜单。',
              playlistsFuture: selectedShelfTab == _ShelfTab.playlists
                  ? _recommendedPlaylistsFuture(selectedProviderId)
                  : _chartPlaylistsFuture(selectedProviderId),
              onPlaylistSelected: (playlist) => _showPlaylistSheet(
                context,
                ref,
                playlist.providerId,
                playlist,
              ),
            ),
          ],
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
                        final tracks =
                            await _recommendationsFuture(selectedProviderId);
                        if (tracks.isNotEmpty) {
                          await ref
                              .read(demoRepositoryProvider)
                              .playTracks(tracks);
                        }
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('播放全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: selected == 'more'
                ? const Center(child: Text('当前来源暂未提供推荐内容。'))
                : !canShowPlaylists
                    ? const Center(child: Text('当前来源暂未提供每日推荐。'))
                    : FutureBuilder<List<SourceTrack>>(
                        future: _recommendationsFuture(selectedProviderId),
                        builder: (context, snapshot) {
                          final cached = selectedEntry != null
                              ? repository.cachedRecommendations(
                                  selectedEntry.descriptor.id)
                              : null;
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            if (cached != null && cached.isNotEmpty) {
                              return _CachedRecommendationList(
                                tracks: cached,
                                currentRef: currentRef,
                              );
                            }
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return MeloErrorState(
                                message: '推荐加载失败：${snapshot.error}');
                          }
                          final tracks = snapshot.data ?? const [];
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
                              scrollCacheExtent:
                                  const ScrollCacheExtent.pixels(560),
                              addAutomaticKeepAlives: false,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: MeloColors.border,
                              ),
                              itemBuilder: (context, index) {
                                final track = tracks[index];
                                final selected = currentRef == track.ref;
                                return MeloInteractiveRow(
                                  selected: selected,
                                  onDoubleTap: track.isPlayable
                                      ? () => ref
                                          .read(demoRepositoryProvider)
                                          .playOrToggleTrack(track)
                                      : null,
                                  builder: (context, hovered) => Row(
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: Icon(
                                          selected
                                              ? Icons.graphic_eq_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 18,
                                          color: selected || hovered
                                              ? MeloColors.primary700
                                              : MeloColors.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            MeloTrackCover(
                                              seed: track.title,
                                              artwork: track.artwork,
                                              isActive: selected,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child:
                                                  _RecommendationTrackTitleBlock(
                                                title: track.title,
                                                artists: track.artists,
                                                active: selected,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          track.album ?? '今日推荐',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: MeloColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      MeloTrackDownloadButton(track: track),
                                      MeloFavoriteButton(track: track),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ShelfTabSelector extends StatelessWidget {
  const _ShelfTabSelector({
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<_ShelfTab> tabs;
  final _ShelfTab selected;
  final ValueChanged<_ShelfTab> onSelected;

  @override
  Widget build(BuildContext context) {
    const double padding = 4;
    final int selectedIndex = tabs.indexOf(selected);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth && constraints.maxWidth < 960
            ? constraints.maxWidth
            : 260.0;
        final safeTabs = tabs.isEmpty ? 1 : tabs.length;
        final tabWidth = (width - 2 - (padding * 2)) / safeTabs;
        return Container(
          width: width,
          height: 44,
          decoration: BoxDecoration(
            color: MeloColors.surfaceMuted,
            borderRadius: MeloRadii.pill,
            border: Border.all(color: MeloColors.border),
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
                    color: MeloColors.primary600,
                    borderRadius: MeloRadii.pill,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F0AA69A),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _buildTab(context, tabs[i], selectedIndex == i),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, _ShelfTab tab, bool isSelected) {
    final color = isSelected ? MeloColors.surface : MeloColors.textSecondary;
    final beginColor =
        isSelected ? MeloColors.textSecondary : MeloColors.surface;

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

class _MobileRecommendationsView extends StatelessWidget {
  const _MobileRecommendationsView({
    required this.tabs,
    required this.selected,
    required this.selectedProviderId,
    required this.selectedShelfTab,
    required this.shelfTabs,
    required this.canShowPlaylists,
    required this.selectedEntry,
    required this.currentRef,
    required this.repository,
    required this.recommendationsFuture,
    required this.playlistsFuture,
    required this.onTabSelected,
    required this.onShelfSelected,
    required this.onMorePressed,
    required this.onPlaylistSelected,
  });

  final List<ProviderTabItem> tabs;
  final String selected;
  final ProviderId selectedProviderId;
  final _ShelfTab? selectedShelfTab;
  final List<_ShelfTab> shelfTabs;
  final bool canShowPlaylists;
  final ProviderRegistryEntry? selectedEntry;
  final ProviderTrackRef? currentRef;
  final DemoRepository repository;
  final Future<List<SourceTrack>>? recommendationsFuture;
  final Future<List<ProviderPlaylist>>? playlistsFuture;
  final ValueChanged<String> onTabSelected;
  final ValueChanged<_ShelfTab> onShelfSelected;
  final VoidCallback onMorePressed;
  final ValueChanged<ProviderPlaylist> onPlaylistSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: ProviderTabs(
              items: tabs,
              selectedId: selected,
              onSelected: onTabSelected,
              onMorePressed: onMorePressed,
            ),
          ),
          Expanded(
            child: ProviderTabSwipeRegion(
              items: tabs,
              selectedId: selected,
              onSelected: onTabSelected,
              child: CustomScrollView(
                key: PageStorageKey<String>('mobile_recommendations_$selected'),
                scrollCacheExtent: const ScrollCacheExtent.pixels(240),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        children: [
                          if (selected != 'more' && selectedShelfTab != null) ...[
                            const SizedBox(height: 6),
                            _ShelfTabSelector(
                              tabs: shelfTabs,
                              selected: selectedShelfTab!,
                              onSelected: onShelfSelected,
                            ),
                            const SizedBox(height: 14),
                            _MobilePlaylistShelf(
                              playlistsFuture: playlistsFuture,
                              onPlaylistSelected: onPlaylistSelected,
                            ),
                          ],
                          const SizedBox(height: 22),
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
                                onPressed: recommendationsFuture == null
                                    ? null
                                    : () async {
                                        final tracks =
                                            await recommendationsFuture!;
                                        if (tracks.isNotEmpty) {
                                          await repository.playTracks(tracks);
                                        }
                                      },
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 18),
                                label: const Text('播放全部'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  if (selected == 'more')
                    const SliverToBoxAdapter(
                      child: _MobileRecommendationMessage(
                        message: '当前来源暂未提供推荐内容。',
                      ),
                    )
                  else if (!canShowPlaylists)
                    const SliverToBoxAdapter(
                      child: _MobileRecommendationMessage(
                        message: '当前来源暂未提供每日推荐。',
                      ),
                    )
                  else
                    _MobileRecommendationTrackSliver(
                      future: recommendationsFuture!,
                      cached: selectedEntry == null
                          ? null
                          : repository.cachedRecommendations(
                              selectedEntry!.descriptor.id,
                            ),
                      currentRef: currentRef,
                      repository: repository,
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

class _MobilePlaylistShelf extends StatelessWidget {
  const _MobilePlaylistShelf({
    required this.playlistsFuture,
    required this.onPlaylistSelected,
  });

  final Future<List<ProviderPlaylist>>? playlistsFuture;
  final ValueChanged<ProviderPlaylist> onPlaylistSelected;

  @override
  Widget build(BuildContext context) {
    final future = playlistsFuture;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<List<ProviderPlaylist>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 226,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final playlists = snapshot.data ?? const <ProviderPlaylist>[];
        if (snapshot.hasError || playlists.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 226,
          child: ListView.separated(
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
                onTap: () => onPlaylistSelected(playlist),
              );
            },
          ),
        );
      },
    );
  }
}

class _MobileRecommendationTrackSliver extends StatelessWidget {
  const _MobileRecommendationTrackSliver({
    required this.future,
    required this.cached,
    required this.currentRef,
    required this.repository,
  });

  final Future<List<SourceTrack>> future;
  final List<SourceTrack>? cached;
  final ProviderTrackRef? currentRef;
  final DemoRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SourceTrack>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          final cachedTracks = cached;
          if (cachedTracks != null && cachedTracks.isNotEmpty) {
            return _buildSliver(cachedTracks);
          }
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: MeloErrorState(message: '推荐加载失败：${snapshot.error}'),
          );
        }
        final tracks = snapshot.data ?? const <SourceTrack>[];
        if (tracks.isEmpty) {
          return const SliverToBoxAdapter(
            child: _MobileRecommendationMessage(message: '当前来源暂无推荐歌曲。'),
          );
        }
        return _buildSliver(tracks);
      },
    );
  }

  Widget _buildSliver(List<SourceTrack> tracks) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: tracks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final track = tracks[index];
          final selected = currentRef == track.ref;
          return MeloTapFeedback(
            onTap: track.isPlayable
                ? () => repository.playOrToggleTrack(track)
                : null,
            selected: selected,
            borderRadius: BorderRadius.circular(12),
            animatePress: false,
            child: Container(
              decoration: BoxDecoration(
                color: selected ? MeloColors.primary50 : MeloColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: MeloShadows.card,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 28,
                    child: Center(
                      child: selected
                          ? const Icon(
                              Icons.graphic_eq_rounded,
                              color: MeloColors.primary700,
                              size: 16,
                            )
                          : Text(
                              '${index + 1}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MeloColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MeloTrackCover(
                    seed: track.title,
                    artwork: track.artwork,
                    isActive: selected,
                    size: 48,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: selected
                                    ? MeloColors.primary700
                                    : MeloColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artists.join(' / '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: MeloColors.textSecondary,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatRecommendationDuration(track.duration),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(width: 4),
                  MeloTrackDownloadButton(track: track, lightweight: true),
                  MeloFavoriteButton(track: track, lightweight: true),
                ],
              ),
            ),
          );
        },
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

class _PlaylistShelf extends StatelessWidget {
  const _PlaylistShelf({
    required this.selectedTab,
    required this.emptyLabel,
    required this.playlistsFuture,
    required this.onPlaylistSelected,
  });

  final _ShelfTab selectedTab;
  final String emptyLabel;
  final Future<List<ProviderPlaylist>> playlistsFuture;
  final ValueChanged<ProviderPlaylist> onPlaylistSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProviderPlaylist>>(
      future: playlistsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final playlists = snapshot.data ?? const <ProviderPlaylist>[];
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        Widget child;
        if (!isLoading && playlists.isEmpty) {
          child = SizedBox(
            key: ValueKey('empty_$selectedTab'),
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                emptyLabel,
                style: const TextStyle(color: MeloColors.textSecondary),
              ),
            ),
          );
        } else if (isLoading) {
          child = SizedBox(
            key: ValueKey('loading_$selectedTab'),
            height: 204,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          child = SizedBox(
            key: ValueKey('list_$selectedTab'),
            height: 204,
            child: ListView.separated(
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
                  onTap: () => onPlaylistSelected(playlist),
                );
              },
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: child,
        );
      },
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
                            return MeloTapFeedback(
                              onTap: track.isPlayable
                                  ? () => ref
                                      .read(demoRepositoryProvider)
                                      .playOrToggleTrack(track)
                                  : null,
                              selected: false,
                              borderRadius: BorderRadius.circular(12),
                              animatePress: false,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: MeloColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: MeloShadows.card,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 28,
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    MeloColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    MeloTrackCover(
                                      seed: track.title,
                                      artwork: track.artwork,
                                      size: 48,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            track.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      MeloColors.textPrimary,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            track.artists.join(' / '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: MeloColors
                                                      .textSecondary,
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _formatRecommendationDuration(
                                          track.duration),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: MeloColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    MeloTrackDownloadButton(
                                      track: track,
                                      lightweight: true,
                                    ),
                                    MeloFavoriteButton(
                                      track: track,
                                      lightweight: true,
                                    ),
                                  ],
                                ),
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

class _RecommendationTrackTitleBlock extends StatelessWidget {
  const _RecommendationTrackTitleBlock({
    required this.title,
    required this.artists,
    required this.active,
  });

  final String title;
  final List<String> artists;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: active ? MeloColors.primary700 : MeloColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          artists.join(' / '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MeloColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Simplified list display for cached recommendations during background refresh.
class _CachedRecommendationList extends ConsumerWidget {
  const _CachedRecommendationList({
    required this.tracks,
    required this.currentRef,
  });

  final List<SourceTrack> tracks;
  final ProviderTrackRef? currentRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      key: const PageStorageKey<String>('cached_recommendation_tracks'),
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
        return MeloInteractiveRow(
          selected: selected,
          onDoubleTap: track.isPlayable
              ? () => ref.read(demoRepositoryProvider).playOrToggleTrack(track)
              : null,
          builder: (context, hovered) => Row(
            children: [
              SizedBox(
                width: 32,
                child: Icon(
                  selected
                      ? Icons.graphic_eq_rounded
                      : Icons.play_arrow_rounded,
                  size: 18,
                  color: selected || hovered
                      ? MeloColors.primary700
                      : MeloColors.textTertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    MeloTrackCover(
                      seed: track.title,
                      artwork: track.artwork,
                      isActive: selected,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RecommendationTrackTitleBlock(
                        title: track.title,
                        artists: track.artists,
                        active: selected,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  track.album ?? '今日推荐',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MeloColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              MeloTrackDownloadButton(track: track),
              MeloFavoriteButton(track: track),
            ],
          ),
        );
      },
    );
  }
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
