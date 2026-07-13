import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../local_library/local_library_controller.dart';
import '../../local_library/local_library_scanner.dart';
import '../../local_library/artist_metadata_enrichment_service.dart';
import '../../local_library/artist_metadata_image_cache.dart';
import '../../presentation/shell_accent.dart';
import '../../widgets/melo_local_mark.dart';
import '../../widgets/provider_tabs.dart';
import 'local_library_views.dart';

class LocalLibraryPage extends ConsumerStatefulWidget {
  const LocalLibraryPage({super.key});

  @override
  ConsumerState<LocalLibraryPage> createState() => _LocalLibraryPageState();
}

class _LocalLibraryPageState extends ConsumerState<LocalLibraryPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  ArtistMetadataEnrichmentService? _enrichment;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _enrichment?.imageCache.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = ref.watch(demoRepositoryProvider);
    final controller = appRepository.localLibraryController;
    if (controller == null) {
      return const Center(child: Text('本地曲库仅在 Windows 桌面端提供'));
    }
    _enrichment ??= ArtistMetadataEnrichmentService(
      repository: controller.repository,
      providerEntries: appRepository.providerEntries,
      imageCache: ArtistMetadataImageCache(
        directory: Directory(
          '${controller.scanner.artworkDirectory.path}'
          '${Platform.pathSeparator}artist_metadata',
        ),
      ),
      onMetadataUpdated: (artistKey) =>
          controller.view == LocalLibraryView.artists
              ? controller.refreshArtist(artistKey)
              : null,
    );
    return MeloShellAccentScope(
      providerId: localMusicProviderIdValue,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.view == LocalLibraryView.artists &&
              controller.artists.isNotEmpty) {
            _enrichment!.enqueue(controller.artists);
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              MeloSpacing.xl,
              MeloSpacing.lg,
              MeloSpacing.xl,
              MeloSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ViewTabs(controller: controller),
                const SizedBox(height: MeloSpacing.md),
                _Toolbar(
                  controller: controller,
                  search: _search,
                  onManage: () => _manageRoots(controller),
                  onSearch: (value) {
                    setState(() {});
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 250),
                        () => controller.reload(query: value));
                  },
                  onPlayAll: () =>
                      _playVisible(appRepository, controller, shuffle: false),
                  onShuffle: () =>
                      _playVisible(appRepository, controller, shuffle: true),
                ),
                const SizedBox(height: MeloSpacing.lg),
                Expanded(child: _body(appRepository, controller)),
                if (controller.progress case final progress?)
                  _ScanBar(progress: progress, onCancel: controller.cancelScan),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(
      DemoRepository appRepository, LocalLibraryController controller) {
    if (controller.isLoading && controller.stats.trackCount == 0) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.roots.isEmpty) return const _EmptyLibrary();
    return switch (controller.view) {
      LocalLibraryView.songs => LocalSongsView(controller: controller),
      LocalLibraryView.albums => LocalAlbumsView(controller: controller),
      LocalLibraryView.artists => LocalArtistsView(
          controller: controller,
          enrichment: _enrichment,
        ),
    };
  }

  Future<void> _playVisible(
      DemoRepository repository, LocalLibraryController controller,
      {required bool shuffle}) async {
    List<LocalLibraryTrack> tracks;
    switch (controller.view) {
      case LocalLibraryView.songs:
        tracks = [...controller.tracks];
      case LocalLibraryView.albums:
        tracks = [];
        for (final album in controller.albums) {
          tracks.addAll(await controller.tracksForAlbum(album.albumKey));
        }
      case LocalLibraryView.artists:
        tracks = [];
        for (final artist in controller.artists) {
          tracks.addAll(await controller.tracksForArtist(artist.artistKey));
        }
    }
    if (shuffle) tracks.shuffle();
    if (tracks.isNotEmpty) {
      await repository
          .playTracks(tracks.map((track) => track.toSourceTrack()).toList());
    }
  }

  Future<void> _manageRoots(LocalLibraryController controller) =>
      showDialog<void>(
        context: context,
        builder: (context) => _RootsDialog(
            controller: controller,
            onAdd: () async {
              final selected =
                  await getDirectoryPath(confirmButtonText: '导入此目录');
              if (selected != null) await controller.addRoot(selected);
            }),
      );
}

class _ViewTabs extends StatelessWidget {
  const _ViewTabs({required this.controller});
  final LocalLibraryController controller;
  @override
  Widget build(BuildContext context) => ProviderTabs(
        items: [
          ProviderTabItem(
            id: LocalLibraryView.songs.name,
            label: '歌曲 ${controller.stats.trackCount}',
            leading: const Icon(Icons.music_note_rounded, size: 18),
          ),
          ProviderTabItem(
            id: LocalLibraryView.albums.name,
            label: '专辑 ${controller.stats.albumCount}',
            leading: const Icon(Icons.album_outlined, size: 18),
          ),
          ProviderTabItem(
            id: LocalLibraryView.artists.name,
            label: '歌手 ${controller.stats.artistCount}',
            leading: const Icon(Icons.person_outline_rounded, size: 18),
          ),
        ],
        selectedId: controller.view.name,
        onSelected: (id) => controller.setView(
          LocalLibraryView.values.byName(id),
        ),
      );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar(
      {required this.controller,
      required this.search,
      required this.onManage,
      required this.onSearch,
      required this.onPlayAll,
      required this.onShuffle});
  final LocalLibraryController controller;
  final TextEditingController search;
  final VoidCallback onManage;
  final ValueChanged<String> onSearch;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;
  @override
  Widget build(BuildContext context) {
    final count = switch (controller.view) {
      LocalLibraryView.songs => controller.stats.trackCount,
      LocalLibraryView.albums => controller.stats.albumCount,
      LocalLibraryView.artists => controller.stats.artistCount,
    };
    final unit = switch (controller.view) {
      LocalLibraryView.songs => '首歌曲',
      LocalLibraryView.albums => '张专辑',
      LocalLibraryView.artists => '位歌手',
    };
    return Row(children: [
      Text(
        '共 $count $unit',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MeloColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
      const Spacer(),
      SizedBox(
          width: MeloDimensions.desktopToolbarSearchWidth,
          child: Container(
            height: MeloDimensions.desktopToolbarControlHeight,
            decoration: BoxDecoration(
              color: MeloColors.surface,
              borderRadius: MeloRadii.sm,
              border: Border.all(color: MeloColors.border),
            ),
            child: TextField(
                controller: search,
                onChanged: onSearch,
                textAlignVertical: TextAlignVertical.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: MeloColors.textSecondary, size: 20),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: MeloDimensions.desktopToolbarControlHeight,
                      minHeight: MeloDimensions.desktopToolbarControlHeight,
                    ),
                    hintText: '搜索歌曲、歌手或专辑',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MeloColors.textTertiary,
                        ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '清除搜索',
                            onPressed: () {
                              search.clear();
                              onSearch('');
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close_rounded,
                                color: MeloColors.textSecondary, size: 16)),
                    contentPadding: const EdgeInsets.only(
                      right: MeloSpacing.sm,
                      top: 2,
                      bottom: 2,
                    ))),
          )),
      const SizedBox(width: MeloSpacing.toolbarControlGap),
      _SortMenu(controller: controller),
      const SizedBox(width: MeloSpacing.toolbarControlGap),
      IconButton(
          tooltip: controller.isScanning ? '停止扫描' : '重新扫描',
          onPressed: controller.isScanning
              ? controller.cancelScan
              : controller.roots.isEmpty
                  ? null
                  : controller.scanAll,
          style: _toolbarIconStyle(),
          icon: Icon(controller.isScanning
              ? Icons.stop_circle_outlined
              : Icons.sync_rounded)),
      const SizedBox(width: MeloSpacing.toolbarControlGap),
      IconButton(
          tooltip: '管理目录',
          onPressed: onManage,
          style: _toolbarIconStyle(),
          icon: const Icon(Icons.folder_open_outlined)),
      const SizedBox(width: MeloSpacing.toolbarControlGap),
      IconButton(
          tooltip: '随机播放',
          onPressed: controller.stats.trackCount == 0 ? null : onShuffle,
          style: _toolbarIconStyle(),
          icon: const Icon(Icons.shuffle_rounded)),
      const SizedBox(width: MeloSpacing.toolbarControlGap),
      FilledButton.icon(
          onPressed: controller.stats.trackCount == 0 ? null : onPlayAll,
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('播放全部'),
          style: FilledButton.styleFrom(
            fixedSize: const Size.fromHeight(
              MeloDimensions.desktopToolbarControlHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: MeloSpacing.md),
            shape: const RoundedRectangleBorder(borderRadius: MeloRadii.sm),
            elevation: 0,
          )),
    ]);
  }
}

ButtonStyle _toolbarIconStyle() => IconButton.styleFrom(
      fixedSize: const Size.square(MeloDimensions.desktopToolbarControlHeight),
      backgroundColor: MeloColors.surface,
      foregroundColor: MeloColors.textSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: MeloRadii.sm,
        side: BorderSide(color: MeloColors.border),
      ),
    );

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.controller});
  final LocalLibraryController controller;
  @override
  Widget build(BuildContext context) {
    final menu = switch (controller.view) {
      LocalLibraryView.songs => PopupMenuButton<LocalLibrarySortOrder>(
          tooltip: '排序',
          offset: const Offset(0, MeloSpacing.page),
          shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
          onSelected: controller.setSort,
          itemBuilder: (_) => LocalLibrarySortOrder.values
              .map((v) => PopupMenuItem(
                  value: v,
                  child: Text(switch (v) {
                    LocalLibrarySortOrder.album => '按专辑',
                    LocalLibrarySortOrder.title => '按歌曲',
                    LocalLibrarySortOrder.artist => '按歌手'
                  })))
              .toList(),
          child: const _SortButtonFace()),
      LocalLibraryView.albums => PopupMenuButton<LocalAlbumSortOrder>(
          tooltip: '排序',
          offset: const Offset(0, MeloSpacing.page),
          shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
          onSelected: controller.setAlbumSort,
          itemBuilder: (_) => LocalAlbumSortOrder.values
              .map((v) => PopupMenuItem(value: v, child: Text(_albumSort(v))))
              .toList(),
          child: const _SortButtonFace()),
      LocalLibraryView.artists => PopupMenuButton<LocalArtistSortOrder>(
          tooltip: '排序',
          offset: const Offset(0, MeloSpacing.page),
          shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
          onSelected: controller.setArtistSort,
          itemBuilder: (_) => LocalArtistSortOrder.values
              .map((v) => PopupMenuItem(value: v, child: Text(_artistSort(v))))
              .toList(),
          child: const _SortButtonFace()),
    };
    return menu;
  }
}

class _SortButtonFace extends StatelessWidget {
  const _SortButtonFace();

  @override
  Widget build(BuildContext context) => Container(
        width: MeloDimensions.desktopToolbarControlHeight,
        height: MeloDimensions.desktopToolbarControlHeight,
        decoration: BoxDecoration(
          color: MeloColors.surface,
          borderRadius: MeloRadii.sm,
          border: Border.all(color: MeloColors.border),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.sort_rounded,
          size: 20,
          color: MeloColors.textSecondary,
        ),
      );
}

class _ScanBar extends StatelessWidget {
  const _ScanBar({required this.progress, required this.onCancel});
  final LocalLibraryScanProgress progress;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(top: MeloSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: MeloSpacing.md, vertical: MeloSpacing.xs),
      decoration: const BoxDecoration(
          color: MeloColors.localBackground, borderRadius: MeloRadii.sm),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LinearProgressIndicator(
              value: progress.discovered == 0
                  ? null
                  : progress.processed / progress.discovered),
          const SizedBox(height: MeloSpacing.xxs),
          Text(
              '正在扫描 ${progress.processed}/${progress.discovered} · 更新 ${progress.imported} 首',
              style: Theme.of(context).textTheme.bodySmall)
        ])),
        TextButton(onPressed: onCancel, child: const Text('取消'))
      ]));
}

class _RootsDialog extends StatelessWidget {
  const _RootsDialog({required this.controller, required this.onAdd});
  final LocalLibraryController controller;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('管理音乐目录'),
        content: SizedBox(
          width: 620,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final root in controller.roots)
              ListTile(
                leading: const Icon(Icons.folder_rounded),
                title: Text(root.displayName),
                subtitle: Text(root.lastError ?? root.path,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      tooltip: '扫描',
                      onPressed: controller.isScanning
                          ? null
                          : () => controller.scanRoot(root.id),
                      icon: const Icon(Icons.refresh_rounded)),
                  IconButton(
                      tooltip: '移除索引（不会删除文件）',
                      onPressed: () => controller.removeRoot(root.id),
                      icon: const Icon(Icons.delete_outline_rounded)),
                ]),
              ),
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('添加音乐目录'))),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('完成'))
        ],
      );
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
                color: MeloColors.localBackground, borderRadius: MeloRadii.xl),
            alignment: Alignment.center,
            child: const MeloLocalMark(size: 56)),
        const SizedBox(height: MeloSpacing.lg),
        Text('把音乐留在原处', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: MeloSpacing.xs),
        const Text('通过“管理目录”添加音乐文件夹；MeloUnion 只建立索引，不移动文件。')
      ]));
}

String _albumSort(LocalAlbumSortOrder value) => switch (value) {
      LocalAlbumSortOrder.artist => '按歌手',
      LocalAlbumSortOrder.title => '按专辑',
      LocalAlbumSortOrder.year => '按年份',
      LocalAlbumSortOrder.recentlyAdded => '最近添加',
      LocalAlbumSortOrder.trackCount => '按歌曲数'
    };
String _artistSort(LocalArtistSortOrder value) => switch (value) {
      LocalArtistSortOrder.name => '按名称',
      LocalArtistSortOrder.albumCount => '按专辑数',
      LocalArtistSortOrder.trackCount => '按歌曲数',
      LocalArtistSortOrder.recentlyAdded => '最近添加'
    };
