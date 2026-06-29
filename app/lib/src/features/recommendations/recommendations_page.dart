import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../widgets/provider_tabs.dart';

class RecommendationsPage extends ConsumerStatefulWidget {
  const RecommendationsPage({super.key});

  @override
  ConsumerState<RecommendationsPage> createState() =>
      _RecommendationsPageState();
}

class _RecommendationsPageState extends ConsumerState<RecommendationsPage> {
  String _selectedProvider = 'aurora_stream';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final providers = repository.providerEntries
        .where((entry) =>
            entry.isEnabled &&
            entry.provider.isAuthenticated &&
            entry.descriptor
                .supports(ProviderCapability.readDailyRecommendations))
        .toList(growable: false);
    final tabs = <ProviderTabItem>[
      for (final entry in providers)
        ProviderTabItem(
          id: entry.descriptor.id.value,
          label: _providerLabel(entry.descriptor.id),
        ),
      const ProviderTabItem(
        id: 'more',
        label: '更多平台',
        trailing: Icons.keyboard_arrow_down_rounded,
      ),
    ];
    final selected = tabs.any((item) => item.id == _selectedProvider)
        ? _selectedProvider
        : (providers.isEmpty ? 'more' : providers.first.descriptor.id.value);
    final source = repository.providers[ProviderId(selected)];
    final tracks = source
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
              if (id == 'more') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('后续接入的推荐来源会显示在这里。')),
                );
                return;
              }
              setState(() => _selectedProvider = id);
            },
          ),
          const SizedBox(height: 20),
          _RecommendationHero(providerId: selected),
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
                onPressed: tracks.isEmpty
                    ? null
                    : () => repository.playTrack(tracks.first),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('播放全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tracks.isEmpty
                ? const Center(child: Text('当前来源暂未提供推荐内容。'))
                : ListView.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: MeloColors.border),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        leading: _Cover(seed: track.title),
                        title: Text(
                          track.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                            '${track.artists.join(' / ')} · ${track.album ?? '今日推荐'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: '播放',
                              onPressed: () => repository.playTrack(track),
                              icon: const Icon(Icons.play_arrow_rounded),
                            ),
                            IconButton(
                              tooltip: '喜欢',
                              onPressed: () => repository.toggleFavorite(
                                track: track,
                                liked: !track.isFavorited,
                              ),
                              icon: Icon(
                                track.isFavorited
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: track.isFavorited
                                    ? MeloColors.favorite
                                    : MeloColors.textTertiary,
                              ),
                            ),
                          ],
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
              : const [Color(0xFF4BAA69), Color(0xFF1F7B8E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isNetease ? '网易云 · 今日推荐' : 'QQ音乐 · 今日推荐',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '从当前 Provider 的音乐库中发现新的播放灵感。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: MeloRadii.sm,
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .55, .62).toColor(),
            HSLColor.fromAHSL(1, (hue + 50) % 360, .56, .4).toColor(),
          ],
        ),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.white),
    );
  }
}

String _providerLabel(ProviderId id) {
  if (id.value.contains('aurora')) return '网易云';
  if (id.value.contains('beacon')) return 'QQ音乐';
  return id.value;
}
