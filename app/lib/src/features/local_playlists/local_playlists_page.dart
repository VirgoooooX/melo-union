import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../widgets/source_track_tile.dart';

class LocalPlaylistsPage extends ConsumerWidget {
  const LocalPlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final playlists = repository.playlistList;
    final selected = repository.selectedPlaylist;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本地歌单',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: MeloColors.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '歌单只保存 ProviderTrackRef 与缓存元数据；禁用来源后仍可显示历史条目。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MeloColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showNameDialog(
                  context,
                  title: '新建歌单',
                  confirmLabel: '创建',
                  onConfirm: repository.createPlaylist,
                ),
                icon: const Icon(Icons.add),
                label: const Text('新建歌单'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      SizedBox(
                        width: 260,
                        child: _PlaylistSelector(playlists: playlists),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _PlaylistDetails(playlist: selected)),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: _PlaylistSelector(playlists: playlists),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _PlaylistDetails(playlist: selected)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistSelector extends ConsumerWidget {
  const _PlaylistSelector({required this.playlists});

  final List<LocalPlaylist> playlists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final selectedId = repository.selectedPlaylistId;

    return Container(
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: playlists.isEmpty
          ? const Center(child: Text('还没有本地歌单', style: TextStyle(color: MeloColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: playlists.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                final selected = playlist.id == selectedId;
                return InkWell(
                  onTap: () => repository.selectPlaylist(playlist.id),
                  borderRadius: MeloRadii.sm,
                  child: Ink(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? MeloColors.primary50
                          : MeloColors.surfaceMuted,
                      borderRadius: MeloRadii.sm,
                      border: Border.all(
                        color: selected
                            ? MeloColors.primary500
                            : MeloColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: selected ? MeloColors.primary700 : MeloColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${playlist.items.length} 首',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: selected ? MeloColors.primary600 : MeloColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _showNameDialog(
                                  context,
                                  title: '重命名歌单',
                                  initialValue: playlist.name,
                                  confirmLabel: '保存',
                                  onConfirm: (name) =>
                                      repository.renamePlaylist(
                                    playlistId: playlist.id,
                                    nextName: name,
                                  ),
                                );
                                break;
                              case 'delete':
                                repository.deletePlaylist(playlist.id);
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'rename', child: Text('重命名')),
                            PopupMenuItem(value: 'delete', child: Text('删除')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PlaylistDetails extends ConsumerWidget {
  const _PlaylistDetails({required this.playlist});

  final LocalPlaylist? playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);

    if (playlist == null) {
      return const _PlaylistPlaceholder(message: '创建一个本地歌单开始整理来源引用。');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            playlist!.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: MeloColors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${playlist!.items.length} 个缓存引用',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MeloColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: playlist!.items.isEmpty
                ? const _PlaylistPlaceholder(message: '从搜索或全部喜欢加入条目。')
                : ListView.separated(
                    itemCount: playlist!.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = playlist!.items[index];
                      final resolved =
                          repository.playlistResolver.resolve(item);
                      final sourceTrack =
                          repository.sourceTrackByRef(item.trackRef);

                      if (resolved.sourceAvailable && sourceTrack != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SourceTrackTile(
                              track: sourceTrack,
                              providerName: resolved.providerName,
                              favoriteAvailability:
                                  repository.favoriteWriteAvailability(
                                sourceTrack.ref.providerId,
                              ),
                              playlists: repository.playlistList,
                              isDownloadSupported: repository.registry
                                      .describe(sourceTrack.ref.providerId)
                                      ?.supports(
                                          ProviderCapability.resolveDownload) ??
                                  false,
                              downloadTask: repository.downloadCoordinator
                                  .getTask(sourceTrack.ref),
                              onPlay: () => repository.playTrack(sourceTrack),
                              onEnqueue: () =>
                                  repository.enqueueTrack(sourceTrack),
                              onAddToPlaylist: (playlistId) =>
                                  repository.addTrackToPlaylist(
                                playlistId: playlistId,
                                track: sourceTrack,
                              ),
                              onDownload: () {
                                repository.addDownloadTask(sourceTrack);
                                repository.startDownload(sourceTrack.ref);
                              },
                              onPauseDownload: () =>
                                  repository.pauseDownload(sourceTrack.ref),
                              onCancelDownload: () =>
                                  repository.cancelDownload(sourceTrack.ref),
                              onFavoriteChanged: (liked) async {
                                try {
                                    await repository.toggleFavorite(
                                      track: sourceTrack,
                                      liked: liked,
                                    );
                                } on ProviderException catch (error) {
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error.message)),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: () =>
                                  repository.removeTrackFromPlaylist(
                                playlistId: playlist!.id,
                                trackRef: item.trackRef,
                              ),
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('移出歌单'),
                            ),
                          ],
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: MeloColors.surfaceMuted,
                          borderRadius: MeloRadii.md,
                          border: Border.all(color: MeloColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.music_off,
                                color: MeloColors.warning),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resolved.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: MeloColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${resolved.artists.join(' / ')} · ${resolved.providerName}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: MeloColors.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    resolved.unavailableReason ?? '来源当前不可用',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: MeloColors.warning),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  repository.removeTrackFromPlaylist(
                                playlistId: playlist!.id,
                                trackRef: item.trackRef,
                              ),
                              icon: const Icon(Icons.delete_outline),
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

class _PlaylistPlaceholder extends StatelessWidget {
  const _PlaylistPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MeloColors.textSecondary,
            ),
      ),
    );
  }
}

Future<void> _showNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required ValueChanged<String> onConfirm,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  try {
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    if (value != null && value.isNotEmpty) {
      onConfirm(value);
    }
  } finally {
    controller.dispose();
  }
}
