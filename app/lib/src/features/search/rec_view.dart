part of 'search_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String _selectedTab = 'aurora_stream';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final tabs = const [
      ProviderTabItem(id: 'aurora_stream', label: '网易云'),
      ProviderTabItem(id: 'beacon_archive', label: 'QQ音乐'),
      ProviderTabItem(
          id: 'more',
          label: '更多平台',
          trailing: Icons.keyboard_arrow_down_rounded),
    ];
    final selected = _selectedTab == 'more' ? 'aurora_stream' : _selectedTab;
    final active = repository.providers[ProviderId(selected)];
    final tracks = active
            ?.allTracks()
            .where((track) => track.isPlayable)
            .toList(growable: false) ??
        const [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProviderTabs(
              items: tabs,
              selectedId: selected,
              onSelected: (id) {
                if (id != 'more') setState(() => _selectedTab = id);
              }),
          const SizedBox(height: 20),
          _RecommendationHero(providerId: selected),
          const SizedBox(height: 24),
          Row(children: [
            Text('最近适合你',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            FilledButton.icon(
                onPressed: tracks.isEmpty
                    ? null
                    : () => repository.playTrack(tracks.first),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('播放全部')),
          ]),
          const SizedBox(height: 12),
          Expanded(child: _RecommendationList(tracks: tracks)),
        ],
      ),
    );
  }
}

class _RecommendationHero extends StatelessWidget {
  const _RecommendationHero({required this.providerId});
  final String providerId;

  @override
  Widget build(BuildContext context) {
    final isNetease = providerId.contains('aurora');
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          borderRadius: MeloRadii.lg,
          gradient: LinearGradient(
              colors: isNetease
                  ? const [Color(0xFF14B8A6), Color(0xFF3172B8)]
                  : const [Color(0xFF4BAA69), Color(0xFF1F7B8E)])),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isNetease ? '网易云 · 今日推荐' : 'QQ音乐 · 今日推荐',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('从当前 Provider 的音乐库中发现新的播放灵感。',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70)),
          ]),
    );
  }
}
