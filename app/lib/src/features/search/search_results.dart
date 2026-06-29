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
    final repository = ref.watch(demoRepositoryProvider);
    return FutureBuilder<List<ProviderSearchResults>>(
      future: repository.search(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('搜索失败：${snapshot.error}'));
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
    final providerName = _displayProviderName(group.provider.id);
    return Container(
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.lg,
        border: Border.all(color: MeloColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                _SourcePill(providerId: group.provider.id),
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
    final repository = ref.watch(demoRepositoryProvider);
    final availability =
        repository.favoriteWriteAvailability(track.ref.providerId);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _SearchCover(seed: track.title),
      title: Text(
        track.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle:
          Text('${track.artists.join(' / ')} · ${track.album ?? providerName}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: track.isPlayable ? '播放' : '当前不可播放',
            onPressed:
                track.isPlayable ? () => repository.playTrack(track) : null,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
          Tooltip(
            message: availability.reason ?? (track.isFavorited ? '取消喜欢' : '喜欢'),
            child: IconButton(
              onPressed: availability.isEnabled
                  ? () async {
                      try {
                        await repository.toggleFavorite(
                          track: track,
                          liked: !track.isFavorited,
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
                track.isFavorited
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: track.isFavorited
                    ? MeloColors.favorite
                    : MeloColors.textTertiary,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '更多',
            onSelected: (value) {
              if (value == 'playlist') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('加入本地歌单操作将在下个交互迭代接入。')),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'playlist', child: Text('加入本地歌单')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchCover extends StatelessWidget {
  const _SearchCover({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final hue = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: MeloRadii.sm,
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .52, .64).toColor(),
            HSLColor.fromAHSL(1, (hue + 42) % 360, .54, .42).toColor(),
          ],
        ),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.white),
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.providerId});

  final ProviderId providerId;

  @override
  Widget build(BuildContext context) {
    final netease = providerId.value.contains('aurora');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: netease ? MeloColors.neteaseBackground : MeloColors.qqBackground,
        borderRadius: MeloRadii.sm,
      ),
      child: Text(
        _displayProviderName(providerId),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: netease
                  ? MeloColors.neteaseForeground
                  : MeloColors.qqForeground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
