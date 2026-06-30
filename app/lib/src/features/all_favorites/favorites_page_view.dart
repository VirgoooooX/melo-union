part of 'all_favorites_page.dart';

enum _FavoriteSort { recent, title, artist, duration }

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
    final tabs = <ProviderTabItem>[
      const ProviderTabItem(id: 'all', label: '全部喜欢'),
      for (final entry in entries)
        ProviderTabItem(
          id: entry.descriptor.id.value,
          label: meloProviderLabel(entry.descriptor.id),
        ),
      const ProviderTabItem(
        id: 'more',
        label: '更多平台',
        trailing: Icons.keyboard_arrow_down_rounded,
      ),
    ];
    final selected =
        tabs.any((item) => item.id == _selectedTab) ? _selectedTab : 'all';
    final visibleCount = ref.watch(allFavoritesProvider).maybeWhen<int?>(
          data: (tracks) => _visibleTracks(tracks, selected).length,
          orElse: () => null,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
      child: Column(
        children: [
          _FavoritesTopRail(
            tabs: tabs,
            selectedId: selected,
            onSelected: (value) {
              if (value == 'more') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('后续接入的平台会在这里显示。')),
                );
                return;
              }
              setState(() => _selectedTab = value);
            },
          ),
          const SizedBox(height: 22),
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
          ),
          const SizedBox(height: 18),
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
  });

  final TextEditingController controller;
  final String query;
  final int? visibleCount;
  final _FavoriteSort sort;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_FavoriteSort> onSortSelected;

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
          width: 248,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: MeloColors.surface,
              borderRadius: MeloRadii.sm,
              border: Border.all(color: MeloColors.border),
            ),
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              textAlignVertical: TextAlignVertical.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: MeloColors.textSecondary,
                ),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除搜索',
                        onPressed: onClearQuery,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: MeloColors.textSecondary,
                          size: 18,
                        ),
                      ),
                hintText: '搜索歌曲、歌手或专辑',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textTertiary,
                    ),
                contentPadding: const EdgeInsets.only(right: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _SortButton(sort: sort, onSelected: onSortSelected),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onSelected});

  final _FavoriteSort sort;
  final ValueChanged<_FavoriteSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_FavoriteSort>(
      tooltip: '排序',
      onSelected: onSelected,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: MeloRadii.md),
      itemBuilder: (context) => [
        for (final item in _FavoriteSort.values)
          PopupMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(
                  item == sort ? Icons.check_rounded : Icons.sort_rounded,
                  size: 18,
                  color: item == sort
                      ? MeloColors.primary700
                      : MeloColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Text(_sortLabel(item)),
              ],
            ),
          ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: MeloColors.surface,
          borderRadius: MeloRadii.sm,
          border: Border.all(color: MeloColors.border),
        ),
        child: const Icon(
          Icons.tune_rounded,
          size: 18,
          color: MeloColors.textSecondary,
        ),
      ),
    );
  }
}

String _sortLabel(_FavoriteSort sort) => switch (sort) {
      _FavoriteSort.recent => '最近添加',
      _FavoriteSort.title => '歌曲名称',
      _FavoriteSort.artist => '歌手名称',
      _FavoriteSort.duration => '歌曲时长',
    };
