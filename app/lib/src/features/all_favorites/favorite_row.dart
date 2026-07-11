part of 'all_favorites_page.dart';

class _FavoriteRow extends ConsumerStatefulWidget {
  const _FavoriteRow({
    required this.index,
    required this.track,
    required this.providerId,
    required this.onPlay,
  });

  final int index;
  final UnifiedFavoriteTrack track;
  final String? providerId;
  final Future<void> Function() onPlay;

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
    return MeloInteractiveRow(
      selected: isPlaying,
      height: MeloListMetrics.rowHeight,
      onDoubleTap: () {
        if (isPlaying) {
          unawaited(repository.playOrToggleUnifiedTrack(widget.track));
        } else {
          unawaited(widget.onPlay());
        }
      },
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
                        .firstWhere((v) => v.artwork != null,
                            orElse: () => primary)
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
                      MeloPlatformIcon(providerId: item.ref.providerId),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Center(
                child: MeloTrackMoreMenu(
                  unifiedTrack: widget.track,
                  providerId: widget.providerId,
                  addToPlaylistDialog: _AddToPlaylistDialog(track: primary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MobileFavoriteRow extends ConsumerWidget {
  const _MobileFavoriteRow({
    required this.index,
    required this.track,
    required this.providerId,
    required this.onPlay,
    super.key,
  });

  final int index;
  final UnifiedFavoriteTrack track;
  final String? providerId;
  final Future<void> Function() onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    final variants = providerId == null
        ? track.variants
        : track.variants
            .where((item) => item.ref.providerId.value == providerId)
            .toList(growable: false);
    if (variants.isEmpty) return const SizedBox.shrink();

    final primary = variants.first;
    final selected = ref.watch(
      demoRepositoryProvider.select((repository) {
        final currentRef = repository.queue.current?.track.ref;
        return currentRef != null &&
            variants.any((variant) => variant.ref == currentRef);
      }),
    );
    final artwork = track.variants
        .firstWhere((variant) => variant.artwork != null, orElse: () => primary)
        .artwork;

    return MeloMobileTrackRow(
      index: index,
      title: track.title,
      artists: track.artists,
      artwork: artwork,
      duration: track.duration,
      isActive: selected,
      onTap: () {
        if (selected) {
          unawaited(repository.playOrToggleUnifiedTrack(track));
        } else {
          unawaited(onPlay());
        }
      },
      trailing: MeloMobileTrackTrailing(
        providerIcon: providerId == null
            ? MeloPlatformIcon(providerId: primary.ref.providerId)
            : null,
        durationLabel: _formatMobileDuration(track.duration),
        actions: [
          MeloTrackMoreMenu(
            unifiedTrack: track,
            providerId: providerId,
          ),
        ],
      ),
    );
  }
}

String _formatMobileDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
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
                      MeloSnackbar.show(
                        context: context,
                        message: '已加入“${playlist.name}”。',
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

  Future<String?> _askForPlaylistName(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => MeloDialogControllerWrapper(
        builder: (context, controller) => AlertDialog(
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
      ),
    );
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


