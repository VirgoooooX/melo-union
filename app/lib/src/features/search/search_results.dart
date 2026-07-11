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
        final visibleGroups = filtered
            .where((group) => group.tracks.isNotEmpty)
            .toList(growable: false)
          ..sort(_compareProviderGroups);
        final count = visibleGroups.fold<int>(
            0, (sum, group) => sum + group.tracks.length);
        if (count == 0) {
          return _SearchEmptyState(query: query);
        }

        final compact = MediaQuery.sizeOf(context).width < 760;
        return ListView.separated(
          scrollCacheExtent: const ScrollCacheExtent.pixels(320),
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          padding: EdgeInsets.fromLTRB(0, compact ? 2 : 4, 0, 22),
          itemCount: visibleGroups.length + 1,
          separatorBuilder: (_, index) =>
              SizedBox(height: index == 0 ? 14 : (compact ? 14 : 18)),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _SearchSummary(
                count: count,
                sourceCount: visibleGroups.length,
              );
            }
            final group = visibleGroups[index - 1];
            return compact
                ? _MobileProviderResultSection(group: group)
                : _DesktopProviderResultSection(group: group);
          },
        );
      },
    );
  }
}

int _compareProviderGroups(ProviderSearchResults a, ProviderSearchResults b) {
  final aCatalog = _isCatalogProvider(a.provider);
  final bCatalog = _isCatalogProvider(b.provider);
  if (aCatalog != bCatalog) return aCatalog ? 1 : -1;
  return a.provider.displayName.compareTo(b.provider.displayName);
}

bool _isCatalogProvider(ProviderDescriptor provider) {
  final value = provider.id.value.toLowerCase();
  return value.contains('catalog') || value.contains('compass');
}

class _SearchSummary extends StatelessWidget {
  const _SearchSummary({required this.count, required this.sourceCount});

  final int count;
  final int sourceCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '找到 $count 首相关内容 · $sourceCount 个来源',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MeloColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '没有找到“$query”相关的结果。',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MeloColors.textSecondary,
            ),
      ),
    );
  }
}

class _MobileProviderResultSection extends StatelessWidget {
  const _MobileProviderResultSection({required this.group});

  final ProviderSearchResults group;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MeloColors.mobileSurfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MeloColors.mobileSurfaceBorder),
        boxShadow: MeloShadows.card,
      ),
      child: Column(
        children: [
          _ProviderSectionHeader(group: group, compact: true),
          const Divider(height: 1, color: MeloColors.border),
          for (var i = 0; i < group.tracks.length; i++) ...[
            _MobileSearchTrackRow(
              index: i + 1,
              track: group.tracks[i],
              provider: group.provider,
            ),
            if (i != group.tracks.length - 1)
              const Divider(
                height: 1,
                indent: 72,
                color: MeloColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _DesktopProviderResultSection extends StatelessWidget {
  const _DesktopProviderResultSection({required this.group});

  final ProviderSearchResults group;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProviderSectionHeader(group: group),
        for (var i = 0; i < group.tracks.length; i++)
          RepaintBoundary(
            child: _DesktopSearchTrackRow(
              index: i + 1,
              track: group.tracks[i],
              provider: group.provider,
            ),
          ),
      ],
    );
  }
}

class _ProviderSectionHeader extends StatelessWidget {
  const _ProviderSectionHeader({
    required this.group,
    this.compact = false,
  });

  final ProviderSearchResults group;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final presentation = meloProviderPresentation(
      group.provider.id,
      displayName: group.provider.displayName,
    );
    final catalog = _isCatalogProvider(group.provider);
    return Padding(
      padding:
          EdgeInsets.fromLTRB(14, compact ? 12 : 10, 14, compact ? 10 : 12),
      child: Row(
        children: [
          _ProviderLogoFrame(
              providerId: group.provider.id, size: compact ? 32 : 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentation.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: MeloColors.textPrimary,
                        fontSize: compact ? 15.5 : null,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (catalog) ...[
                  const SizedBox(height: 2),
                  Text(
                    '目录结果仅用于识别与整理',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textTertiary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ProviderCountPill(
            label: catalog
                ? '目录 · ${group.tracks.length}'
                : '${group.tracks.length} 首',
          ),
        ],
      ),
    );
  }
}

class _ProviderLogoFrame extends StatelessWidget {
  const _ProviderLogoFrame({required this.providerId, this.size = 32});

  final ProviderId providerId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MeloColors.primary50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MeloColors.primary100),
      ),
      alignment: Alignment.center,
      child: MeloPlatformIcon(providerId: providerId),
    );
  }
}

class _ProviderCountPill extends StatelessWidget {
  const _ProviderCountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: MeloColors.mobileSurfaceMuted,
        borderRadius: MeloRadii.pill,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MeloColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _MobileSearchTrackRow extends ConsumerWidget {
  const _MobileSearchTrackRow({
    required this.index,
    required this.track,
    required this.provider,
  });

  final int index;
  final SourceTrack track;
  final ProviderDescriptor provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    final selected = ref.watch(
      demoRepositoryProvider
          .select((r) => r.queue.current?.track.ref == track.ref),
    );
    final playable = track.isPlayable;
    return MeloMobileTrackRow(
      index: index,
      title: track.title,
      artists: track.artists,
      artwork: track.artwork,
      duration: track.duration,
      isActive: selected,
      onTap: playable ? () => repository.playOrToggleTrack(track) : null,
      trailing: MeloMobileTrackTrailing(
        duration: playable ? null : const _CatalogTag(),
        durationLabel: playable ? _formatSearchDuration(track.duration) : null,
        durationColor: MeloColors.textTertiary,
        durationFontWeight: FontWeight.w700,
        actions: [
          _SearchTrackActions(track: track),
        ],
      ),
    );
  }
}

class _DesktopSearchTrackRow extends ConsumerWidget {
  const _DesktopSearchTrackRow({
    required this.index,
    required this.track,
    required this.provider,
  });

  final int index;
  final SourceTrack track;
  final ProviderDescriptor provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    final selected = ref.watch(
      demoRepositoryProvider
          .select((r) => r.queue.current?.track.ref == track.ref),
    );
    final playable = track.isPlayable;
    final play = playable ? () => repository.playOrToggleTrack(track) : null;
    return MeloDesktopTrackRow(
      index: index,
      title: track.title,
      artists: track.artists,
      artwork: track.artwork,
      album: track.album ?? provider.displayName,
      isActive: selected,
      onDoubleTap: play,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!playable) ...[
            const _CatalogTag(),
            const SizedBox(width: 8),
          ],
          if (playable) ...[
            Text(_formatSearchDuration(track.duration)),
            const SizedBox(width: 8),
          ],
          _SearchTrackActions(track: track),
        ],
      ),
    );
  }
}

class _CatalogTag extends StatelessWidget {
  const _CatalogTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: MeloColors.mobileAccentSurface,
        borderRadius: MeloRadii.pill,
        border: Border.all(color: MeloColors.mobileAccentBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        '目录',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MeloColors.primary700,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _SearchTrackActions extends StatelessWidget {
  const _SearchTrackActions({required this.track});

  final SourceTrack track;

  @override
  Widget build(BuildContext context) {
    return MeloTrackMoreMenu(track: track);
  }
}

String _formatSearchDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
