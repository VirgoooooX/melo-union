import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../widgets/source_track_tile.dart';

class AllFavoritesPage extends ConsumerWidget {
  const AllFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final favorites = ref.watch(allFavoritesProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _PageHeader(
          title: '全部喜欢',
          subtitle: '仅聚合已启用、已登录且支持 readFavorites 的 Provider。',
          trailing: FilledButton.icon(
            onPressed: () => ref.invalidate(allFavoritesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('刷新假数据'),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              label: '聚合来源',
              value: repository.capabilityMatrix
                  .eligibleFavoritesEntries(repository.registry)
                  .length
                  .toString(),
            ),
            _SummaryCard(
              label: '本地歌单',
              value: repository.playlistList.length.toString(),
            ),
            _SummaryCard(
              label: '队列状态',
              value: repository.queue.entries.isEmpty ? '空' : '就绪',
            ),
          ],
        ),
        const SizedBox(height: 20),
        favorites.when(
          data: (items) {
            if (items.isEmpty) {
              return const _EmptyState(
                message: '当前没有可聚合的喜欢来源。可在 Provider / 我的 页面启用或登录账号型来源。',
              );
            }
            return Column(
              children: [
                for (final item in items) ...[
                  _UnifiedFavoriteCard(track: item),
                  const SizedBox(height: 14),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => _EmptyState(message: error.toString()),
        ),
      ],
    );
  }
}

class _UnifiedFavoriteCard extends ConsumerWidget {
  const _UnifiedFavoriteCard({required this.track});

  final UnifiedFavoriteTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);

    return Material(
      color: MeloColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: MeloRadii.md,
        side: BorderSide(color: MeloColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          track.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: MeloColors.textPrimary,
              ),
        ),
        subtitle: Text(
          '${track.artists.join(' / ')} · ${track.variants.length} 个来源',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
        trailing: FilledButton.icon(
          onPressed: () => repository.playUnifiedTrack(track),
          icon: const Icon(Icons.play_arrow),
          label: const Text('播放来源组'),
        ),
        children: [
          for (final variant in track.variants) ...[
            SourceTrackTile(
              track: variant,
              providerName: repository.registry
                      .describe(variant.ref.providerId)
                      ?.displayName ??
                  variant.ref.providerId.value,
              favoriteAvailability: repository.favoriteWriteAvailability(
                variant.ref.providerId,
              ),
              playlists: repository.playlistList,
              isDownloadSupported: repository.registry
                      .describe(variant.ref.providerId)
                      ?.supports(ProviderCapability.resolveDownload) ??
                  false,
              downloadTask: repository.downloadCoordinator.getTask(variant.ref),
              onPlay: () => repository.playTrack(variant),
              onEnqueue: () => repository.enqueueTrack(variant),
              onAddToPlaylist: (playlistId) => repository.addTrackToPlaylist(
                playlistId: playlistId,
                track: variant,
              ),
              onDownload: () {
                repository.addDownloadTask(variant);
                repository.startDownload(variant.ref);
              },
              onPauseDownload: () => repository.pauseDownload(variant.ref),
              onCancelDownload: () => repository.cancelDownload(variant.ref),
              onFavoriteChanged: (liked) async {
                await _handleFavoriteToggle(
                  context,
                  repository,
                  variant,
                  liked,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

Future<void> _handleFavoriteToggle(
  BuildContext context,
  DemoRepository repository,
  SourceTrack track,
  bool liked,
) async {
  try {
    await repository.toggleFavorite(track: track, liked: liked);
  } on ProviderException catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MeloColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        trailing,
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MeloColors.textSecondary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: MeloColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MeloColors.textSecondary,
            ),
      ),
    );
  }
}
