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
  String _selectedProvider = 'netease_cloud_music';

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
    final selectedProviderId = ProviderId(selected);

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
          if (selected != 'more') ...[
            const SizedBox(height: 24),
            _RecommendedPlaylistStrip(providerId: selectedProviderId),
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
                onPressed: selected == 'more'
                    ? null
                    : () async {
                        final tracks = await repository
                            .loadRecommendations(selectedProviderId);
                        if (tracks.isNotEmpty) {
                          await repository.playTrack(tracks.first);
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
                : FutureBuilder<List<SourceTrack>>(
                    future: repository.loadRecommendations(selectedProviderId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('推荐加载失败：${snapshot.error}'));
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
                          itemCount: tracks.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: MeloColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: _Cover(
                                seed: track.title,
                                artwork: track.artwork,
                              ),
                              title: Text(
                                track.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${track.artists.join(' / ')} · ${track.album ?? '今日推荐'}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: '播放',
                                    onPressed: () =>
                                        repository.playTrack(track),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedPlaylistStrip extends ConsumerWidget {
  const _RecommendedPlaylistStrip({required this.providerId});

  final ProviderId providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    return FutureBuilder<List<ProviderPlaylist>>(
      future: repository.loadRecommendedPlaylists(providerId),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final playlists = snapshot.data ?? const <ProviderPlaylist>[];
        if (snapshot.hasError || (!isLoading && playlists.isEmpty)) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '推荐歌单',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 178,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: playlists.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return _RecommendedPlaylistCard(
                          playlist: playlist,
                          onTap: () => _showPlaylistSheet(
                            context,
                            ref,
                            providerId,
                            playlist,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _RecommendedPlaylistCard extends StatelessWidget {
  const _RecommendedPlaylistCard({
    required this.playlist,
    required this.onTap,
  });

  final ProviderPlaylist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: InkWell(
        borderRadius: MeloRadii.md,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _PlaylistCover(playlist: playlist),
              ),
              const SizedBox(height: 8),
              Text(
                playlist.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MeloColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _playlistMeta(playlist),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MeloColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistCover extends StatelessWidget {
  const _PlaylistCover({required this.playlist});

  final ProviderPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    final cover = playlist.cover;
    if (cover != null && cover.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: MeloRadii.md,
        child: Image.network(
          cover.toString(),
          fit: BoxFit.cover,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://music.163.com',
          },
          errorBuilder: (_, __, ___) => _playlistPlaceholder(playlist.name),
        ),
      );
    }
    return _playlistPlaceholder(playlist.name);
  }
}

Widget _playlistPlaceholder(String seed) {
  final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
  return Container(
    decoration: BoxDecoration(
      borderRadius: MeloRadii.md,
      gradient: LinearGradient(
        colors: [
          HSLColor.fromAHSL(1, hue.toDouble(), .48, .64).toColor(),
          HSLColor.fromAHSL(1, (hue + 36) % 360, .5, .42).toColor(),
        ],
      ),
    ),
    child: const Icon(Icons.queue_music_rounded, color: Colors.white),
  );
}

void _showPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  ProviderId providerId,
  ProviderPlaylist playlist,
) {
  final repository = ref.read(demoRepositoryProvider);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: MeloColors.surface,
    builder: (context) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: FutureBuilder<List<SourceTrack>>(
          future: repository.loadProviderPlaylistTracks(
            providerId: providerId,
            playlistId: playlist.playlistId,
          ),
          builder: (context, snapshot) {
            final tracks = snapshot.data ?? const <SourceTrack>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 78,
                        height: 78,
                        child: _PlaylistCover(playlist: playlist),
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
                            : () => repository.playTrack(tracks.first),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('播放全部'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: MeloColors.border),
                Expanded(
                  child: switch (snapshot.connectionState) {
                    ConnectionState.done when snapshot.hasError => Center(
                        child: Text('歌单加载失败：${snapshot.error}'),
                      ),
                    ConnectionState.done when tracks.isEmpty =>
                      const Center(child: Text('歌单暂无歌曲。')),
                    ConnectionState.done => ListView.separated(
                        itemCount: tracks.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: MeloColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 5,
                            ),
                            leading: _Cover(
                              seed: track.title,
                              artwork: track.artwork,
                            ),
                            title: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${track.artists.join(' / ')} · ${track.album ?? '歌单'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: '播放',
                              onPressed: () => repository.playTrack(track),
                              icon: const Icon(Icons.play_arrow_rounded),
                            ),
                          );
                        },
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

class _RecommendationHero extends StatelessWidget {
  const _RecommendationHero({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context) {
    final isNetease =
        providerId.contains('aurora') || providerId.contains('netease');
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: MeloRadii.lg,
        color: MeloColors.surface,
        border: Border.all(color: MeloColors.border),
        boxShadow: MeloShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isNetease ? '网易云 · 今日推荐' : 'QQ音乐 · 今日推荐',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isNetease
                      ? MeloColors.neteaseForeground
                      : MeloColors.primary700,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '从当前 Provider 的音乐库中发现新的播放灵感。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MeloColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.seed, this.artwork});

  final String seed;
  final Uri? artwork;

  @override
  Widget build(BuildContext context) {
    if (artwork != null && artwork!.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: MeloRadii.sm,
        child: Image.network(
          artwork!.toString(),
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://music.163.com',
          },
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
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
  if (id.value.contains('aurora') || id.value.contains('netease')) return '网易云';
  if (id.value.contains('beacon')) return 'QQ音乐';
  return id.value;
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

String _compactCount(int value) {
  if (value >= 100000000) {
    return '${(value / 100000000).toStringAsFixed(1)}亿';
  }
  if (value >= 10000) {
    return '${(value / 10000).toStringAsFixed(1)}万';
  }
  return value.toString();
}
