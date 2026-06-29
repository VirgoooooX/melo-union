part of 'all_favorites_page.dart';

class AllFavoritesPage extends ConsumerStatefulWidget {
  const AllFavoritesPage({super.key});

  @override
  ConsumerState<AllFavoritesPage> createState() => _AllFavoritesPageState();
}

class _AllFavoritesPageState extends ConsumerState<AllFavoritesPage> {
  String _selectedTab = 'all';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final entries = repository.capabilityMatrix
        .eligibleFavoritesEntries(repository.registry);
    final tabs = <ProviderTabItem>[
      const ProviderTabItem(id: 'all', label: '全部喜欢'),
      for (final entry in entries)
        ProviderTabItem(
            id: entry.descriptor.id.value,
            label: providerLabel(entry.descriptor.id)),
      const ProviderTabItem(
          id: 'more',
          label: '更多平台',
          trailing: Icons.keyboard_arrow_down_rounded),
    ];
    final selected =
        tabs.any((item) => item.id == _selectedTab) ? _selectedTab : 'all';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ProviderTabs(
                  items: tabs,
                  selectedId: selected,
                  onSelected: (value) {
                    if (value == 'more') {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('后续接入的平台会在这里显示。')));
                    } else {
                      setState(() => _selectedTab = value);
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: '刷新喜欢列表',
                onPressed: () => ref.invalidate(allFavoritesProvider),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 270,
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: '搜索歌曲、歌手或专辑'),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list_rounded),
                  label: const Text('筛选')),
              const SizedBox(width: 8),
              FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('播放全部')),
            ],
          ),
          const SizedBox(height: 16),
          const _FavoritesHeader(),
          const SizedBox(height: 4),
          Expanded(
              child: _FavoritesList(
                  selectedProviderId: selected == 'all' ? null : selected,
                  query: _query)),
        ],
      ),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: MeloColors.textTertiary, fontWeight: FontWeight.w700);
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
          color: MeloColors.surfaceMuted, borderRadius: MeloRadii.sm),
      child: Row(children: [
        SizedBox(width: 34, child: Text('#', style: style)),
        const SizedBox(width: 48),
        Expanded(flex: 4, child: Text('歌曲', style: style)),
        Expanded(flex: 2, child: Text('专辑', style: style)),
        SizedBox(width: 124, child: Text('来源', style: style)),
        SizedBox(width: 48, child: Text('时长', style: style)),
        const SizedBox(width: 44),
      ]),
    );
  }
}
