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
                    ),
                  )
                : _SilentRefreshList(
                    tracks: tracks,
                    providerId: widget.selectedProviderId,
                    scrollController: _scrollController,
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

/// AnimatedList wrapper that applies diff-based insert/remove animations
/// when [tracks] changes, enabling silent refresh with visual transitions.
///
/// Only handles pure additions and removals (the common case for favorites).
/// Sort/query/filter changes fall through to a non-animated rebuild.
class _SilentRefreshList extends StatefulWidget {
  const _SilentRefreshList({
    required this.tracks,
    required this.providerId,
    required this.scrollController,
  });

  final List<UnifiedFavoriteTrack> tracks;
  final String? providerId;
  final ScrollController scrollController;

  @override
  State<_SilentRefreshList> createState() => _SilentRefreshListState();
}

class _SilentRefreshListState extends State<_SilentRefreshList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<UnifiedFavoriteTrack> _items = [];

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.tracks);
  }

  @override
  void didUpdateWidget(_SilentRefreshList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.tracks, widget.tracks)) return;
    _applyDiff(widget.tracks);
  }

  void _applyDiff(List<UnifiedFavoriteTrack> newTracks) {
    final newIds = newTracks.map((t) => t.unifiedId).toList();
    final oldIds = _items.map((t) => t.unifiedId).toList();
    if (_listEquals(newIds, oldIds)) return;

    // If items changed in more than simple add/remove (sort, filter, etc.),
    // fall back to a non-animated rebuild.
    final added = newIds.toSet().difference(oldIds.toSet());
    final removed = oldIds.toSet().difference(newIds.toSet());
    if (added.length + removed.length !=
        (newIds.length - oldIds.length).abs()) {
      // Complex change — rebuild silently.
      _items
        ..clear()
        ..addAll(newTracks);
      return;
    }

    // 1. Remove items (reverse order to keep indices valid).
    for (int i = _items.length - 1; i >= 0; i--) {
      if (!newIds.contains(_items[i].unifiedId)) {
        final removed = _items[i];
        _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (ctx, animation) => _AnimatedRemovingRow(
            animation: animation,
            track: removed,
          ),
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    // 2. Insert new items.
    final currentIds = _items.map((t) => t.unifiedId).toSet();
    for (int i = 0; i < newTracks.length; i++) {
      if (!currentIds.contains(newTracks[i].unifiedId)) {
        _items.insert(i, newTracks[i]);
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList.separated(
      key: _listKey,
      controller: widget.scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      initialItemCount: _items.length,
      separatorBuilder: (context, index, animation) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: MeloColors.border),
      ),
      removedSeparatorBuilder: (context, index, animation) =>
          const SizedBox.shrink(),
      itemBuilder: (context, index, animation) {
        if (index >= _items.length) return const SizedBox.shrink();
        return _FavoriteRow(
          index: index + 1,
          track: _items[index],
          providerId: widget.providerId,
        );
      },
    );
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _MobileFavoritesLibrary extends ConsumerWidget {
  const _MobileFavoritesLibrary({
    required this.selectedProviderId,
    required this.sort,
  });

  final String? selectedProviderId;
  final _FavoriteSort sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(allFavoritesProvider);
    final cached = ref.read(demoRepositoryProvider).lastFavoritesData;
    return favorites.when(
      loading: () {
        if (cached != null && cached.isNotEmpty) {
          return _buildList(context, _filterAndSort(cached));
        }
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, _) => MeloErrorState(
        message: '喜欢列表加载失败：$error',
        onRetry: () => ref.invalidate(allFavoritesProvider),
      ),
      data: (tracks) => _buildList(context, _filterAndSort(tracks)),
    );
  }

  Widget _buildList(BuildContext context, List<UnifiedFavoriteTrack> tracks) {
    if (tracks.isEmpty) {
      return const MeloEmptyState(
        icon: Icons.favorite_border_rounded,
        title: '没有找到匹配的喜欢歌曲',
        subtitle: '切换来源或刷新后再试。',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 156),
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: tracks.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: MeloColors.border),
      itemBuilder: (context, index) => RepaintBoundary(
        child: _MobileFavoriteRow(
          index: index + 1,
          track: tracks[index],
          providerId: selectedProviderId,
        ),
      ),
    );
  }

  List<UnifiedFavoriteTrack> _filterAndSort(List<UnifiedFavoriteTrack> tracks) {
    final visible = tracks.where((track) {
      return selectedProviderId == null ||
          track.variants.any(
            (item) => item.ref.providerId.value == selectedProviderId,
          );
    }).toList(growable: false);
    switch (sort) {
      case _FavoriteSort.recent:
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
}

/// Fade-out + height-collapse animation for removed rows.
class _AnimatedRemovingRow extends StatelessWidget {
  const _AnimatedRemovingRow({
    required this.animation,
    required this.track,
  });

  final Animation<double> animation;
  final UnifiedFavoriteTrack track;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: animation,
        child: _FavoriteRow(
          index: 0,
          track: track,
          providerId: null,
        ),
      ),
    );
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
