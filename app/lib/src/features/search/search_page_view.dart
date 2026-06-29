part of 'search_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  String _selectedSource = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final searchable = repository.providerEntries
        .where((entry) =>
            entry.isEnabled &&
            entry.descriptor.supports(ProviderCapability.search))
        .toList(growable: false);
    final tabs = <ProviderTabItem>[
      const ProviderTabItem(id: 'all', label: '全部来源'),
      for (final entry in searchable)
        ProviderTabItem(
          id: entry.descriptor.id.value,
          label: _displayProviderName(entry.descriptor.id),
        ),
    ];
    final selected = tabs.any((item) => item.id == _selectedSource)
        ? _selectedSource
        : 'all';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '搜索',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                '跨来源检索',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MeloColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: '搜索歌曲、歌手或专辑',
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清除',
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          ProviderTabs(
            items: tabs,
            selectedId: selected,
            onSelected: (value) => setState(() => _selectedSource = value),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _query.isEmpty
                ? const _SearchIdleState()
                : _SearchResults(query: _query, selectedSource: selected),
          ),
        ],
      ),
    );
  }
}

class _SearchIdleState extends StatelessWidget {
  const _SearchIdleState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: MeloColors.surface,
          borderRadius: MeloRadii.lg,
          border: Border.all(color: MeloColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.manage_search_rounded,
              size: 42,
              color: MeloColors.primary600,
            ),
            const SizedBox(height: 14),
            Text(
              '从已启用的音乐来源中查找内容',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '结果会标明来源、收藏能力和可播放状态。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayProviderName(ProviderId id) {
  if (id.value.contains('aurora') || id.value.contains('netease')) return '网易云';
  if (id.value.contains('beacon')) return 'QQ音乐';
  return id.value;
}
