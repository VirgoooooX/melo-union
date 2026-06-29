part of 'all_favorites_page.dart';

class _FavoritesLibraryPanel extends ConsumerWidget {
  const _FavoritesLibraryPanel({
    required this.selectedProviderId,
    required this.query,
    required this.sort,
  });

  final String? selectedProviderId;
  final String query;
  final _FavoriteSort sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(allFavoritesProvider);
    return Container(
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.lg,
        border: Border.all(color: MeloColors.border),
        boxShadow: MeloShadows.card,
      ),
      child: favorites.when(
        loading: () => const _FavoritesLoadingState(),
        error: (error, _) => _FavoritesErrorState(
          message: '喜欢列表加载失败：$error',
          onRetry: () => ref.invalidate(allFavoritesProvider),
        ),
        data: (tracks) {
          final visible = _filterAndSort(tracks);
          return Column(
            children: [
              _FavoritesTableHeader(
                count: visible.length,
                sourceCount: visible
                    .expand((track) => track.variants)
                    .map((variant) => variant.ref.providerId.value)
                    .toSet()
                    .length,
              ),
              const Divider(height: 1, color: MeloColors.border),
              Expanded(
                child: visible.isEmpty
                    ? const _FavoritesEmptyState()
                    : Scrollbar(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, color: MeloColors.border),
                          ),
                          itemBuilder: (context, index) => _FavoriteRow(
                            index: index + 1,
                            track: visible[index],
                            providerId: selectedProviderId,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<UnifiedFavoriteTrack> _filterAndSort(
    List<UnifiedFavoriteTrack> tracks,
  ) {
    final visible = tracks.where((track) {
      final providerMatch = selectedProviderId == null ||
          track.variants
              .any((item) => item.ref.providerId.value == selectedProviderId);
      final queryMatch = query.isEmpty ||
          '${track.title} ${track.artists.join(' ')} ${track.variants.map((item) => item.album ?? '').join(' ')}'
              .toLowerCase()
              .contains(query);
      return providerMatch && queryMatch;
    }).toList(growable: false);

    final sorted = List<UnifiedFavoriteTrack>.from(visible);
    switch (sort) {
      case _FavoriteSort.recent:
        break;
      case _FavoriteSort.title:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case _FavoriteSort.artist:
        sorted.sort(
          (a, b) => a.artists.join(' ').toLowerCase().compareTo(
                b.artists.join(' ').toLowerCase(),
              ),
        );
      case _FavoriteSort.duration:
        sorted.sort((a, b) => a.duration.compareTo(b.duration));
    }
    return sorted;
  }
}

class _FavoritesTableHeader extends StatelessWidget {
  const _FavoritesTableHeader({
    required this.count,
    required this.sourceCount,
  });

  final int count;
  final int sourceCount;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: MeloColors.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        );
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: MeloColors.surfaceMuted,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(width: 38, child: Text('#', style: labelStyle)),
          const SizedBox(width: 58),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('歌曲', style: labelStyle),
                const SizedBox(height: 2),
                Text(
                  '$count 首 · $sourceCount 个来源',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.textTertiary,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text('专辑', style: labelStyle)),
          SizedBox(width: 132, child: Text('来源', style: labelStyle)),
          SizedBox(width: 58, child: Text('时长', style: labelStyle)),
          const SizedBox(width: 46),
        ],
      ),
    );
  }
}

class _FavoritesLoadingState extends StatelessWidget {
  const _FavoritesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _FavoritesTableHeader(count: 0, sourceCount: 0),
        const Divider(height: 1, color: MeloColors.border),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: 6,
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
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          const SizedBox(width: 30),
          _SkeletonBox(width: 46, height: 46, radius: MeloRadii.md),
          const SizedBox(width: 12),
          const Expanded(flex: 4, child: _SkeletonTextGroup()),
          const Expanded(flex: 2, child: _SkeletonTextGroup(short: true)),
          const SizedBox(width: 132, child: _SkeletonBox(width: 64, height: 20, radius: MeloRadii.pill)),
          const SizedBox(width: 58),
          const SizedBox(width: 46),
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
        _SkeletonBox(width: short ? 76 : 144, height: 13, radius: MeloRadii.sm),
        const SizedBox(height: 8),
        _SkeletonBox(width: short ? 48 : 96, height: 10, radius: MeloRadii.sm),
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
        color: MeloColors.border.withOpacity(.55),
        borderRadius: radius,
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: MeloColors.primary50,
              borderRadius: MeloRadii.lg,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: MeloColors.primary700,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '没有找到匹配的喜欢歌曲',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '换一个关键词，或切换到其他音乐来源试试。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MeloColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesErrorState extends StatelessWidget {
  const _FavoritesErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: MeloColors.textTertiary,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
