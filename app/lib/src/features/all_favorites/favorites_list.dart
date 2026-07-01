part of 'all_favorites_page.dart';

class _FavoritesLibraryPanel extends ConsumerStatefulWidget {
  const _FavoritesLibraryPanel({
    required this.selectedProviderId,
    required this.query,
    required this.sort,
  });

  final String? selectedProviderId;
  final String query;
  final _FavoriteSort sort;

  @override
  ConsumerState<_FavoritesLibraryPanel> createState() => _FavoritesLibraryPanelState();
}

class _FavoritesLibraryPanelState extends ConsumerState<_FavoritesLibraryPanel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(allFavoritesProvider);
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MeloColors.surface,
          borderRadius: MeloRadii.sm,
          border: Border.all(color: MeloColors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availableHeight = constraints.maxHeight;
            // The non-list height is:
            // TableHeader: 42, Divider: 1. Total = 43
            final double availableListHeight = availableHeight - 43;
            final double listUsableHeight = availableListHeight - 8.0;
            final int maxRowsThatFit = !availableHeight.isFinite
                ? 6
                : listUsableHeight <= 0
                    ? 1
                    : (listUsableHeight / (MeloListMetrics.rowHeight + 1))
                        .floor()
                        .clamp(1, 10000);

            return favorites.when(
              loading: () => _FavoritesLoadingState(
                skeletonCount: maxRowsThatFit,
              ),
              error: (error, _) => MeloErrorState(
                message: '喜欢列表加载失败：$error',
                onRetry: () => ref.invalidate(allFavoritesProvider),
              ),
              data: (tracks) {
                final visible = _filterAndSort(tracks);
                if (visible.isEmpty) {
                  return const Column(
                    children: [
                      _FavoritesTableHeader(),
                      Divider(height: 1, color: MeloColors.border),
                      Expanded(
                        child: MeloEmptyState(
                          icon: Icons.favorite_border_rounded,
                          title: '没有找到匹配的喜欢歌曲',
                          subtitle: '换一个关键词，或切换到其他音乐来源试试。',
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    const _FavoritesTableHeader(),
                    const Divider(height: 1, color: MeloColors.border),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, color: MeloColors.border),
                          ),
                          itemBuilder: (context, index) => _FavoriteRow(
                            index: index + 1,
                            track: visible[index],
                            providerId: widget.selectedProviderId,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<UnifiedFavoriteTrack> _filterAndSort(
    List<UnifiedFavoriteTrack> tracks,
  ) {
    final visible = tracks.where((track) {
      final providerMatch = widget.selectedProviderId == null ||
          track.variants
              .any((item) => item.ref.providerId.value == widget.selectedProviderId);
      final queryMatch = widget.query.isEmpty ||
          '${track.title} ${track.artists.join(' ')} ${track.variants.map((item) => item.album ?? '').join(' ')}'
              .toLowerCase()
              .contains(widget.query);
      return providerMatch && queryMatch;
    }).toList(growable: false);

    final sorted = List<UnifiedFavoriteTrack>.from(visible);
    switch (widget.sort) {
      case _FavoriteSort.recent:
        break;
      case _FavoriteSort.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case _FavoriteSort.artist:
        sorted.sort(
          (a, b) => a.artists.join(' ').toLowerCase().compareTo(
                b.artists.join(' ').toLowerCase(),
              ),
        );
        break;
      case _FavoriteSort.duration:
        sorted.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }
    return sorted;
  }
}

class _FavoritesTableHeader extends StatelessWidget {
  const _FavoritesTableHeader();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: MeloColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        );
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: MeloColors.surfaceMuted,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#',
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text('歌曲', style: labelStyle),
          ),
          Expanded(flex: 3, child: Text('专辑', style: labelStyle)),
          SizedBox(
            width: 132,
            child: Text(
              '来源',
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '收藏',
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '操作',
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesLoadingState extends StatelessWidget {
  const _FavoritesLoadingState({this.skeletonCount = 6});

  final int skeletonCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _FavoritesTableHeader(),
        const Divider(height: 1, color: MeloColors.border),
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: skeletonCount,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: MeloColors.border),
            ),
            itemBuilder: (_, __) => const _FavoriteRowSkeleton(),
          ),
        ),
      ],
    );
  }
}

class _FavoriteRowSkeleton extends StatelessWidget {
  const _FavoriteRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MeloListMetrics.rowHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: MeloListMetrics.rowHorizontalPadding,
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _SkeletonBox(
                  width: MeloListMetrics.trackCoverSize,
                  height: MeloListMetrics.trackCoverSize,
                  radius: MeloRadii.sm,
                ),
                const SizedBox(width: 12),
                const Expanded(child: _SkeletonTextGroup()),
              ],
            ),
          ),
          const Expanded(flex: 3, child: _SkeletonTextGroup(short: true)),
          const SizedBox(
            width: 132,
            child: Center(
              child: _SkeletonBox(
                width: 64,
                height: 20,
                radius: MeloRadii.pill,
              ),
            ),
          ),
          const SizedBox(width: 64),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _SkeletonTextGroup extends StatelessWidget {
  const _SkeletonTextGroup({this.short = false});
  final bool short;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(
          width: short ? 76 : 144,
          height: 13,
          radius: MeloRadii.sm,
        ),
        const SizedBox(height: 8),
        _SkeletonBox(
          width: short ? 48 : 96,
          height: 10,
          radius: MeloRadii.sm,
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: MeloColors.border.withValues(alpha: .55),
        borderRadius: radius,
      ),
    );
  }
}
