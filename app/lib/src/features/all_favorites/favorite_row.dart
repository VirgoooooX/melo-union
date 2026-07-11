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
    final playNextStatus = ref.watch(demoRepositoryProvider.select(
      (repository) => repository.playNextStatusForVariants(
        variants,
        queueSurface: false,
      ),
    ));
    final isPlaying = currentRef != null &&
        variants.any((variant) => variant.ref == currentRef);
    final hasFavorite = variants.any((variant) => variant.isFavorited);
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
              width: 64,
              child: Center(
                child: variants.length > 1
                    ? IconButton(
                        tooltip: '管理多个来源的收藏状态',
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
                      )
                    : MeloFavoriteButton(track: primary),
              ),
            ),
            SizedBox(
              width: 40,
              child: MeloPlayNextButton(
                status: playNextStatus,
                onPressed: () async {
                  await repository.playUnifiedTrackNext(widget.track);
                  if (context.mounted) {
                    MeloSnackbar.show(
                      context: context,
                      message: '已设为下一首：${widget.track.title}',
                    );
                  }
                },
              ),
            ),
            SizedBox(
              width: 56,
              child: Center(
                child: MeloTrackMoreMenu(
                  track: primary,
                  addToPlaylistDialog: _AddToPlaylistDialog(track: primary),
                ),
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
    }
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
    final playNextStatus = ref.watch(demoRepositoryProvider.select(
      (repository) => repository.playNextStatusForVariants(
        variants,
        queueSurface: false,
      ),
    ));
    final selected = ref.watch(
      demoRepositoryProvider.select((repository) {
        final currentRef = repository.queue.current?.track.ref;
        return currentRef != null &&
            variants.any((variant) => variant.ref == currentRef);
      }),
    );
    final hasFavorite = variants.any((variant) => variant.isFavorited);
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
          MeloPlayNextButton(
            status: playNextStatus,
            onPressed: () async {
              await repository.playUnifiedTrackNext(track);
              if (context.mounted) {
                MeloSnackbar.show(
                  context: context,
                  message: '已设为下一首：${track.title}',
                );
              }
            },
            size: 19,
          ),
          _MobileFavoriteActionsButton(
            track: track,
            primary: primary,
            variants: variants,
            hasFavorite: hasFavorite,
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

enum _MobileFavoriteAction { favorite, appendToQueue, download, playlist }

class _MobileFavoriteActionsButton extends ConsumerWidget {
  const _MobileFavoriteActionsButton({
    required this.track,
    required this.primary,
    required this.variants,
    required this.hasFavorite,
  });

  final UnifiedFavoriteTrack track;
  final SourceTrack primary;
  final List<SourceTrack> variants;
  final bool hasFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    return PopupMenuButton<_MobileFavoriteAction>(
      tooltip: '更多操作',
      icon: const Icon(Icons.more_horiz_rounded, size: 22),
      offset: const Offset(0, 42),
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration.zero,
        reverseDuration: Duration.zero,
        curve: Curves.linear,
        reverseCurve: Curves.linear,
      ),
      onSelected: (action) async {
        switch (action) {
          case _MobileFavoriteAction.favorite:
            if (variants.length > 1) {
              await showDialog<void>(
                context: context,
                builder: (context) => _FavoriteSourceDialog(
                  track: track,
                  variants: variants,
                ),
              );
              return;
            }
            await repository.toggleFavorite(
              track: primary,
              liked: !primary.isFavorited,
            );
            break;
          case _MobileFavoriteAction.appendToQueue:
            repository.enqueueTrack(primary);
            MeloSnackbar.show(
              context: context,
              message: '已添加到播放队列末尾。',
            );
            break;
          case _MobileFavoriteAction.download:
            final quality = await _chooseMobileDownloadQuality(context);
            if (quality == null || !context.mounted) return;
            MeloSnackbar.show(
              context: context,
              message: '开始下载：${primary.title}',
            );
            unawaited(
              repository.downloadTrack(primary, quality: quality).then(
                (status) {
                  if (!context.mounted) return;
                  MeloSnackbar.show(
                    context: context,
                    message: switch (status) {
                      DownloadStatus.completed => '已下载到本地。',
                      DownloadStatus.resolving ||
                      DownloadStatus.downloading =>
                        '正在下载：${primary.title}',
                      DownloadStatus.queued => '已开始下载。',
                      DownloadStatus.paused => '下载已暂停。',
                      DownloadStatus.failed => '下载失败，请在下载页重试。',
                      DownloadStatus.cancelled => '下载已取消。',
                      null => '当前来源暂不支持下载。',
                    },
                  );
                },
              ),
            );
            break;
          case _MobileFavoriteAction.playlist:
            await showDialog<void>(
              context: context,
              builder: (context) => MeloAddToPlaylistDialog(track: primary),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MobileFavoriteAction.favorite,
          child: _MobileActionItem(
            icon: hasFavorite ? Icons.favorite_rounded : Icons.favorite_border,
            label: variants.length > 1
                ? '管理喜欢'
                : (primary.isFavorited ? '取消喜欢' : '喜欢'),
            color: hasFavorite ? MeloColors.favorite : null,
          ),
        ),
        const PopupMenuItem(
          value: _MobileFavoriteAction.appendToQueue,
          child: _MobileActionItem(
            icon: Icons.queue_music_rounded,
            label: '添加到队列末尾',
          ),
        ),
        if (repository.canDownloadTrack(primary))
          const PopupMenuItem(
            value: _MobileFavoriteAction.download,
            child: _MobileActionItem(
              icon: Icons.download_rounded,
              label: '下载',
            ),
          ),
        const PopupMenuItem(
          value: _MobileFavoriteAction.playlist,
          child: _MobileActionItem(
            icon: Icons.playlist_add_rounded,
            label: '加入本地歌单',
          ),
        ),
      ],
    );
  }
}

Future<AudioQuality?> _chooseMobileDownloadQuality(BuildContext context) {
  return showDialog<AudioQuality>(
    context: context,
    animationStyle: const AnimationStyle(
      duration: Duration.zero,
      reverseDuration: Duration.zero,
    ),
    builder: (context) => SimpleDialog(
      title: const Text('选择下载音质'),
      children: [
        for (final quality in AudioQuality.values)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, quality),
            child: Row(
              children: [
                const Icon(Icons.high_quality_rounded, size: 18),
                const SizedBox(width: 10),
                Text(_favoriteAudioQualityLabel(quality)),
              ],
            ),
          ),
      ],
    ),
  );
}

String _favoriteAudioQualityLabel(AudioQuality quality) => switch (quality) {
      AudioQuality.low => '标准',
      AudioQuality.standard => '较高',
      AudioQuality.high => '极高',
      AudioQuality.lossless => '无损',
    };

class _MobileActionItem extends StatelessWidget {
  const _MobileActionItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
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
          MeloFavoriteButton(
            track: liveVariant,
            showSnackbar: false,
          ),
        ],
      ),
    );
  }
}
