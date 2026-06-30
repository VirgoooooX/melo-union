import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../widgets/melo_components.dart';
import '../../widgets/provider_tabs.dart';

class RecommendationsPage extends ConsumerStatefulWidget {
  const RecommendationsPage({super.key});

  @override
  ConsumerState<RecommendationsPage> createState() =>
      _RecommendationsPageState();
}

class _RecommendationsPageState extends ConsumerState<RecommendationsPage> {
  String _selectedProvider = 'netease_cloud_music';
  final Map<String, Future<List<SourceTrack>>> _recommendationFutures = {};
  final Map<String, Future<List<ProviderPlaylist>>> _playlistFutures = {};

  Future<List<SourceTrack>> _recommendationsFuture(ProviderId providerId) {
    return _recommendationFutures.putIfAbsent(
      providerId.value,
      () => ref.read(demoRepositoryProvider).loadRecommendations(providerId),
    );
  }

  Future<List<ProviderPlaylist>> _recommendedPlaylistsFuture(
    ProviderId providerId,
  ) {
    return _playlistFutures.putIfAbsent(
      providerId.value,
      () => ref.read(demoRepositoryProvider).loadRecommendedPlaylists(
            providerId,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final currentRef = ref.watch(
      demoRepositoryProvider.select((r) => r.queue.current?.track.ref),
    );
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
          label: meloProviderLabel(entry.descriptor.id),
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
          if (selected != 'more') ...[
            _RecommendedPlaylistStrip(
              playlistsFuture: _recommendedPlaylistsFuture(selectedProviderId),
              onPlaylistSelected: (playlist) => _showPlaylistSheet(
                context,
                ref,
                selectedProviderId,
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
                onPressed: selected == 'more'
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
                : FutureBuilder<List<SourceTrack>>(
                    future: _recommendationsFuture(selectedProviderId),
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
                            final selected = currentRef == track.ref;
                            return MeloInteractiveRow(
                              selected: selected,
                              onTap: () => ref
                                  .read(demoRepositoryProvider)
                                  .playTrack(track),
                              builder: (context, hovered) => Row(
                                children: [
                                  SizedBox(
                                    width: 38,
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
                                  MeloTrackCover(
                                    seed: track.title,
                                    artwork: track.artwork,
                                    isActive: selected,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: selected
                                                ? MeloColors.primary700
                                                : MeloColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${track.artists.join(' / ')} · ${track.album ?? '今日推荐'}',
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
                                  IconButton(
                                    tooltip: '喜欢',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => ref
                                        .read(demoRepositoryProvider)
                                        .toggleFavorite(
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

class _RecommendedPlaylistStrip extends StatelessWidget {
  const _RecommendedPlaylistStrip({
    required this.playlistsFuture,
    required this.onPlaylistSelected,
  });

  final Future<List<ProviderPlaylist>> playlistsFuture;
  final ValueChanged<ProviderPlaylist> onPlaylistSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProviderPlaylist>>(
      future: playlistsFuture,
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
              height: 204,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
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
            ),
          ],
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
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
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
                          return MeloInteractiveRow(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            onTap: () => ref
                                .read(demoRepositoryProvider)
                                .playTrack(track),
                            builder: (context, hovered) => Row(
                              children: [
                                SizedBox(
                                  width: 38,
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    size: 18,
                                    color: hovered
                                        ? MeloColors.primary700
                                        : MeloColors.textTertiary,
                                  ),
                                ),
                                MeloTrackCover(
                                  seed: track.title,
                                  artwork: track.artwork,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: MeloColors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${track.artists.join(' / ')} · ${track.album ?? '歌单'}',
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
                              ],
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
