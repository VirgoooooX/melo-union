part of 'all_favorites_page.dart';

class _FavoriteRow extends ConsumerStatefulWidget {
  const _FavoriteRow({
    required this.index,
    required this.track,
    required this.providerId,
  });

  final int index;
  final UnifiedFavoriteTrack track;
  final String? providerId;

  @override
  ConsumerState<_FavoriteRow> createState() => _FavoriteRowState();
}

class _FavoriteRowState extends ConsumerState<_FavoriteRow> {
  @override
  Widget build(BuildContext context) {
    final repository = ref.read(demoRepositoryProvider);
    final currentRef = ref.watch(
        demoRepositoryProvider.select((r) => r.queue.current?.track.ref));
    final variants = widget.providerId == null
        ? widget.track.variants
        : widget.track.variants
            .where((item) => item.ref.providerId.value == widget.providerId)
            .toList(growable: false);
    if (variants.isEmpty) return const SizedBox.shrink();

    final primary = variants.first;
    final isPlaying = currentRef != null &&
        variants.any((variant) => variant.ref == currentRef);
    final hasFavorite = variants.any((variant) => variant.isFavorited);
    return MeloInteractiveRow(
      selected: isPlaying,
      height: MeloListMetrics.rowHeight,
      onDoubleTap: () => repository.playOrToggleUnifiedTrack(widget.track),
      builder: (context, hovered) {
        return Row(
          children: [
            SizedBox(
              width: 32,
              child: Center(
                child: _RowPlaybackIndicator(
                  index: widget.index,
                  hovered: hovered,
                  isPlaying: isPlaying,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  MeloTrackCover(
                    seed: widget.track.title,
                    isActive: isPlaying,
                    artwork: widget.track.variants
                        .firstWhere((v) => v.artwork != null, orElse: () => primary)
                        .artwork,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TrackTitleBlock(
                      title: widget.track.title,
                      artists: widget.track.artists,
                      active: isPlaying,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _albumLabel(variants),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            SizedBox(
              width: 132,
              child: Center(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final item in variants)
                      MeloSourceBadge(providerId: item.ref.providerId),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 64,
              child: Center(
                child: IconButton(
                  tooltip: variants.length > 1
                      ? '管理多个来源的收藏状态'
                      : hasFavorite
                          ? '取消喜欢'
                          : '喜欢',
                  onPressed: () => _handleFavoriteTap(
                    context,
                    repository,
                    variants,
                  ),
                  splashRadius: 20,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    hasFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: hasFavorite
                        ? MeloColors.favorite
                        : MeloColors.textTertiary,
                    size: 21,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Center(
                child: _TrackMoreMenu(track: primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleFavoriteTap(
    BuildContext context,
    DemoRepository repository,
    List<SourceTrack> variants,
  ) async {
    if (variants.length > 1) {
      await showDialog<void>(
        context: context,
        builder: (context) => _FavoriteSourceDialog(
          track: widget.track,
          variants: variants,
        ),
      );
      return;
    }

    final source = variants.first;
    final availability =
        repository.favoriteWriteAvailability(source.ref.providerId);
    if (!availability.isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(availability.reason ?? '此来源无法写回收藏。')),
      );
      return;
    }
    await _toggleSingle(context, repository, source);
  }

  Future<void> _toggleSingle(
    BuildContext context,
    DemoRepository repository,
    SourceTrack source,
  ) async {
    final newLiked = !source.isFavorited;
    try {
      await repository.toggleFavorite(
        track: source,
        liked: newLiked,
      );
      ref.invalidate(allFavoritesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newLiked ? '已收藏' : '已取消收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } on ProviderException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _TrackTitleBlock extends StatelessWidget {
  const _TrackTitleBlock({
    required this.title,
    required this.artists,
    required this.active,
  });

  final String title;
  final List<String> artists;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: active ? MeloColors.primary700 : MeloColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          artists.join(' / '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MeloColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

String _albumLabel(List<SourceTrack> variants) {
  for (final variant in variants) {
    final album = variant.album;
    if (album != null && album.trim().isNotEmpty) {
      return album;
    }
  }
  return '未知专辑';
}

class _RowPlaybackIndicator extends StatelessWidget {
  const _RowPlaybackIndicator({
    required this.index,
    required this.hovered,
    required this.isPlaying,
  });

  final int index;
  final bool hovered;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final color = isPlaying ? MeloColors.primary700 : MeloColors.textTertiary;
    return isPlaying
        ? Icon(
            Icons.graphic_eq_rounded,
            color: color,
            size: 18,
          )
        : hovered
            ? Icon(
                Icons.play_arrow_rounded,
                color: MeloColors.primary700,
                size: 20,
              )
            : Text(
                '$index'.padLeft(2, '0'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              );
  }
}

class _TrackMoreMenu extends ConsumerWidget {
  const _TrackMoreMenu({required this.track});

  final SourceTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    return PopupMenuButton<_TrackMenuAction>(
      tooltip: '更多操作',
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      offset: const Offset(0, 42),
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
      onSelected: (action) async {
        if (action == _TrackMenuAction.playNext) {
          repository.enqueueTrack(track);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已添加到播放队列末尾。')),
          );
          return;
        }
        if (action == _TrackMenuAction.addToPlaylist) {
          await showDialog<void>(
            context: context,
            builder: (context) => _AddToPlaylistDialog(track: track),
          );
          return;
        }
        repository.addDownloadTask(track);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已创建下载任务。')),
        );
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _TrackMenuAction.playNext,
          child: _TrackMenuItem(
            icon: Icons.queue_music_rounded,
            label: '加入播放队列',
          ),
        ),
        const PopupMenuItem(
          value: _TrackMenuAction.addToPlaylist,
          child: _TrackMenuItem(
            icon: Icons.playlist_add_rounded,
            label: '加入本地歌单',
          ),
        ),
        PopupMenuItem(
          value: _TrackMenuAction.download,
          enabled: track.isDownloadable,
          child: _TrackMenuItem(
            icon: track.isDownloadable
                ? Icons.download_rounded
                : Icons.block_rounded,
            label: track.isDownloadable ? '下载' : '当前来源不支持下载',
          ),
        ),
      ],
    );
  }
}

enum _TrackMenuAction { playNext, addToPlaylist, download }

class _TrackMenuItem extends StatelessWidget {
  const _TrackMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(label),
        ],
      );
}

class _AddToPlaylistDialog extends ConsumerWidget {
  const _AddToPlaylistDialog({required this.track});

  final SourceTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final playlists = repository.playlistList;
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '加入本地歌单',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(child: Text('还没有本地歌单。')),
                )
              else ...[
                for (final playlist in playlists) ...[
                  _PlaylistChoice(
                    playlist: playlist,
                    onTap: () {
                      repository.addTrackToPlaylist(
                        playlistId: playlist.id,
                        track: track,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已加入“${playlist.name}”。')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final name = await _askForPlaylistName(context);
                  if (name == null || name.trim().isEmpty) return;
                  repository.createPlaylist(name.trim());
                  final target = repository.selectedPlaylistId;
                  if (target != null) {
                    repository.addTrackToPlaylist(
                      playlistId: target,
                      track: track,
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('新建歌单并加入'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _askForPlaylistName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建本地歌单'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '歌单名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    controller.dispose();
    return name;
  }
}

class _PlaylistChoice extends StatelessWidget {
  const _PlaylistChoice({required this.playlist, required this.onTap});

  final LocalPlaylist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: MeloRadii.md,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: MeloColors.surfaceMuted,
          borderRadius: MeloRadii.md,
          border: Border.all(color: MeloColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: MeloColors.primary50,
                borderRadius: MeloRadii.sm,
              ),
              child: const Icon(
                Icons.playlist_play_rounded,
                color: MeloColors.primary700,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist.items.length} 首 · 混合歌单',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.add_rounded,
              color: MeloColors.primary700,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteSourceDialog extends ConsumerWidget {
  const _FavoriteSourceDialog({
    required this.track,
    required this.variants,
  });

  final UnifiedFavoriteTrack track;
  final List<SourceTrack> variants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '管理收藏来源',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: MeloColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '同一首歌在多个来源中存在。每个来源的喜欢状态独立维护。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MeloColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 14),
              for (final variant in variants) ...[
                _FavoriteSourceItem(variant: variant),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteSourceItem extends ConsumerWidget {
  const _FavoriteSourceItem({required this.variant});

  final SourceTrack variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final liveVariant = repository.sourceTrackByRef(variant.ref) ?? variant;
    final availability =
        repository.favoriteWriteAvailability(liveVariant.ref.providerId);
    final canWrite = availability.isEnabled;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MeloColors.surfaceMuted,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: Row(
        children: [
          MeloSourceBadge(providerId: liveVariant.ref.providerId),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              liveVariant.isFavorited ? '已收藏到这个来源' : '尚未收藏到这个来源',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Tooltip(
            message: canWrite
                ? (liveVariant.isFavorited ? '取消喜欢' : '喜欢')
                : availability.reason ?? '此来源无法写回收藏',
            child: IconButton(
              onPressed: canWrite
                  ? () async {
                      try {
                        await repository.toggleFavorite(
                          track: liveVariant,
                          liked: !liveVariant.isFavorited,
                        );
                        ref.invalidate(allFavoritesProvider);
                      } on ProviderException catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      }
                    }
                  : null,
              icon: Icon(
                liveVariant.isFavorited
                    ? Icons.favorite_rounded
                    : canWrite
                        ? Icons.favorite_border_rounded
                        : Icons.lock_outline_rounded,
                color: liveVariant.isFavorited
                    ? MeloColors.favorite
                    : canWrite
                        ? MeloColors.textTertiary
                        : MeloColors.textQuaternary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
