part of 'all_favorites_page.dart';

enum _FavoriteSort { recent, album, title, artist, duration }

class AllFavoritesPage extends ConsumerStatefulWidget {
  const AllFavoritesPage({super.key});

  @override
  ConsumerState<AllFavoritesPage> createState() => _AllFavoritesPageState();
}

class _AllFavoritesPageState extends ConsumerState<AllFavoritesPage> {
  String _selectedTab = 'all';
  String _query = '';
  _FavoriteSort _sort = _FavoriteSort.recent;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(demoRepositoryProvider);
    final entries = repository.capabilityMatrix
        .eligibleFavoritesEntries(repository.registry);
    final entryIds = {for (final entry in entries) entry.descriptor.id};
    final loggedInPendingEntries = repository.providerEntries.where((entry) {
      final descriptor = entry.descriptor;
      return entry.isEnabled &&
          descriptor.supports(ProviderCapability.authenticate) &&
          entry.provider.isAuthenticated &&
          !entryIds.contains(descriptor.id);
    });
    final tabs = <ProviderTabItem>[
      const ProviderTabItem(
        id: 'all',
        label: '全部喜欢',
        leading: MeloBrandIcon(),
      ),
      for (final entry in entries)
        ProviderTabItem(
          id: entry.descriptor.id.value,
          label: meloProviderLabel(entry.descriptor.id),
          leading: MeloPlatformIcon(providerId: entry.descriptor.id),
        ),
      for (final entry in loggedInPendingEntries)
        ProviderTabItem(
          id: entry.descriptor.id.value,
          label: meloProviderLabel(entry.descriptor.id),
          leading: MeloPlatformIcon(providerId: entry.descriptor.id),
          enabled: false,
        ),
    ];
    final selected =
        tabs.any((item) => item.id == _selectedTab) ? _selectedTab : 'all';
    final visibleCount = ref.watch(allFavoritesProvider).maybeWhen<int?>(
          data: (tracks) => _visibleTracks(tracks, selected).length,
          orElse: () => null,
        );
    final isMobile = MediaQuery.sizeOf(context).width < 960;
    if (isMobile) {
      return _MobileAllFavoritesView(
        tabs: tabs,
        selected: selected,
        visibleCount: visibleCount,
        sort: _sort,
        onTabSelected: (value) => setState(() => _selectedTab = value),
        onSortSelected: (value) => setState(() => _sort = value),
        onRefresh: () => ref.invalidate(allFavoritesProvider),
        searchController: _searchController,
        query: _query,
        onQueryChanged: (value) =>
            setState(() => _query = value.trim().toLowerCase()),
        onClearQuery: () {
          _searchController.clear();
          setState(() => _query = '');
        },
        onPlayAll: () async {
          final favorites = ref.read(allFavoritesProvider);
          final tracks = favorites.maybeWhen(
            data: (list) => _visibleTracks(list, selected),
            orElse: () => const <UnifiedFavoriteTrack>[],
          );
          if (tracks.isNotEmpty) {
            await repository.playUnifiedTracks(tracks);
          }
        },
      );
    }

    return MeloShellAccentScope(
      providerId: selected,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
        child: Column(
          children: [
            _FavoritesTopRail(
              tabs: tabs,
              selectedId: selected,
              onSelected: (value) => setState(() => _selectedTab = value),
            ),
            const SizedBox(height: 16),
            _FavoritesToolbar(
              controller: _searchController,
              query: _query,
              visibleCount: visibleCount,
              sort: _sort,
              onQueryChanged: (value) {
                setState(() => _query = value.trim().toLowerCase());
              },
              onClearQuery: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              onSortSelected: (value) => setState(() => _sort = value),
              onRefresh: () {
                ref.invalidate(allFavoritesProvider);
              },
              onPlayAll: () async {
                final favorites = ref.read(allFavoritesProvider);
                final tracks = favorites.maybeWhen(
                  data: (list) => _visibleTracks(list, selected),
                  orElse: () => const <UnifiedFavoriteTrack>[],
                );
                if (tracks.isNotEmpty) {
                  await repository.playUnifiedTracks(tracks);
                }
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: _FavoritesLibraryPanel(
                  selectedProviderId: selected == 'all' ? null : selected,
                  query: _query,
                  sort: _sort,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<UnifiedFavoriteTrack> _visibleTracks(
    List<UnifiedFavoriteTrack> tracks,
    String selected,
  ) {
    return tracks.where((track) {
      final providerMatch = selected == 'all' ||
          track.variants.any((item) => item.ref.providerId.value == selected);
      final queryMatch = _query.isEmpty ||
          '${track.title} ${track.artists.join(' ')}'
              .toLowerCase()
              .contains(_query);
      return providerMatch && queryMatch;
    }).toList(growable: false);
  }
}

class _MobileAllFavoritesView extends StatelessWidget {
  const _MobileAllFavoritesView({
    required this.tabs,
    required this.selected,
    required this.visibleCount,
    required this.sort,
    required this.onTabSelected,
    required this.onSortSelected,
    required this.onRefresh,
    required this.onPlayAll,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onClearQuery,
  });

  final List<ProviderTabItem> tabs;
  final String selected;
  final int? visibleCount;
  final _FavoriteSort sort;
  final ValueChanged<String> onTabSelected;
  final ValueChanged<_FavoriteSort> onSortSelected;
  final VoidCallback onRefresh;
  final VoidCallback onPlayAll;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;

  static const _floatingToolbarTop = 12.0;
  static const _floatingToolbarHeight = 40.0;
  static const _floatingToolbarBottomGap = 12.0;
  static const _listTopPadding =
      _floatingToolbarTop + _floatingToolbarHeight + _floatingToolbarBottomGap;

  @override
  Widget build(BuildContext context) {
    return MeloShellAccentScope(
      providerId: selected,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: ProviderTabs(
                items: tabs,
                selectedId: selected,
                onSelected: onTabSelected,
              ),
            ),
            Expanded(
              child: ProviderTabSwipeRegion(
                items: tabs,
                selectedId: selected,
                onSelected: onTabSelected,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RefreshIndicator(
                        displacement: _listTopPadding,
                        onRefresh: () async => onRefresh(),
                        child: _MobileFavoritesLibrary(
                          selectedProviderId:
                              selected == 'all' ? null : selected,
                          sort: sort,
                          query: query,
                          topPadding: _listTopPadding,
                        ),
                      ),
                    ),
                    Positioned(
                      top: _floatingToolbarTop,
                      left: 16,
                      right: 16,
                      child: _MobileFavoritesFloatingToolbar(
                        selected: selected,
                        visibleCount: visibleCount,
                        sort: sort,
                        onSortSelected: onSortSelected,
                        onPlayAll: onPlayAll,
                        searchController: searchController,
                        query: query,
                        onQueryChanged: onQueryChanged,
                        onClearQuery: onClearQuery,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileFavoritesFloatingToolbar extends StatelessWidget {
  const _MobileFavoritesFloatingToolbar({
    required this.selected,
    required this.visibleCount,
    required this.sort,
    required this.onSortSelected,
    required this.onPlayAll,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onClearQuery,
  });

  final String selected;
  final int? visibleCount;
  final _FavoriteSort sort;
  final ValueChanged<_FavoriteSort> onSortSelected;
  final VoidCallback onPlayAll;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    final dockForeground = meloShellMobileDockForegroundColor(selected);
    final hintText =
        visibleCount == null ? '搜索歌曲 · 加载中' : '搜索歌曲 · $visibleCount 首';

    return SizedBox(
      height: _MobileAllFavoritesView._floatingToolbarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MobileSearchBar(
              controller: searchController,
              query: query,
              hintText: hintText,
              accentProviderId: selected,
              onQueryChanged: onQueryChanged,
              onClearQuery: onClearQuery,
            ),
          ),
          const SizedBox(width: 8),
          _MobileSortButton(
            sort: sort,
            accentProviderId: selected,
            onSelected: onSortSelected,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: MeloRadii.pill,
                boxShadow: _mobileFloatingControlShadow,
              ),
              child: FilledButton(
                onPressed: onPlayAll,
                style: FilledButton.styleFrom(
                  backgroundColor: dockForeground,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: const RoundedRectangleBorder(
                    borderRadius: MeloRadii.pill,
                  ),
                  elevation: 0,
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 18),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '播放全部',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _mobileFloatingControlShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x141C2736),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
];

Color _mobileFloatingControlFillColor(String providerId) => Color.lerp(
      meloShellMobileDockIndicatorColor(providerId),
      meloShellMobileDockForegroundColor(providerId),
      0.18,
    )!
        .withValues(alpha: 0.92);

class _MobileSearchBar extends StatelessWidget {
  const _MobileSearchBar({
    required this.controller,
    required this.query,
    required this.hintText,
    required this.accentProviderId,
    required this.onQueryChanged,
    required this.onClearQuery,
  });

  final TextEditingController controller;
  final String query;
  final String hintText;
  final String accentProviderId;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    final foreground = meloShellMobileDockForegroundColor(accentProviderId);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _mobileFloatingControlFillColor(accentProviderId),
        borderRadius: MeloRadii.pill,
        boxShadow: _mobileFloatingControlShadow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onQueryChanged,
        textAlignVertical: TextAlignVertical.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MeloColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: foreground.withValues(alpha: 0.82),
            size: 20,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 40,
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: '清除搜索',
                  onPressed: onClearQuery,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: foreground.withValues(alpha: 0.82),
                    size: 18,
                  ),
                ),
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
              ),
          contentPadding: const EdgeInsets.only(right: 12),
        ),
      ),
    );
  }
}

class _MobileSortButton extends StatelessWidget {
  const _MobileSortButton({
    required this.sort,
    required this.accentProviderId,
    required this.onSelected,
  });

  final _FavoriteSort sort;
  final String accentProviderId;
  final ValueChanged<_FavoriteSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<PopupMenuButtonState<_FavoriteSort>> menuKey = GlobalKey();
    final foreground = meloShellMobileDockForegroundColor(accentProviderId);
    return PopupMenuButton<_FavoriteSort>(
      key: menuKey,
      tooltip: '排序',
      onSelected: onSelected,
      offset: const Offset(0, 44),
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 80),
        reverseDuration: Duration(milliseconds: 60),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      itemBuilder: (context) => [
        for (final item in _FavoriteSort.values)
          PopupMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(
                  item == sort ? Icons.check_rounded : Icons.sort_rounded,
                  size: 18,
                  color: item == sort ? foreground : MeloColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Text(_sortLabel(item)),
              ],
            ),
          ),
      ],
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: MeloRadii.pill,
          boxShadow: _mobileFloatingControlShadow,
        ),
        child: IconButton(
          tooltip: '排序',
          icon: Icon(
            Icons.swap_vert_rounded,
            size: 20,
            color: foreground,
          ),
          onPressed: () => menuKey.currentState?.showButtonMenu(),
          style: IconButton.styleFrom(
            fixedSize: const Size(40, 40),
            backgroundColor: _mobileFloatingControlFillColor(accentProviderId),
            shape: const RoundedRectangleBorder(borderRadius: MeloRadii.pill),
          ),
        ),
      ),
    );
  }
}

class _FavoritesTopRail extends StatelessWidget {
  const _FavoritesTopRail({
    required this.tabs,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ProviderTabItem> tabs;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ProviderTabs(
        items: tabs,
        selectedId: selectedId,
        onSelected: onSelected,
      ),
    );
  }
}

class _FavoritesToolbar extends StatelessWidget {
  const _FavoritesToolbar({
    required this.controller,
    required this.query,
    required this.visibleCount,
    required this.sort,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSortSelected,
    required this.onRefresh,
    required this.onPlayAll,
  });

  final TextEditingController controller;
  final String query;
  final int? visibleCount;
  final _FavoriteSort sort;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_FavoriteSort> onSortSelected;
  final VoidCallback onRefresh;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          visibleCount == null ? '正在统计喜欢歌曲' : '共 $visibleCount 首歌曲',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        SizedBox(
          width: MeloDimensions.desktopToolbarSearchWidth,
          child: Container(
            height: MeloDimensions.desktopToolbarControlHeight,
            decoration: BoxDecoration(
              color: MeloColors.surface,
              borderRadius: MeloRadii.sm,
              border: Border.all(color: MeloColors.border),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              textAlignVertical: TextAlignVertical.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: MeloColors.textSecondary,
                  size: 20,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: MeloDimensions.desktopToolbarControlHeight,
                  minHeight: MeloDimensions.desktopToolbarControlHeight,
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除搜索',
                        onPressed: onClearQuery,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: MeloColors.textSecondary,
                          size: 16,
                        ),
                      ),
                hintText: '搜索歌曲、歌手或专辑',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textTertiary,
                    ),
                contentPadding:
                    const EdgeInsets.only(right: 12, top: 2, bottom: 2),
              ),
            ),
          ),
        ),
        const SizedBox(width: MeloSpacing.toolbarControlGap),
        _SortButton(sort: sort, onSelected: onSortSelected),
        const SizedBox(width: MeloSpacing.toolbarControlGap),
        IconButton(
          tooltip: '刷新同步歌单',
          icon: const Icon(
            Icons.sync_rounded,
            color: MeloColors.textSecondary,
            size: 20,
          ),
          onPressed: onRefresh,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(
              MeloDimensions.desktopToolbarControlHeight,
            ),
            backgroundColor: MeloColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: MeloRadii.sm,
              side: BorderSide(color: MeloColors.border),
            ),
          ),
        ),
        const SizedBox(width: MeloSpacing.toolbarControlGap),
        FilledButton.icon(
          onPressed: onPlayAll,
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('播放全部'),
          style: FilledButton.styleFrom(
            fixedSize: const Size.fromHeight(
              MeloDimensions.desktopToolbarControlHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: const RoundedRectangleBorder(borderRadius: MeloRadii.sm),
            elevation: 0,
            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _SortButton extends StatefulWidget {
  const _SortButton({required this.sort, required this.onSelected});

  final _FavoriteSort sort;
  final ValueChanged<_FavoriteSort> onSelected;

  @override
  State<_SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends State<_SortButton> {
  final GlobalKey<PopupMenuButtonState<_FavoriteSort>> _menuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_FavoriteSort>(
      key: _menuKey,
      tooltip: '排序',
      onSelected: widget.onSelected,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: MeloRadii.md),
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 80),
        reverseDuration: Duration(milliseconds: 60),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      itemBuilder: (context) => [
        for (final item in _FavoriteSort.values)
          PopupMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(
                  item == widget.sort
                      ? Icons.check_rounded
                      : Icons.sort_rounded,
                  size: 18,
                  color: item == widget.sort
                      ? MeloColors.primary700
                      : MeloColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Text(_sortLabel(item)),
              ],
            ),
          ),
      ],
      child: IconButton(
        tooltip: '排序',
        icon: const Icon(
          Icons.tune_rounded,
          size: 20,
          color: MeloColors.textSecondary,
        ),
        onPressed: () => _menuKey.currentState?.showButtonMenu(),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(
            MeloDimensions.desktopToolbarControlHeight,
          ),
          backgroundColor: MeloColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: MeloRadii.sm,
            side: BorderSide(color: MeloColors.border),
          ),
        ),
      ),
    );
  }
}

String _sortLabel(_FavoriteSort sort) => switch (sort) {
      _FavoriteSort.recent => '最近添加',
      _FavoriteSort.album => '按专辑',
      _FavoriteSort.title => '歌曲名称',
      _FavoriteSort.artist => '歌手名称',
      _FavoriteSort.duration => '歌曲时长',
    };
