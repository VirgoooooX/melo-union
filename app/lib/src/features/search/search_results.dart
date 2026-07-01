part of 'search_page.dart';

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.query,
    required this.selectedSource,
  });

  final String query;
  final String selectedSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    return FutureBuilder<List<ProviderSearchResults>>(
      future: repository.search(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return MeloErrorState(message: '搜索失败：${snapshot.error}');
        }
        final groups = snapshot.data ?? const <ProviderSearchResults>[];
        final filtered = selectedSource == 'all'
            ? groups
            : groups
                .where((group) => group.provider.id.value == selectedSource)
                .toList(growable: false);
        final count =
            filtered.fold<int>(0, (sum, group) => sum + group.tracks.length);
        if (count == 0) {
          return Center(
            child: Text(
              '没有找到“$query”相关的结果。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textSecondary,
                  ),
            ),
          );
        }
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '找到 $count 首相关歌曲',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MeloColors.textSecondary,
                    ),
              ),
            ),
            for (final group in filtered) ...[
              _SourceResultSection(group: group),
              const SizedBox(height: 18),
            ],
          ],
        );
      },
    );
  }
}

class _SourceResultSection extends ConsumerWidget {
  const _SourceResultSection({required this.group});

  final ProviderSearchResults group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerName = meloProviderPresentation(
      group.provider.id,
      displayName: group.provider.displayName,
    ).fullName;
    return Container(
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.lg,
        border: Border.all(color: MeloColors.border),
        boxShadow: MeloShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                MeloSourceBadge(providerId: group.provider.id),
                const SizedBox(width: 8),
                Text(
                  providerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '${group.tracks.length} 首',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: MeloColors.border),
          for (final track in group.tracks)
            _SearchTrackRow(track: track, providerName: providerName),
        ],
      ),
    );
  }
}

class _SearchTrackRow extends ConsumerWidget {
  const _SearchTrackRow({
    required this.track,
    required this.providerName,
  });

  final SourceTrack track;
  final String providerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    final currentRef = ref.watch(
      demoRepositoryProvider.select((r) => r.queue.current?.track.ref),
    );
    final selected = currentRef == track.ref;
    return MeloInteractiveRow(
      selected: selected,
      onDoubleTap:
          track.isPlayable ? () => repository.playOrToggleTrack(track) : null,
      builder: (context, hovered) => Row(
        children: [
          SizedBox(
            width: 32,
            child: Icon(
              selected ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
              size: 18,
              color: selected
                  ? MeloColors.primary700
                  : hovered
                      ? MeloColors.primary700
                      : MeloColors.textTertiary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                MeloTrackCover(
                  seed: track.title,
                  artwork: track.artwork,
                  isActive: selected,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SearchTrackTitleBlock(
                    title: track.title,
                    artists: track.artists,
                    active: selected,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              track.album ?? providerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          MeloFavoriteButton(track: track),
          MeloTrackMoreMenu(track: track),
        ],
      ),
    );
  }
}

class _SearchTrackTitleBlock extends StatelessWidget {
  const _SearchTrackTitleBlock({
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
