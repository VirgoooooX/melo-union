part of 'local_playlists_page.dart';

class _PlaylistGrid extends ConsumerWidget {
  const _PlaylistGrid({required this.playlists});
  final List<LocalPlaylist> playlists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final width = MediaQuery.sizeOf(context).width;
    final count = width >= 1240
        ? 4
        : width >= 980
            ? 3
            : 2;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: .80,
      ),
      itemCount: playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const _CreatePlaylistCard();
        final playlist = playlists[index - 1];
        final selected = playlist.id == repository.selectedPlaylistId;
        return InkWell(
          onTap: () => repository.selectPlaylist(playlist.id),
          borderRadius: MeloRadii.lg,
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MeloColors.surface,
              borderRadius: MeloRadii.lg,
              border: Border.all(
                  color: selected ? MeloColors.primary500 : MeloColors.border),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: MeloRadii.md,
                    gradient: LinearGradient(
                        colors: [Color(0xFF3AAEAA), Color(0xFF5B7DBA)]),
                  ),
                  child: const Icon(Icons.queue_music_rounded,
                      size: 46, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${playlist.items.length} 首 · 混合',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: MeloColors.textSecondary)),
            ]),
          ),
        );
      },
    );
  }
}

class _CreatePlaylistCard extends StatelessWidget {
  const _CreatePlaylistCard();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: MeloColors.surfaceMuted,
            borderRadius: MeloRadii.lg,
            border:
                Border.all(color: MeloColors.border, style: BorderStyle.solid)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_circle_outline_rounded,
              size: 38, color: MeloColors.primary600),
          const SizedBox(height: 10),
          Text('新建本地歌单',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MeloColors.primary700, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _RemotePlaylistsPanel extends ConsumerWidget {
  const _RemotePlaylistsPanel({
    required this.providerId,
    required this.selectedPlaylistId,
    required this.onSelected,
    required this.onBack,
  });

  final ProviderId providerId;
  final String? selectedPlaylistId;
  final ValueChanged<String> onSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    return FutureBuilder<List<ProviderPlaylist>>(
      future: repository.loadProviderPlaylists(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('歌单加载失败：${snapshot.error}'));
        }
        final playlists = snapshot.data ?? const [];
        if (playlists.isEmpty) {
          return const _RemotePlaylistPlaceholder(message: '当前来源没有可读取的歌单。');
        }
        ProviderPlaylist? selected;
        if (selectedPlaylistId != null) {
          for (final playlist in playlists) {
            if (playlist.playlistId == selectedPlaylistId) {
              selected = playlist;
              break;
            }
          }
        }
        if (selected != null) {
          return _RemotePlaylistTracks(
            playlist: selected,
            onBack: onBack,
          );
        }
        return _RemotePlaylistGrid(
          playlists: playlists,
          onSelected: onSelected,
        );
      },
    );
  }
}

class _RemotePlaylistGrid extends StatelessWidget {
  const _RemotePlaylistGrid({
    required this.playlists,
    required this.onSelected,
  });

  final List<ProviderPlaylist> playlists;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final count = width >= 1240
        ? 4
        : width >= 980
            ? 3
            : 2;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: .72,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return InkWell(
          onTap: () => onSelected(playlist.playlistId),
          borderRadius: MeloRadii.lg,
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MeloColors.surface,
              borderRadius: MeloRadii.lg,
              border: Border.all(color: MeloColors.border),
              boxShadow: MeloShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: _RemotePlaylistCover(playlist: playlist),
                ),
                const SizedBox(height: 12),
                Text(
                  playlist.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${playlist.trackCount} 首 · ${playlist.creatorName ?? '网易云'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RemotePlaylistTracks extends ConsumerWidget {
  const _RemotePlaylistTracks({
    required this.playlist,
    required this.onBack,
  });

  final ProviderPlaylist playlist;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    return FutureBuilder<List<SourceTrack>>(
      future: repository.loadProviderPlaylistTracks(
        providerId: playlist.providerId,
        playlistId: playlist.playlistId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('歌单曲目加载失败：${snapshot.error}'));
        }
        final tracks = snapshot.data ?? const [];
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '返回歌单',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${tracks.length} 首 · ${playlist.creatorName ?? '远端歌单'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: MeloColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: tracks.isEmpty
                          ? null
                          : () async {
                              await repository.playTrack(tracks.first);
                              for (final track in tracks.skip(1)) {
                                repository.enqueueTrack(track);
                              }
                            },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('播放全部'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: MeloColors.border),
              Expanded(
                child: tracks.isEmpty
                    ? const Center(child: Text('这个歌单暂时没有可显示曲目。'))
                    : ListView.separated(
                        itemCount: tracks.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: MeloColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return ListTile(
                            leading: SizedBox(
                              width: 76,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${index + 1}',
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: MeloColors.textTertiary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _RemoteTrackCover(track: track),
                                ],
                              ),
                            ),
                            title: Text(track.title),
                            subtitle: Text(
                              '${track.artists.join(' / ')} · ${track.album ?? '网易云'}',
                            ),
                            trailing: IconButton(
                              tooltip: '播放',
                              onPressed: track.isPlayable
                                  ? () => repository.playTrack(track)
                                  : null,
                              icon: const Icon(Icons.play_arrow_rounded),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RemotePlaylistCover extends StatelessWidget {
  const _RemotePlaylistCover({required this.playlist});

  final ProviderPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    final cover = playlist.cover;
    if (cover != null && cover.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: MeloRadii.md,
        child: Image.network(
          cover.toString(),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://music.163.com',
          },
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: MeloRadii.md,
        color: MeloColors.primary50,
      ),
      child: const Icon(
        Icons.queue_music_rounded,
        size: 46,
        color: MeloColors.primary700,
      ),
    );
  }
}

class _RemoteTrackCover extends StatelessWidget {
  const _RemoteTrackCover({required this.track});

  final SourceTrack track;

  @override
  Widget build(BuildContext context) {
    final artwork = track.artwork;
    if (artwork != null && artwork.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: MeloRadii.sm,
        child: Image.network(
          artwork.toString(),
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://music.163.com',
          },
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hue =
        track.title.codeUnits.fold<int>(0, (sum, value) => sum + value) % 360;
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
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
