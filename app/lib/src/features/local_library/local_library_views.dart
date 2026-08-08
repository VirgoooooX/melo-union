import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../local_library/artist_metadata_enrichment_service.dart';
import '../../local_library/local_library_controller.dart';
import '../../widgets/melo_components.dart';
import '../../widgets/melo_track_row.dart';

class LocalSongsView extends ConsumerWidget {
  const LocalSongsView({
    super.key,
    required this.controller,
    this.tracks,
    this.titleFlex = 3,
    this.albumFlex = 3,
    this.yearWidth,
  });

  final LocalLibraryController controller;
  final List<LocalLibraryTrack>? tracks;
  final int titleFlex;
  final int albumFlex;
  final double? yearWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = tracks ?? controller.tracks;
    if (values.isEmpty) return const Center(child: Text('没有找到匹配的本地歌曲'));
    final repository = ref.read(demoRepositoryProvider);
    final currentRef = ref.watch(
        demoRepositoryProvider.select((repo) => repo.queue.current?.track.ref));
    return DecoratedBox(
      decoration: BoxDecoration(
          color: MeloColors.surface,
          borderRadius: MeloRadii.sm,
          border: Border.all(color: MeloColors.border)),
      child: ClipRRect(
        borderRadius: MeloRadii.sm,
        child: Column(children: [
          _TrackHeader(
            titleFlex: titleFlex,
            albumFlex: albumFlex,
            yearWidth: yearWidth,
          ),
          const Divider(height: 1, color: MeloColors.border),
          Expanded(
              child: ListView.builder(
            itemExtent: MeloListMetrics.rowHeight,
            itemCount:
                values.length + (tracks == null && controller.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == values.length) {
                return Center(
                    child: TextButton(
                        onPressed:
                            controller.isLoading ? null : controller.loadMore,
                        child: const Text('加载更多')));
              }
              final local = values[index];
              final track = local.toSourceTrack();
              return MeloDesktopTrackRow(
                index: index + 1,
                title: track.title,
                artists: track.artists,
                artwork: track.artwork,
                album: track.album ?? '未知专辑',
                year: local.year?.toString() ?? '—',
                isActive: currentRef == track.ref,
                onDoubleTap: () =>
                    unawaited(repository.playOrToggleTrack(track)),
                titleFlex: titleFlex,
                albumFlex: albumFlex,
                yearWidth: yearWidth,
                trailing: SizedBox(
                    width: MeloDimensions.desktopTrackActionColumnWidth,
                    child: Center(
                        child: local.isAvailable
                            ? MeloTrackMoreMenu(track: track)
                            : const Tooltip(
                                message: '文件不存在或磁盘不可用',
                                child: Icon(Icons.link_off_rounded,
                                    color: MeloColors.warning, size: 18)))),
              );
            },
          )),
        ]),
      ),
    );
  }
}

class LocalAlbumsView extends StatelessWidget {
  const LocalAlbumsView({
    super.key,
    required this.controller,
    required this.onAlbumTap,
  });
  final LocalLibraryController controller;
  final ValueChanged<LocalLibraryAlbum> onAlbumTap;
  @override
  Widget build(BuildContext context) {
    if (controller.albums.isEmpty) {
      return const Center(child: Text('没有找到匹配的专辑'));
    }
    return _PagedGrid(
      count: controller.albums.length,
      hasMore: controller.hasMore,
      isLoading: controller.isLoading,
      onMore: controller.loadMore,
      itemBuilder: (context, index) {
        final album = controller.albums[index];
        return _LibraryCard(
          artwork: album.artworkPath == null ? const [] : [album.artworkPath!],
          title: album.title,
          subtitle:
              '${album.albumArtist} · ${album.canonicalYear ?? '未知年份'} · ${album.trackCount} 首',
          hasYearConflict: album.hasYearConflict,
          onTap: () => onAlbumTap(album),
        );
      },
    );
  }
}

class LocalArtistsView extends StatelessWidget {
  const LocalArtistsView({
    super.key,
    required this.controller,
    required this.onArtistTap,
    this.enrichment,
  });
  final LocalLibraryController controller;
  final ArtistMetadataEnrichmentService? enrichment;
  final ValueChanged<LocalLibraryArtist> onArtistTap;
  @override
  Widget build(BuildContext context) {
    if (controller.artists.isEmpty) {
      return const Center(child: Text('没有找到匹配的歌手'));
    }
    return _PagedGrid(
      count: controller.artists.length,
      hasMore: controller.hasMore,
      isLoading: controller.isLoading,
      onMore: controller.loadMore,
      itemBuilder: (context, index) {
        final artist = controller.artists[index];
        final cachedPath = artist.metadata?.avatarCachePath;
        final cached = cachedPath != null && File(cachedPath).existsSync()
            ? cachedPath
            : null;
        return _LibraryCard(
          artwork: cached == null
              ? artist.sampleArtworkPaths.take(4).toList()
              : [cached],
          title: artist.displayName,
          subtitle: '${artist.albumCount} 张专辑 · ${artist.trackCount} 首歌曲',
          circular: cached != null,
          onTap: () => onArtistTap(artist),
        );
      },
    );
  }
}

class _PagedGrid extends StatelessWidget {
  const _PagedGrid(
      {required this.count,
      required this.hasMore,
      required this.isLoading,
      required this.onMore,
      required this.itemBuilder});
  final int count;
  final bool hasMore;
  final bool isLoading;
  final Future<void> Function() onMore;
  final IndexedWidgetBuilder itemBuilder;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = (constraints.maxWidth / 180).floor().clamp(2, 8);
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (hasMore &&
                !isLoading &&
                notification.metrics.extentAfter < 600) {
              unawaited(onMore());
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: MeloSpacing.lg,
                    crossAxisSpacing: MeloSpacing.lg,
                    childAspectRatio: .76),
                delegate: SliverChildBuilderDelegate(
                  itemBuilder,
                  childCount: count,
                ),
              ),
              if (hasMore)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MeloSpacing.xxl,
                    child: isLoading
                        ? const Center(
                            child: SizedBox.square(
                              dimension: MeloSpacing.lg,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
            ],
          ),
        );
      });
}

class _LibraryCard extends StatefulWidget {
  const _LibraryCard(
      {required this.artwork,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.circular = false,
      this.hasYearConflict = false});
  final List<String> artwork;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool circular;
  final bool hasYearConflict;
  @override
  State<_LibraryCard> createState() => _LibraryCardState();
}

class _LibraryCardState extends State<_LibraryCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: InkWell(
            onTap: widget.onTap,
            borderRadius: MeloRadii.md,
            child: Padding(
                padding: const EdgeInsets.all(MeloSpacing.xs),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Stack(fit: StackFit.expand, children: [
                        ClipRRect(
                            borderRadius:
                                widget.circular ? MeloRadii.pill : MeloRadii.md,
                            child: _ArtworkCollage(
                                paths: widget.artwork, label: widget.title)),
                        if (hovered)
                          Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Material(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: widget.onTap,
                                      child: const SizedBox.square(
                                        dimension: 30,
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ))),
                      ])),
                      const SizedBox(height: MeloSpacing.sm),
                      Text(widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Expanded(
                            child: Text(widget.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: MeloColors.textSecondary))),
                        if (widget.hasYearConflict) ...[
                          const SizedBox(width: MeloSpacing.xs),
                          const Tooltip(
                              message: '年份标签存在差异',
                              child: Icon(Icons.info_outline_rounded,
                                  size: MeloSpacing.md,
                                  color: MeloColors.warning)),
                        ],
                      ]),
                    ]))),
      );
}

class _ArtworkCollage extends StatelessWidget {
  const _ArtworkCollage({required this.paths, required this.label});
  final List<String> paths;
  final String label;
  @override
  Widget build(BuildContext context) {
    final available =
        paths.where((value) => File(value).existsSync()).take(4).toList();
    if (available.isEmpty) return _InitialArtwork(label: label);
    if (available.length == 1) {
      return Image.file(File(available.first),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialArtwork(label: label));
    }
    return GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        children: [
          for (final value in available)
            Image.file(File(value),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialArtwork(label: label))
        ]);
  }
}

class _InitialArtwork extends StatelessWidget {
  const _InitialArtwork({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [MeloColors.localBackground, Color(0xFFD8EBFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: Center(
          child: Text(
              label.trim().isEmpty
                  ? '?'
                  : label.trim().characters.first.toUpperCase(),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: MeloColors.localForeground,
                  fontWeight: FontWeight.w800))));
}

class LocalAlbumDetailView extends ConsumerWidget {
  const LocalAlbumDetailView({
    super.key,
    required this.controller,
    required this.album,
    required this.onBack,
  });
  final LocalLibraryController controller;
  final LocalLibraryAlbum album;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '返回',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: MeloSpacing.xs),
            Text(
              '专辑详情',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: MeloSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 150,
              child: ClipRRect(
                borderRadius: MeloRadii.md,
                child: _ArtworkCollage(
                  paths: album.artworkPath == null ? const [] : [album.artworkPath!],
                  label: album.title,
                ),
              ),
            ),
            const SizedBox(width: MeloSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${album.albumArtist} · ${album.canonicalYear ?? '未知年份'} · ${album.trackCount} 首',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  ),
                  FutureBuilder<List<LocalLibraryTrack>>(
                    future: controller.tracksForAlbum(album.albumKey),
                    builder: (context, snapshot) => _AlbumYearConflictDetails(
                      album: album,
                      tracks: snapshot.data,
                    ),
                  ),
                  const SizedBox(height: MeloSpacing.md),
                  FutureBuilder<List<LocalLibraryTrack>>(
                    future: controller.tracksForAlbum(album.albumKey),
                    builder: (_, snapshot) => FilledButton.icon(
                      onPressed: snapshot.hasData
                          ? () => ref
                              .read(demoRepositoryProvider)
                              .playTracks(snapshot.data!
                                  .map((t) => t.toSourceTrack())
                                  .toList())
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('播放专辑'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: MeloSpacing.lg),
        Expanded(
          child: FutureBuilder<List<LocalLibraryTrack>>(
            future: controller.tracksForAlbum(album.albumKey),
            builder: (_, snapshot) => snapshot.hasData
                ? LocalSongsView(
                    controller: controller,
                    tracks: snapshot.data,
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),
      ],
    );
  }
}

class LocalArtistDetailView extends ConsumerWidget {
  const LocalArtistDetailView({
    super.key,
    required this.controller,
    required this.artist,
    required this.onBack,
    required this.onAlbumTap,
    this.enrichment,
  });
  final LocalLibraryController controller;
  final LocalLibraryArtist artist;
  final VoidCallback onBack;
  final ValueChanged<LocalLibraryAlbum> onAlbumTap;
  final ArtistMetadataEnrichmentService? enrichment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = artist.metadata;
    final cachedPath = metadata?.avatarCachePath;
    final artwork = cachedPath == null || !File(cachedPath).existsSync()
        ? artist.sampleArtworkPaths
        : [cachedPath];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '返回',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: MeloSpacing.xs),
            Text(
              '歌手详情',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: '歌手资料',
              onSelected: (action) async {
                if (action == 'refresh') {
                  await enrichment?.enrichNow(artist);
                } else if (action == 'collage') {
                  await enrichment?.forceCollage(artist);
                } else if (action == 'clear') {
                  await enrichment?.clearMetadata(artist);
                }
                await controller.refreshArtist(artist.artistKey);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'refresh', child: Text('重新获取资料')),
                PopupMenuItem(value: 'collage', child: Text('使用专辑封面拼贴')),
                PopupMenuItem(value: 'clear', child: Text('清除网络资料')),
              ],
            ),
          ],
        ),
        const SizedBox(height: MeloSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 150,
              child: ClipOval(
                child: _ArtworkCollage(
                  paths: artwork,
                  label: artist.displayName,
                ),
              ),
            ),
            const SizedBox(width: MeloSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          artist.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: MeloSpacing.md),
                      FutureBuilder<List<LocalLibraryTrack>>(
                        future: controller.tracksForArtist(artist.artistKey),
                        builder: (_, snapshot) => FilledButton.icon(
                          onPressed: snapshot.hasData
                              ? () => ref
                                  .read(demoRepositoryProvider)
                                  .playTracks(snapshot.data!
                                      .map((t) => t.toSourceTrack())
                                      .toList())
                              : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('播放全部'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${artist.albumCount} 张专辑 · ${artist.trackCount} 首歌曲',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  ),
                  if (metadata?.description case final description?)
                    Padding(
                      padding: const EdgeInsets.only(top: MeloSpacing.sm),
                      child: Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: MeloColors.textSecondary,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: MeloSpacing.lg),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Albums (3-column grid)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '专辑',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: MeloSpacing.sm),
                    Expanded(
                      child: FutureBuilder<List<LocalLibraryAlbum>>(
                        future: controller.albumsForArtist(artist.artistKey),
                        builder: (context, snapshot) {
                          final albums = [...(snapshot.data ?? const <LocalLibraryAlbum>[])];
                          if (albums.isEmpty) {
                            return const Center(child: Text('暂无专辑'));
                          }
                          albums.sort((a, b) {
                            final yearA = a.canonicalYear;
                            final yearB = b.canonicalYear;
                            if (yearA == null && yearB == null) return 0;
                            if (yearA == null) return 1;
                            if (yearB == null) return -1;
                            return yearB.compareTo(yearA);
                          });
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final maxWidth = constraints.maxWidth;
                              const spacing = 16.0; // MeloSpacing.md is 16.0
                              final cardWidth = (maxWidth - (spacing * 2)) / 3;
                              final cardHeight = cardWidth + 52.0; // 52.0 fits padding and text perfectly
                              final childAspectRatio = cardWidth / cardHeight;

                              return GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: MeloSpacing.md,
                                  crossAxisSpacing: MeloSpacing.md,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemCount: albums.length,
                                itemBuilder: (context, index) {
                                  final album = albums[index];
                                  return _LibraryCard(
                                    artwork: album.artworkPath == null ? const [] : [album.artworkPath!],
                                    title: album.title,
                                    subtitle: '${album.canonicalYear ?? '未知年份'} · ${album.trackCount} 首',
                                    hasYearConflict: album.hasYearConflict,
                                    onTap: () => onAlbumTap(album),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MeloSpacing.xl),
              // Right side: All Songs
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '全部歌曲',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: MeloSpacing.sm),
                    Expanded(
                      child: FutureBuilder<List<LocalLibraryTrack>>(
                        future: controller.tracksForArtist(artist.artistKey),
                        builder: (_, snapshot) => snapshot.hasData
                            ? LocalSongsView(
                                controller: controller,
                                tracks: snapshot.data,
                                titleFlex: 5,
                                albumFlex: 3,
                                yearWidth: 80.0,
                              )
                            : const Center(
                                child: CircularProgressIndicator(),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlbumYearConflictDetails extends StatelessWidget {
  const _AlbumYearConflictDetails({required this.album, this.tracks});

  final LocalLibraryAlbum album;
  final List<LocalLibraryTrack>? tracks;

  @override
  Widget build(BuildContext context) {
    final years = album.observedYears.join('、');
    final canonicalYear = album.canonicalYear;
    final differentTracks = tracks
        ?.where((track) => track.year != canonicalYear)
        .map((track) => '${track.title}（${track.year ?? '未知年份'}）')
        .toList();
    if (!album.hasYearConflict &&
        (differentTracks == null || differentTracks.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: MeloSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: MeloSpacing.sm,
        vertical: MeloSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: MeloColors.warning.withValues(alpha: .08),
        borderRadius: MeloRadii.sm,
        border: Border.all(color: MeloColors.warning.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '检测到的年份：${years.isEmpty ? '未知年份' : years}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MeloColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (differentTracks != null && differentTracks.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: MeloSpacing.xxxl),
              child: SingleChildScrollView(
                child: Text(
                  '与 ${canonicalYear ?? '规范年份'} 不一致：${differentTracks.join('、')}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: MeloColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({
    this.titleFlex = 3,
    this.albumFlex = 3,
    this.yearWidth,
  });

  final int titleFlex;
  final int albumFlex;
  final double? yearWidth;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: MeloColors.textSecondary, fontWeight: FontWeight.w700);
    return Container(
        height: MeloDimensions.desktopTrackTableHeaderHeight,
        padding: const EdgeInsets.symmetric(horizontal: MeloSpacing.md),
        color: MeloColors.surfaceMuted,
        child: Row(children: [
          SizedBox(
              width: 32,
              child: Text('#', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: MeloSpacing.md),
          Expanded(flex: titleFlex, child: Text('歌曲', style: style)),
          Expanded(flex: albumFlex, child: Text('专辑', style: style)),
          SizedBox(
              width: yearWidth ?? MeloDimensions.desktopTrackMetadataColumnWidth,
              child: Text('年份', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: MeloDimensions.desktopTrackActionColumnWidth,
              child: Text('操作', style: style, textAlign: TextAlign.center))
        ]));
  }
}
