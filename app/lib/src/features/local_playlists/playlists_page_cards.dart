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
        childAspectRatio: width < 960 ? .66 : .70,
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
    final repo = ref.read(demoRepositoryProvider);
    final cached = repo.cachedRemotePlaylists(widget.providerId);
    if (cached != null && repo.hasFreshRemotePlaylists(widget.providerId)) {
      return Future.value(cached);
    }
    return repo.loadProviderPlaylists(widget.providerId);
  }

  @override
  Widget build(BuildContext context) {
    final cached = ref
        .read(demoRepositoryProvider)
        .cachedRemotePlaylists(widget.providerId);
    return FutureBuilder<List<ProviderPlaylist>>(
      future: _playlistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          if (cached != null && cached.isNotEmpty) {
            return _RemotePlaylistGrid(
              playlists: cached,
              onSelected: widget.onSelected,
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return MeloErrorState(message: '歌单加载失败：${snapshot.error}');
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
        childAspectRatio: width < 960 ? .66 : .70,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final presentation = meloProviderPresentation(playlist.providerId);
        return MeloPlaylistCard(
          title: playlist.name,
          subtitle:
              '${playlist.trackCount} 首 · ${playlist.creatorName ?? presentation.shortName}',
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
    final repo = ref.read(demoRepositoryProvider);
    final cached = repo.cachedPlaylistTracks(
      widget.playlist.providerId,
      widget.playlist.playlistId,
    );
    if (cached != null &&
        repo.hasFreshPlaylistTracks(
          widget.playlist.providerId,
          widget.playlist.playlistId,
        )) {
      return Future.value(cached);
    }
    return repo.loadProviderPlaylistTracks(
      providerId: widget.playlist.providerId,
      playlistId: widget.playlist.playlistId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;
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
          return MeloErrorState(message: '歌单曲目加载失败：${snapshot.error}');
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
                        padding: EdgeInsets.only(bottom: isMobile ? 156 : 4),
                        scrollCacheExtent: isMobile ? 640 : null,
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
                                    track.album ??
                                        meloProviderPresentation(
                                          track.ref.providerId,
                                        ).shortName,
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

class _LocalPlaylistTracks extends StatelessWidget {
  const _LocalPlaylistTracks({
    required this.playlist,
    required this.repository,
    required this.onBack,
  });

  final LocalPlaylist playlist;
  final DemoRepository repository;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;
    final currentRef = repository.queue.current?.track.ref;
    final playableTracks = [
      for (final item in playlist.items)
        if (repository.sourceTrackByRef(item.trackRef) case final track?)
          if (track.isPlayable) track,
    ];

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
                SizedBox(
                  width: 46,
                  height: 46,
                  child: MeloPlaylistCover(title: playlist.name),
                ),
                const SizedBox(width: 12),
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
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${playlist.items.length} 首 · 本地歌单',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MeloColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: playableTracks.isEmpty
                      ? null
                      : () => repository.playTracks(playableTracks),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('播放全部'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: MeloColors.border),
          Expanded(
            child: playlist.items.isEmpty
      for (final item in playlist.items)
        if (repository.sourceTrackByRef(item.trackRef) case final track?)
          if (track.isPlayable) track,
    ];

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
                SizedBox(
                  width: 46,
                  height: 46,
                  child: MeloPlaylistCover(title: playlist.name),
                ),
                const SizedBox(width: 12),
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
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${playlist.items.length} 首 · 本地歌单',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MeloColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: playableTracks.isEmpty
                      ? null
                      : () => repository.playTracks(playableTracks),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('播放全部'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: MeloColors.border),
          Expanded(
            child: playlist.items.isEmpty
                ? const MeloEmptyState(
                    icon: Icons.playlist_add_rounded,
                    title: '这个歌单还没有歌曲',
                    subtitle: '在喜欢、推荐或搜索结果里通过更多菜单加入歌曲。',
                  )
                : ListView.separated(
                    itemCount: playlist.items.length,
                    padding: EdgeInsets.only(bottom: isMobile ? 156 : 4),
                    scrollCacheExtent: isMobile ? 640 : null,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      final track = repository.sourceTrackByRef(item.trackRef);
                      final selected = currentRef == item.trackRef;
                      final title = track?.title ?? item.cachedTitle;
                      final artists = track?.artists ?? item.cachedArtists;
                      final providerName = track == null
                          ? item.cachedProviderName
                          : meloProviderPresentation(track.ref.providerId)
                              .shortName;
                      return MeloInteractiveRow(
                        selected: selected,
                        onDoubleTap: track?.isPlayable == true
                            ? () => repository.playOrToggleTrack(track!)
                            : null,
                        builder: (context, hovered) => Row(
                          children: [
                            SizedBox(
                              width: 34,
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
                                            color: MeloColors.textTertiary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            MeloTrackCover(
                              seed: title,
                              artwork: track?.artwork,
                              isActive: selected,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PlaylistTrackTitleBlock(
                                title: title,
                                artists: artists,
                                active: selected,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              providerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: MeloColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: track?.isPlayable == true
                                  ? '播放'
                                  : '当前会话缺少播放信息',
                              visualDensity: VisualDensity.compact,
                              onPressed: track?.isPlayable == true
                                  ? () => repository.playOrToggleTrack(track!)
                                  : null,
                              icon: const Icon(Icons.play_arrow_rounded),
                            ),
                            IconButton(
                              tooltip: '从歌单移除',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  repository.removeTrackFromPlaylist(
                                playlistId: playlist.id,
                                trackRef: item.trackRef,
                              ),
                              icon: const Icon(Icons.close_rounded),
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
