part of 'local_playlists_page.dart';

class _PlaylistGrid extends StatelessWidget {
  const _PlaylistGrid({
    required this.playlists,
    required this.selectedPlaylistId,
    required this.onSelected,
  });

  final List<LocalPlaylist> playlists;
  final String? selectedPlaylistId;
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
        childAspectRatio: .78,
      ),
      itemCount: playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const _CreatePlaylistCard();
        final playlist = playlists[index - 1];
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: MeloRadii.md,
            border: Border.all(
              color: playlist.id == selectedPlaylistId
                  ? MeloColors.primary500
                  : Colors.transparent,
            ),
          ),
          child: MeloPlaylistCard(
            title: playlist.name,
            subtitle: '${playlist.items.length} 首 · 混合',
            onTap: () => onSelected(playlist.id),
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

class _RemotePlaylistsPanel extends ConsumerStatefulWidget {
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
  ConsumerState<_RemotePlaylistsPanel> createState() =>
      _RemotePlaylistsPanelState();
}

class _RemotePlaylistsPanelState extends ConsumerState<_RemotePlaylistsPanel> {
  late Future<List<ProviderPlaylist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = _loadPlaylists();
  }

  @override
  void didUpdateWidget(covariant _RemotePlaylistsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providerId != widget.providerId) {
      _playlistsFuture = _loadPlaylists();
    }
  }

  Future<List<ProviderPlaylist>> _loadPlaylists() {
    return ref
        .read(demoRepositoryProvider)
        .loadProviderPlaylists(widget.providerId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProviderPlaylist>>(
      future: _playlistsFuture,
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
        if (widget.selectedPlaylistId != null) {
          for (final playlist in playlists) {
            if (playlist.playlistId == widget.selectedPlaylistId) {
              selected = playlist;
              break;
            }
          }
        }
        if (selected != null) {
          return _RemotePlaylistTracks(
            playlist: selected,
            onBack: widget.onBack,
          );
        }
        return _RemotePlaylistGrid(
          playlists: playlists,
          onSelected: widget.onSelected,
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
        childAspectRatio: .78,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return MeloPlaylistCard(
          title: playlist.name,
          subtitle:
              '${playlist.trackCount} 首 · ${playlist.creatorName ?? '网易云'}',
          cover: playlist.cover,
          onTap: () => onSelected(playlist.playlistId),
        );
      },
    );
  }
}

class _RemotePlaylistTracks extends ConsumerStatefulWidget {
  const _RemotePlaylistTracks({
    required this.playlist,
    required this.onBack,
  });

  final ProviderPlaylist playlist;
  final VoidCallback onBack;

  @override
  ConsumerState<_RemotePlaylistTracks> createState() =>
      _RemotePlaylistTracksState();
}

class _RemotePlaylistTracksState extends ConsumerState<_RemotePlaylistTracks> {
  late Future<List<SourceTrack>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _tracksFuture = _loadTracks();
  }

  @override
  void didUpdateWidget(covariant _RemotePlaylistTracks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist.providerId != widget.playlist.providerId ||
        oldWidget.playlist.playlistId != widget.playlist.playlistId) {
      _tracksFuture = _loadTracks();
    }
  }

  Future<List<SourceTrack>> _loadTracks() {
    return ref.read(demoRepositoryProvider).loadProviderPlaylistTracks(
          providerId: widget.playlist.providerId,
          playlistId: widget.playlist.playlistId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(demoRepositoryProvider);
    final currentRef = ref.watch(
      demoRepositoryProvider.select((r) => r.queue.current?.track.ref),
    );
    return FutureBuilder<List<SourceTrack>>(
      future: _tracksFuture,
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
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${tracks.length} 首 · ${widget.playlist.creatorName ?? '远端歌单'}',
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
                          : () => repository.playTracks(tracks),
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
                          final selected = currentRef == track.ref;
                          return MeloInteractiveRow(
                            selected: selected,
                            onDoubleTap: track.isPlayable
                                ? () => repository.playOrToggleTrack(track)
                                : null,
                            builder: (context, hovered) => Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: selected
                                      ? const Icon(
                                          Icons.graphic_eq_rounded,
                                          color: MeloColors.primary700,
                                          size: 18,
                                        )
                                      : Text(
                                          '${index + 1}'.padLeft(2, '0'),
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: hovered
                                                    ? MeloColors.primary700
                                                    : MeloColors.textTertiary,
                                                fontWeight: FontWeight.w700,
                                              ),
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
                                        child: _PlaylistTrackTitleBlock(
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
                                    track.album ?? '网易云',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: MeloColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 120),
                                  opacity: hovered || selected ? 1 : 0,
                                  child: IgnorePointer(
                                    ignoring: !hovered && !selected,
                                    child: IconButton(
                                      tooltip: '播放',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: track.isPlayable
                                          ? () => repository
                                              .playOrToggleTrack(track)
                                          : null,
                                      icon: const Icon(
                                        Icons.play_arrow_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

class _PlaylistTrackTitleBlock extends StatelessWidget {
  const _PlaylistTrackTitleBlock({
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
