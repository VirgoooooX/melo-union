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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final variants = widget.providerId == null
        ? widget.track.variants
        : widget.track.variants
            .where((item) => item.ref.providerId.value == widget.providerId)
            .toList(growable: false);
    if (variants.isEmpty) return const SizedBox.shrink();

    final primary = variants.first;
    final currentRef = repository.queue.current?.track.ref;
    final isPlaying = currentRef != null &&
        variants.any((variant) => variant.ref == currentRef);
    final hasFavorite = variants.any((variant) => variant.isFavorited);
    final rowBackground = isPlaying
        ? MeloColors.primary50
        : _hovered
            ? MeloColors.surfaceHover
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => repository.playUnifiedTrack(widget.track),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: rowBackground,
              border: Border(
                left: BorderSide(
                  color: isPlaying ? MeloColors.primary500 : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    isPlaying ? '▶' : '${widget.index}'.padLeft(2, '0'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isPlaying
                              ? MeloColors.primary700
                              : MeloColors.textTertiary,
                          fontWeight:
                              isPlaying ? FontWeight.w800 : FontWeight.w600,
                        ),
                  ),
                ),
                _TrackCover(seed: widget.track.title, isPlaying: isPlaying),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _TrackIdentity(
                    track: widget.track,
                    sourceCount: variants.length,
                    isPlaying: isPlaying,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    primary.album ?? '—',
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final item in variants)
                          _SourceTag(provider: item.ref.providerId),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 58,
                  child: Text(
                    formatDuration(widget.track.duration),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                SizedBox(
                  width: 46,
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
              ],
            ),
          ),
        ),
      ),
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

    await _toggleSingle(context, repository, variants.first);
  }

  Future<void> _toggleSingle(
    BuildContext context,
    DemoRepository repository,
    SourceTrack source,
  ) async {
    try {
      await repository.toggleFavorite(
        track: source,
        liked: !source.isFavorited,
      );
    } on ProviderException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _TrackIdentity extends StatelessWidget {
  const _TrackIdentity({
    required this.track,
    required this.sourceCount,
    required this.isPlaying,
  });

  final UnifiedFavoriteTrack track;
  final int sourceCount;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isPlaying
                            ? MeloColors.primary700
                            : MeloColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (sourceCount > 1) ...[
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: MeloColors.primary50,
                    borderRadius: MeloRadii.pill,
                  ),
                  child: Text(
                    '$sourceCount 个来源',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.primary700,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            track.artists.join(' / '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MeloColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      );
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
    final availability =
        repository.favoriteWriteAvailability(variant.ref.providerId);
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
          _SourceTag(provider: variant.ref.providerId),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              variant.isFavorited ? '已收藏到这个来源' : '尚未收藏到这个来源',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Tooltip(
            message: canWrite
                ? (variant.isFavorited ? '取消喜欢' : '喜欢')
                : availability.reason ?? '此来源无法写回收藏',
            child: IconButton(
              onPressed: canWrite
                  ? () async {
                      try {
                        await repository.toggleFavorite(
                          track: variant,
                          liked: !variant.isFavorited,
                        );
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
                variant.isFavorited
                    ? Icons.favorite_rounded
                    : canWrite
                        ? Icons.favorite_border_rounded
                        : Icons.lock_outline_rounded,
                color: variant.isFavorited
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
