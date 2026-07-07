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
        childAspectRatio: 0.78,
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
    final isMobile = width < 960;
    final count = isMobile
        ? 3
        : width >= 1240
            ? 4
            : width >= 980
                ? 3
                : 2;
    return GridView.builder(
      padding: isMobile
          ? const EdgeInsets.fromLTRB(10, 0, 10, 156)
          : EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        mainAxisSpacing: isMobile ? 8 : 16,
        crossAxisSpacing: isMobile ? 10 : 16,
        childAspectRatio: isMobile ? 0.72 : 0.78,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final presentation = meloProviderPresentation(playlist.providerId);
        return MeloPlaylistCard(
          compact: isMobile,
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

class RemotePlaylistId {
  final ProviderId providerId;
  final String playlistId;

  const RemotePlaylistId({required this.providerId, required this.playlistId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemotePlaylistId &&
          runtimeType == other.runtimeType &&
          providerId == other.providerId &&
          playlistId == other.playlistId;

  @override
  int get hashCode => providerId.hashCode ^ playlistId.hashCode;
}

final remotePlaylistTracksProvider =
    FutureProvider.family<List<SourceTrack>, RemotePlaylistId>((ref, id) {
  final repo = ref.read(demoRepositoryProvider);
  final cached = repo.cachedPlaylistTracks(id.providerId, id.playlistId);
  if (cached != null &&
      repo.hasFreshPlaylistTracks(id.providerId, id.playlistId)) {
    return cached;
  }
  return repo.loadProviderPlaylistTracks(
    providerId: id.providerId,
    playlistId: id.playlistId,
  );
});

class _RemotePlaylistTracks extends ConsumerWidget {
  const _RemotePlaylistTracks({
    required this.playlist,
    required this.onBack,
  });

  final ProviderPlaylist playlist;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;
    final repository = ref.read(demoRepositoryProvider);
    final currentRef = ref.watch(
      demoRepositoryProvider.select((r) => r.queue.current?.track.ref),
    );
    final remoteId = RemotePlaylistId(
      providerId: playlist.providerId,
      playlistId: playlist.playlistId,
    );
    final tracksAsync = ref.watch(remotePlaylistTracksProvider(remoteId));

    return tracksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => MeloErrorState(message: '歌单曲目加载失败：$error'),
      data: (tracks) {
        final headerRow = Padding(
          padding: const EdgeInsets.fromLTRB(
              MeloSpacing.xxs, MeloSpacing.sm, MeloSpacing.md, MeloSpacing.sm),
          child: Row(
            children: [
              IconButton(
                tooltip: '返回歌单',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: MeloSpacing.xxs),
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
                onPressed:
                    tracks.isEmpty ? null : () => repository.playTracks(tracks),
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
              'remote_playlist_tracks_mobile_${playlist.providerId.value}_${playlist.playlistId}',
            ),
            padding: const EdgeInsets.fromLTRB(
                MeloSpacing.md, MeloSpacing.xxs, MeloSpacing.md, 156),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: MeloSpacing.xs),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final selected = currentRef == track.ref;
              return MeloMobileTrackRow(
                index: index + 1,
                title: track.title,
                artists: track.artists,
                artwork: track.artwork,
                duration: track.duration,
                isActive: selected,
                onTap: track.isPlayable
                    ? () => repository.playOrToggleTrack(track)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      () {
                        final m =
                            track.duration.inMinutes.toString().padLeft(2, '0');
                        final s = track.duration.inSeconds
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0');
                        return '$m:$s';
                      }(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MeloColors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(width: MeloSpacing.xxs),
                    MeloTrackDownloadButton(track: track),
                    MeloFavoriteButton(track: track),
                  ],
                ),
              );
            },
          );
        } else {
          trackList = ListView.builder(
            key: PageStorageKey<String>(
              'remote_playlist_tracks_${playlist.providerId.value}_${playlist.playlistId}',
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
              return MeloDesktopTrackRow(
                index: index + 1,
                title: track.title,
                artists: track.artists,
                artwork: track.artwork,
                album: track.album ??
                    meloProviderPresentation(
                      track.ref.providerId,
                    ).shortName,
                isActive: selected,
                onDoubleTap: track.isPlayable
                    ? () => repository.playOrToggleTrack(track)
                    : null,
                trailing: Row(
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
              );
            },
          );
        }

        final mainContent = Column(
          children: [
            headerRow,
            if (!isMobile) const Divider(height: 1, color: MeloColors.border),
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
      padding: const EdgeInsets.fromLTRB(
          MeloSpacing.xxs, MeloSpacing.sm, MeloSpacing.md, MeloSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回歌单',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: MeloSpacing.xxs),
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
                      padding: const EdgeInsets.fromLTRB(
                          MeloSpacing.md, MeloSpacing.xxs, MeloSpacing.md, 156),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: playlist.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: MeloSpacing.xs),
                      itemBuilder: (context, index) {
                        final item = playlist.items[index];
                        final track =
                            repository.sourceTrackByRef(item.trackRef);
                        final selected = currentRef == item.trackRef;
                        final title = track?.title ?? item.cachedTitle;
                        final artists = track?.artists ?? item.cachedArtists;
                        final trackPlayable = track?.isPlayable == true;

                        return MeloMobileTrackRow(
                          index: index + 1,
                          title: title,
                          artists: artists,
                          artwork: track?.artwork,
                          duration: track?.duration ?? Duration.zero,
                          isActive: selected,
                          onTap: trackPlayable
                              ? () => repository.playOrToggleTrack(track!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MeloPlatformIcon(
                                  providerId: item.trackRef.providerId),
                              const SizedBox(width: MeloSpacing.xs),
                              Text(
                                track != null
                                    ? () {
                                        final m = track.duration.inMinutes
                                            .toString()
                                            .padLeft(2, '0');
                                        final s = track.duration.inSeconds
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
                                      color: MeloColors.textSecondary,
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              if (track != null)
                                MeloTrackDownloadButton(track: track),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                color: MeloColors.textTertiary,
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    repository.removeTrackFromPlaylist(
                                  playlistId: playlist.id,
                                  trackRef: item.trackRef,
                                ),
                              ),
                            ],
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
                      scrollCacheExtent: const ScrollCacheExtent.pixels(560),
                      itemExtent: MeloListMetrics.rowHeight,
                      addAutomaticKeepAlives: false,
                      addSemanticIndexes: false,
                      itemBuilder: (context, index) {
                        final item = playlist.items[index];
                        final track =
                            repository.sourceTrackByRef(item.trackRef);
                        final selected = currentRef == item.trackRef;
                        final title = track?.title ?? item.cachedTitle;
                        final artists = track?.artists ?? item.cachedArtists;
                        final providerName = track == null
                            ? item.cachedProviderName
                            : meloProviderPresentation(track.ref.providerId)
                                .shortName;
                        return MeloDesktopTrackRow(
                          index: index + 1,
                          title: title,
                          artists: artists,
                          artwork: track?.artwork,
                          subtitle: providerName,
                          isActive: selected,
                          onDoubleTap: track?.isPlayable == true
                              ? () => repository.playOrToggleTrack(track!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                  tooltip:
                                      track.isPlayable ? '播放' : '当前会话缺少播放信息',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: track.isPlayable
                                      ? () =>
                                          repository.playOrToggleTrack(track)
                                      : null,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                ),
                              ],
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
            child: Text(columns[0],
                style: labelStyle, textAlign: TextAlign.center),
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
            child: Text(columns[3],
                style: labelStyle, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
