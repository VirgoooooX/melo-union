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
          label: providerLabel(entry.descriptor.id),
        ),
      const ProviderTabItem(
        id: 'more',
        label: '更多平台',
        trailing: Icons.keyboard_arrow_down_rounded,
      ),
    ];
    final selected =
        tabs.any((item) => item.id == _selectedTab) ? _selectedTab : 'all';

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
            onRefresh: () => ref.invalidate(allFavoritesProvider),
          ),
          const SizedBox(height: 22),
          _FavoritesToolbar(
            controller: _searchController,
            query: _query,
            sort: _sort,
            onQueryChanged: (value) {
              setState(() => _query = value.trim().toLowerCase());
            },
            onClearQuery: () {
              _searchController.clear();
              setState(() => _query = '');
            },
            onSortSelected: (value) => setState(() => _sort = value),
            onPlayAll: () => _playAllVisible(selected),
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

  Future<void> _playAllVisible(String selected) async {
    final tracks = await ref.read(allFavoritesProvider.future);
    final visible = tracks.where((track) {
      final providerMatch = selected == 'all' ||
          track.variants.any((item) => item.ref.providerId.value == selected);
      final queryMatch = _query.isEmpty ||
          '${track.title} ${track.artists.join(' ')}'
              .toLowerCase()
              .contains(_query);
      return providerMatch && queryMatch;
    }).toList(growable: false);
    if (visible.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前筛选条件下没有可播放的歌曲。')),
        );
      }
      return;
    }
    await ref.read(demoRepositoryProvider).playUnifiedTracks(visible);
  }
}

class _FavoritesTopRail extends StatelessWidget {
  const _FavoritesTopRail({
    required this.tabs,
    required this.selectedId,
    required this.onSelected,
    required this.onRefresh,
  });

  final List<ProviderTabItem> tabs;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ProviderTabs(
            items: tabs,
            selectedId: selectedId,
            onSelected: onSelected,
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: '刷新喜欢列表',
          child: InkWell(
            onTap: onRefresh,
            borderRadius: MeloRadii.md,
            child: Ink(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: MeloColors.surface,
                borderRadius: MeloRadii.md,
                border: Border.all(color: MeloColors.border),
                boxShadow: MeloShadows.card,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: MeloColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoritesToolbar extends StatelessWidget {
  const _FavoritesToolbar({
    required this.controller,
    required this.query,
    required this.sort,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSortSelected,
    required this.onPlayAll,
  });

  final TextEditingController controller;
  final String query;
  final _FavoriteSort sort;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_FavoriteSort> onSortSelected;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: MeloColors.surface,
              borderRadius: MeloRadii.md,
              border: Border.all(color: MeloColors.border),
              boxShadow: MeloShadows.card,
            ),
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
              decoration: InputDecoration(
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
                contentPadding: const EdgeInsets.only(right: 12, top: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _SortButton(sort: sort, onSelected: onSortSelected),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onPlayAll,
          icon: const Icon(Icons.play_arrow_rounded, size: 19),
          label: const Text('播放全部'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
            elevation: 0,
          ),
        ),
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
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: MeloColors.surface,
          borderRadius: MeloRadii.md,
          border: Border.all(color: MeloColors.border),
          boxShadow: MeloShadows.card,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.tune_rounded,
              size: 18,
              color: MeloColors.primary700,
            ),
            const SizedBox(width: 7),
            Text(
              _sortLabel(sort),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: MeloColors.textSecondary,
            ),
          ],
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
