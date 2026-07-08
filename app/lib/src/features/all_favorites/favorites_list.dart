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
  ConsumerState<_FavoritesLibraryPanel> createState() =>
      _FavoritesLibraryPanelState();
}

class _FavoritesLibraryPanelState
    extends ConsumerState<_FavoritesLibraryPanel> {
  late final ScrollController _scrollController;
  bool _hasAnimatedListEverRun = false;

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
    final cached = ref.read(demoRepositoryProvider).lastFavoritesData;
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

            return favorites.when(
              loading: () {
                // Silent refresh: show cached data from repository (app-lifetime).
                if (cached != null && cached.isNotEmpty) {
                  return _buildTrackList(cached, isInitialRender: false);
                }
                return _buildSkeleton(availableHeight);
              },
              error: (error, _) => MeloErrorState(
                message: '喜欢列表加载失败：$error',
                onRetry: () => ref.invalidate(allFavoritesProvider),
              ),
              data: (tracks) {
                final visible = _filterAndSort(tracks);
                final isFirst = !_hasAnimatedListEverRun;
                if (isFirst) _hasAnimatedListEverRun = true;
                return _buildTrackList(visible, isInitialRender: isFirst);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton(double availableHeight) {
    final double availableListHeight = availableHeight - 43;
    final double listUsableHeight = availableListHeight - 8.0;
    final int maxRowsThatFit = !availableHeight.isFinite
        ? 6
        : listUsableHeight <= 0
            ? 1
            : (listUsableHeight / (MeloListMetrics.rowHeight + 1))
                .floor()
                .clamp(1, 10000);
    return _FavoritesLoadingState(skeletonCount: maxRowsThatFit);
  }

  Widget _buildTrackList(List<UnifiedFavoriteTrack> tracks,
      {required bool isInitialRender}) {
    if (tracks.isEmpty) {
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
            child: isInitialRender
                ? ListView.separated(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: tracks.length,
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: MeloColors.border),
                    ),
                    itemBuilder: (context, index) => _FavoriteRow(
                      index: index + 1,
                      track: tracks[index],
                      providerId: widget.selectedProviderId,
                      onPlay: () => ref
                          .read(demoRepositoryProvider)
                          .playUnifiedTracksFrom(
                            tracks,
                            tracks[index],
                            providerId: widget.selectedProviderId,
                          ),
                    ),
                  )
                : _SilentRefreshList(
                    tracks: tracks,
                    providerId: widget.selectedProviderId,
                    scrollController: _scrollController,
                    onPlay: (tracks, selected, providerId) =>
                        ref.read(demoRepositoryProvider).playUnifiedTracksFrom(
                              tracks,
                              selected,
                              providerId: providerId,
                            ),
                  ),
          ),
        ),
      ],
    );
  }

  List<UnifiedFavoriteTrack> _filterAndSort(
    List<UnifiedFavoriteTrack> tracks,
  ) {
    final visible = tracks.where((track) {
      final providerMatch = widget.selectedProviderId == null ||
          track.variants.any(
              (item) => item.ref.providerId.value == widget.selectedProviderId);
      final queryMatch = widget.query.isEmpty ||
          '${track.title} ${track.artists.join(' ')} ${track.variants.map((item) => item.album ?? '').join(' ')}'
              .toLowerCase()
              .contains(widget.query);
      return providerMatch && queryMatch;
    }).toList(growable: false);

    final sorted = List<UnifiedFavoriteTrack>.from(visible);
    switch (widget.sort) {
      case _FavoriteSort.recent:
        if (widget.selectedProviderId != null) {
          sorted.sort(
            (a, b) => _providerLikedAt(b, widget.selectedProviderId!)
                .compareTo(_providerLikedAt(a, widget.selectedProviderId!)),
          );
        }
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

  DateTime _providerLikedAt(UnifiedFavoriteTrack track, String providerId) {
    DateTime? best;
    for (final variant in track.variants) {
      if (variant.ref.providerId.value != providerId) continue;
      final likedAt = variant.likedAt;
      if (likedAt != null && (best == null || likedAt.isAfter(best))) {
        best = likedAt;
      }
    }
    return best ?? DateTime(1900);
  }
}

class _SilentRefreshList extends StatefulWidget {
  const _SilentRefreshList({
    required this.tracks,
    required this.providerId,
    required this.scrollController,
    required this.onPlay,
  });

  final List<UnifiedFavoriteTrack> tracks;
  final String? providerId;
  final ScrollController scrollController;
  final Future<void> Function(
    List<UnifiedFavoriteTrack> tracks,
    UnifiedFavoriteTrack selected,
    String? providerId,
  ) onPlay;

  @override
  State<_SilentRefreshList> createState() => _SilentRefreshListState();
}

class _SilentRefreshListState extends State<_SilentRefreshList> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: widget.scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: widget.tracks.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: MeloColors.border),
      ),
      itemBuilder: (context, index) {
        final track = widget.tracks[index];
        return KeyedSubtree(
          key: ValueKey(track.unifiedId),
          child: _FavoriteRow(
            index: index + 1,
            track: track,
            providerId: widget.providerId,
            onPlay: () => widget.onPlay(
              widget.tracks,
              track,
              widget.providerId,
            ),
          ),
        );
      },
    );
  }
}

class _MobileFavoritesLibrary extends ConsumerWidget {
  const _MobileFavoritesLibrary({
    required this.selectedProviderId,
    required this.sort,
    required this.query,
    required this.topPadding,
  });

  final String? selectedProviderId;
  final _FavoriteSort sort;
  final String query;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(allFavoritesProvider);
    final cached = ref.read(demoRepositoryProvider).lastFavoritesData;
    return favorites.when(
      loading: () {
        if (cached != null && cached.isNotEmpty) {
          return _buildList(context, ref, _filterAndSort(cached));
        }
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, _) => MeloErrorState(
        message: '喜欢列表加载失败：$error',
        onRetry: () => ref.invalidate(allFavoritesProvider),
      ),
      data: (tracks) => _buildList(context, ref, _filterAndSort(tracks)),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<UnifiedFavoriteTrack> tracks,
  ) {
    if (tracks.isEmpty) {
      return const MeloEmptyState(
        icon: Icons.favorite_border_rounded,
        title: '没有找到匹配的喜欢歌曲',
        subtitle: '切换来源或刷新后再试。',
      );
    }
    return ListView.builder(
      key: PageStorageKey<String>('mobile_favorites_$selectedProviderId'),
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 156),
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      scrollCacheExtent: const ScrollCacheExtent.pixels(192),
      itemExtentBuilder: (index, _) => index.isEven ? 64 : 8,
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      itemCount: tracks.length * 2 - 1,
      itemBuilder: (context, index) {
        if (index.isOdd) return const SizedBox(height: 8);
        final track = tracks[index ~/ 2];
        final repository = ref.read(demoRepositoryProvider);
        return _MobileFavoriteRow(
          key: ValueKey(track.unifiedId),
          index: index ~/ 2 + 1,
          track: track,
          providerId: selectedProviderId,
          onPlay: () => repository.playUnifiedTracksFrom(
            tracks,
            track,
            providerId: selectedProviderId,
          ),
        );
      },
    );
  }

  List<UnifiedFavoriteTrack> _filterAndSort(List<UnifiedFavoriteTrack> tracks) {
    final visible = tracks.where((track) {
      final providerMatch = selectedProviderId == null ||
          track.variants.any(
            (item) => item.ref.providerId.value == selectedProviderId,
          );
      final queryMatch = query.isEmpty ||
          '${track.title} ${track.artists.join(' ')} ${track.variants.map((item) => item.album ?? '').join(' ')}'
              .toLowerCase()
              .contains(query);
      return providerMatch && queryMatch;
    }).toList(growable: false);
    switch (sort) {
      case _FavoriteSort.recent:
        if (selectedProviderId != null) {
          visible.sort(
            (a, b) => _providerLikedAt(b, selectedProviderId!)
                .compareTo(_providerLikedAt(a, selectedProviderId!)),
          );
        }
        break;
      case _FavoriteSort.title:
        visible.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case _FavoriteSort.artist:
        visible.sort(
          (a, b) => a.artists
              .join(' ')
              .toLowerCase()
              .compareTo(b.artists.join(' ').toLowerCase()),
        );
        break;
      case _FavoriteSort.duration:
        visible.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }
    return visible;
  }

  DateTime _providerLikedAt(UnifiedFavoriteTrack track, String providerId) {
    DateTime? best;
    for (final variant in track.variants) {
      if (variant.ref.providerId.value != providerId) continue;
      final likedAt = variant.likedAt;
      if (likedAt != null && (best == null || likedAt.isAfter(best))) {
        best = likedAt;
      }
    }
    return best ?? DateTime(1900);
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
                width: 18,
                height: 18,
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
