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
        final entries = <_SearchResultEntry>[
          _SearchResultEntry.summary(count),
          for (final group in filtered) ...[
            _SearchResultEntry.header(group),
            for (final track in group.tracks)
              _SearchResultEntry.track(
                track,
                meloProviderPresentation(
                  group.provider.id,
                  displayName: group.provider.displayName,
                ).fullName,
              ),
            const _SearchResultEntry.gap(),
          ],
        ];
        return ListView.builder(
          scrollCacheExtent: const ScrollCacheExtent.pixels(720),
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return switch (entry.kind) {
              _SearchResultEntryKind.summary => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '找到 ${entry.count} 首相关歌曲',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  ),
                ),
              _SearchResultEntryKind.header => _SearchResultHeader(
                  group: entry.group!,
                ),
              _SearchResultEntryKind.track => RepaintBoundary(
                  child: _SearchTrackRow(
                    track: entry.track!,
                    providerName: entry.providerName!,
                  ),
                ),
              _SearchResultEntryKind.gap => const SizedBox(height: 18),
            };
          },
        );
      },
    );
  }
}

enum _SearchResultEntryKind { summary, header, track, gap }

class _SearchResultEntry {
  const _SearchResultEntry._({
    required this.kind,
    this.count,
    this.group,
    this.track,
    this.providerName,
  });

  const _SearchResultEntry.summary(int count)
      : this._(kind: _SearchResultEntryKind.summary, count: count);

  const _SearchResultEntry.header(ProviderSearchResults group)
      : this._(kind: _SearchResultEntryKind.header, group: group);

  const _SearchResultEntry.track(SourceTrack track, String providerName)
      : this._(
          kind: _SearchResultEntryKind.track,
          track: track,
          providerName: providerName,
        );

  const _SearchResultEntry.gap() : this._(kind: _SearchResultEntryKind.gap);

  final _SearchResultEntryKind kind;
  final int? count;
  final ProviderSearchResults? group;
  final SourceTrack? track;
  final String? providerName;
}

class _SearchResultHeader extends StatelessWidget {
  const _SearchResultHeader({required this.group});

  final ProviderSearchResults group;

  @override
  Widget build(BuildContext context) {
    final providerName = meloProviderPresentation(
      group.provider.id,
      displayName: group.provider.displayName,
    ).fullName;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: MeloColors.border),
        boxShadow: MeloShadows.card,
      ),
      child: Padding(
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
