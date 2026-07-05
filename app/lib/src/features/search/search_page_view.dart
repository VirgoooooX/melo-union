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
    final compact = MediaQuery.sizeOf(context).width < 760;
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
          leading: MeloPlatformIcon(providerId: entry.descriptor.id),
          label: meloProviderPresentation(
            entry.descriptor.id,
            displayName: entry.descriptor.displayName,
          ).shortName,
        ),
    ];
    final selected = tabs.any((item) => item.id == _selectedSource)
        ? _selectedSource
        : 'all';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 18 : 20,
        compact ? 16 : 24,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '搜索',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: compact ? 28 : null,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
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
              filled: true,
              fillColor: MeloColors.surface,
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
          compact
              ? _MobileSearchSourceRail(
                  items: tabs,
                  selectedId: selected,
                  onSelected: (value) =>
                      setState(() => _selectedSource = value),
                )
              : ProviderTabs(
                  items: tabs,
                  selectedId: selected,
                  onSelected: (value) =>
                      setState(() => _selectedSource = value),
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

class _MobileSearchSourceRail extends StatelessWidget {
  const _MobileSearchSourceRail({
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ProviderTabItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return _MobileSearchSourceChip(
            item: item,
            selected: item.id == selectedId,
            onTap: () => onSelected(item.id),
          );
        },
      ),
    );
  }
}

class _MobileSearchSourceChip extends StatelessWidget {
  const _MobileSearchSourceChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ProviderTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? MeloColors.primary700 : MeloColors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? MeloColors.primary50 : MeloColors.surface,
          borderRadius: MeloRadii.pill,
          border: Border.all(
            color: selected ? MeloColors.primary100 : MeloColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            item.leading ??
                Icon(
                  Icons.all_inclusive_rounded,
                  size: 18,
                  color: foreground,
                ),
            const SizedBox(width: 7),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
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
          boxShadow: MeloShadows.card,
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
