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

        final headerRow = Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: '返回歌单',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '我的歌单',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
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
        );

        Widget trackList;
        if (tracks.isEmpty) {
          trackList = const Center(child: Text('这个歌单暂时没有可显示曲目。'));
        } else if (isMobile) {
          trackList = ListView.separated(
            key: PageStorageKey<String>(
              'remote_playlist_tracks_mobile_${widget.playlist.providerId.value}_${widget.playlist.playlistId}',
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 156),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final selected = currentRef == track.ref;
              return MeloTapFeedback(
                onTap: track.isPlayable
                    ? () => repository.playOrToggleTrack(track)
                    : null,
                selected: selected,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? MeloColors.primary50
                        : MeloColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: MeloShadows.card,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 28,
                        child: Center(
                          child: selected
                              ? const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: MeloColors.primary700,
                                  size: 16,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: MeloColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MeloTrackCover(
                        seed: track.title,
                        artwork: track.artwork,
                        isActive: selected,
                        size: 48,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: selected
                                        ? MeloColors.primary700
                                        : MeloColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artists.join(' / '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: MeloColors.textSecondary,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        () {
                          final m = track.duration.inMinutes
                              .toString()
                              .padLeft(2, '0');
                          final s = track.duration.inSeconds
                              .remainder(60)
                              .toString()
                              .padLeft(2, '0');
                          return '$m:$s';
                        }(),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: MeloColors.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                      const SizedBox(width: 4),
                      MeloTrackDownloadButton(track: track),
                      MeloFavoriteButton(track: track),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          trackList = ListView.builder(
            key: PageStorageKey<String>(
              'remote_playlist_tracks_${widget.playlist.providerId.value}_${widget.playlist.playlistId}',
            ),
            itemCount: tracks.length,
            padding: const EdgeInsets.only(bottom: 4),
            scrollCacheExtent: const ScrollCacheExtent.pixels(560),
            itemExtent: MeloListMetrics.rowHeight,
            addAutomaticKeepAlives: false,
            addSemanticIndexes: false,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final selected = currentRef == track.ref;
              return _TrackRowFrame(
                child: MeloInteractiveRow(
                  selected: selected,
                  onTap: null,
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
                        duration: Duration.zero,
                        opacity: hovered || selected ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !hovered && !selected,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MeloTrackDownloadButton(track: track),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: MeloFavoriteButton(
                                    track: track,
                                    showSnackbar: false,
                                  ),
                                ),
                              ),
                              MeloTrackMoreMenu(track: track),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        final mainContent = Column(
          children: [
            headerRow,
            if (!isMobile)
              const Divider(height: 1, color: MeloColors.border),
            Expanded(child: trackList),
          ],
        );

        if (isMobile) return mainContent;

        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: MeloColors.surface,
              borderRadius: MeloRadii.sm,
              border: Border.all(color: MeloColors.border),
            ),
            child: Column(
              children: [
                headerRow,
                const Divider(height: 1, color: MeloColors.border),
                const _TracksTableHeader(
                  columns: ['#', '歌曲', '专辑', '操作'],
                ),
                const Divider(height: 1, color: MeloColors.border),
                Expanded(child: trackList),
              ],
            ),
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

    final headerWidget = Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回歌单',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '我的歌单',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
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
    );

    final mainContent = Column(
      children: [
        headerWidget,
        if (!isMobile) const Divider(height: 1, color: MeloColors.border),
        if (!isMobile)
          const _TracksTableHeader(
            columns: ['#', '歌曲', '来源', '操作'],
          ),
        if (!isMobile) const Divider(height: 1, color: MeloColors.border),
        Expanded(
          child: playlist.items.isEmpty
              ? const MeloEmptyState(
                  icon: Icons.playlist_add_rounded,
                  title: '这个歌单还没有歌曲',
                  subtitle: '在喜欢、推荐或搜索结果里通过更多菜单加入歌曲。',
                )
              : isMobile
                  ? ListView.separated(
                      key: PageStorageKey<String>(
                        'local_playlist_tracks_mobile_${playlist.id}',
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 156),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: playlist.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = playlist.items[index];
                        final track =
                            repository.sourceTrackByRef(item.trackRef);
                        final selected = currentRef == item.trackRef;
                        final title = track?.title ?? item.cachedTitle;
                        final artists =
                            track?.artists ?? item.cachedArtists;
                        final trackPlayable = track?.isPlayable == true;

                        return MeloTapFeedback(
                          onTap: trackPlayable
                              ? () =>
                                  repository.playOrToggleTrack(track!)
                              : null,
                          selected: selected,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? MeloColors.primary50
                                  : MeloColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: MeloShadows.card,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 28,
                                  child: Center(
                                    child: selected
                                        ? const Icon(
                                            Icons.graphic_eq_rounded,
                                            color: MeloColors.primary700,
                                            size: 16,
                                          )
                                        : Text(
                                            '${index + 1}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: MeloColors
                                                      .textSecondary,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                MeloTrackCover(
                                  seed: title,
                                  artwork: track?.artwork,
                                  isActive: selected,
                                  size: 48,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: selected
                                                  ? MeloColors
                                                      .primary700
                                                  : MeloColors
                                                      .textPrimary,
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        artists.join(' / '),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: MeloColors
                                                  .textSecondary,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                MeloPlatformIcon(
                                    providerId:
                                        item.trackRef.providerId),
                                const SizedBox(width: 10),
                                Text(
                                  track != null
                                      ? () {
                                          final m = track.duration
                                              .inMinutes
                                              .toString()
                                              .padLeft(2, '0');
                                          final s = track.duration
                                              .inSeconds
                                              .remainder(60)
                                              .toString()
                                              .padLeft(2, '0');
                                          return '$m:$s';
                                        }()
                                      : '--:--',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            MeloColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                if (track != null)
                                  MeloTrackDownloadButton(
                                      track: track),
                                IconButton(
                                  icon: const Icon(
                                      Icons.close_rounded,
                                      size: 20),
                                  color: MeloColors.textTertiary,
                                  visualDensity:
                                      VisualDensity.compact,
                                  onPressed: () => repository
                                      .removeTrackFromPlaylist(
                                    playlistId: playlist.id,
                                    trackRef: item.trackRef,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      key: PageStorageKey<String>(
                        'local_playlist_tracks_${playlist.id}',
                      ),
                      itemCount: playlist.items.length,
                      padding: const EdgeInsets.only(bottom: 4),
                      scrollCacheExtent:
                          const ScrollCacheExtent.pixels(560),
                      itemExtent: MeloListMetrics.rowHeight,
                      addAutomaticKeepAlives: false,
                      addSemanticIndexes: false,
                      itemBuilder: (context, index) {
                        final item = playlist.items[index];
                        final track =
                            repository.sourceTrackByRef(item.trackRef);
                        final selected = currentRef == item.trackRef;
                        final title = track?.title ?? item.cachedTitle;
                        final artists =
                            track?.artists ?? item.cachedArtists;
                        final providerName = track == null
                            ? item.cachedProviderName
                            : meloProviderPresentation(
                                    track.ref.providerId)
                                .shortName;
                        return _TrackRowFrame(
                          child: MeloInteractiveRow(
                            selected: selected,
                            onTap: null,
                            onDoubleTap: track?.isPlayable == true
                                ? () => repository
                                    .playOrToggleTrack(track!)
                                : null,
                            builder: (context, hovered) => Row(
                              children: [
                                SizedBox(
                                  width: 34,
                                  child: selected
                                      ? const Icon(
                                          Icons.graphic_eq_rounded,
                                          color:
                                              MeloColors.primary700,
                                          size: 18,
                                        )
                                      : Text(
                                          '${index + 1}'
                                              .padLeft(2, '0'),
                                          textAlign:
                                              TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: MeloColors
                                                    .textTertiary,
                                                fontWeight:
                                                    FontWeight.w700,
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
                                        color:
                                            MeloColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                if (track != null) ...[
                                  MeloTrackDownloadButton(track: track),
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Center(
                                      child: MeloFavoriteButton(
                                        track: track,
                                        showSnackbar: false,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: track.isPlayable
                                        ? '播放'
                                        : '当前会话缺少播放信息',
                                    visualDensity:
                                        VisualDensity.compact,
                                    onPressed: track.isPlayable
                                        ? () => repository
                                            .playOrToggleTrack(track)
                                        : null,
                                    icon: const Icon(
                                        Icons.play_arrow_rounded),
                                  ),
                                ],
                                IconButton(
                                  tooltip: '从歌单移除',
                                  visualDensity:
                                      VisualDensity.compact,
                                  onPressed: () => repository
                                      .removeTrackFromPlaylist(
                                    playlistId: playlist.id,
                                    trackRef: item.trackRef,
                                  ),
                                  icon: const Icon(
                                      Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );

    if (isMobile) {
      return mainContent;
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MeloColors.surface,
          borderRadius: MeloRadii.sm,
          border: Border.all(color: MeloColors.border),
        ),
        child: mainContent,
      ),
    );
  }
}

class _TracksTableHeader extends StatelessWidget {
  const _TracksTableHeader({required this.columns});

  final List<String> columns;

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
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(columns[0], style: labelStyle, textAlign: TextAlign.center),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(columns[1], style: labelStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(columns[2], style: labelStyle),
          ),
          SizedBox(
            width: 128,
            child: Text(columns[3], style: labelStyle, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _TrackRowFrame extends StatelessWidget {
  const _TrackRowFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MeloColors.border),
        ),
      ),
      child: child,
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
