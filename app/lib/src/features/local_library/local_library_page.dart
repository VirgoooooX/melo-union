import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../local_library/local_library_controller.dart';
import '../../widgets/melo_components.dart';
import '../../widgets/melo_local_mark.dart';
import '../../widgets/melo_track_row.dart';
import '../../widgets/provider_tabs.dart';

class LocalLibraryPage extends ConsumerStatefulWidget {
  const LocalLibraryPage({super.key});

  @override
  ConsumerState<LocalLibraryPage> createState() => _LocalLibraryPageState();
}

class _LocalLibraryPageState extends ConsumerState<LocalLibraryPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(demoRepositoryProvider);
    final controller = repository.localLibraryController;
    if (controller == null) {
      return const Center(child: Text('本地曲库仅在 Windows 桌面端提供'));
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildLibrary(context, repository, controller),
    );
  }

  Widget _buildLibrary(
    BuildContext context,
    DemoRepository repository,
    LocalLibraryController controller,
  ) {
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
          _LocalLibraryTopRail(
            scanning: controller.isScanning,
            canScan: controller.roots.isNotEmpty,
            onAddDirectory: () => _addDirectory(controller),
            onScan: controller.scanAll,
            onCancelScan: controller.cancelScan,
          ),
          const SizedBox(height: MeloSpacing.lg),
          _LibraryToolbar(
            searchController: _searchController,
            query: _searchController.text,
            visibleCount: controller.tracks.length,
            sort: controller.sort,
            onSortChanged: controller.setSort,
            onSearchChanged: (value) {
              setState(() {});
              _searchDebounce?.cancel();
              _searchDebounce = Timer(
                const Duration(milliseconds: 250),
                () => controller.reload(query: value),
              );
            },
            onClearSearch: () {
              _searchDebounce?.cancel();
              _searchController.clear();
              setState(() {});
              controller.reload(query: '');
            },
            onPlayAll: controller.tracks.isNotEmpty
                ? () => repository.playTracks([
                      for (final track in controller.tracks)
                        track.toSourceTrack(),
                    ])
                : null,
          ),
          if (controller.roots.isNotEmpty) ...[
            const SizedBox(height: MeloSpacing.md),
            _RootStrip(controller: controller),
          ],
          if (controller.progress case final progress?) ...[
            const SizedBox(height: MeloSpacing.sm),
            LinearProgressIndicator(
              value: progress.discovered == 0
                  ? null
                  : progress.processed / progress.discovered,
              color: MeloColors.localForeground,
              backgroundColor: MeloColors.localBackground,
            ),
            const SizedBox(height: MeloSpacing.xs),
            Text(
              '正在扫描 ${progress.processed}/${progress.discovered} · '
              '更新 ${progress.imported} 首',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MeloColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: MeloSpacing.md),
          Expanded(
            child: controller.loadingView,
          ),
        ],
      ),
    );
  }

  Future<void> _addDirectory(LocalLibraryController controller) async {
    final selected = await getDirectoryPath(confirmButtonText: '导入此目录');
    if (selected != null) await controller.addRoot(selected);
  }
}

class _LocalLibraryTopRail extends StatelessWidget {
  const _LocalLibraryTopRail({
    required this.scanning,
    required this.canScan,
    required this.onAddDirectory,
    required this.onScan,
    required this.onCancelScan,
  });

  final bool scanning;
  final bool canScan;
  final VoidCallback onAddDirectory;
  final VoidCallback onScan;
  final VoidCallback onCancelScan;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: ProviderTabs(
              items: const [
                ProviderTabItem(
                  id: localMusicProviderIdValue,
                  label: '本地曲库',
                  leading: MeloLocalMark(size: 18),
                ),
              ],
              selectedId: localMusicProviderIdValue,
              onSelected: (_) {},
            ),
          ),
          IconButton(
            tooltip: '添加目录',
            onPressed: scanning ? null : onAddDirectory,
            icon: const Icon(Icons.create_new_folder_outlined, size: 20),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(
                MeloDimensions.desktopToolbarControlHeight,
              ),
              backgroundColor: MeloColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: MeloRadii.sm,
                side: BorderSide(color: MeloColors.border),
              ),
            ),
          ),
          const SizedBox(width: MeloSpacing.toolbarControlGap),
          IconButton(
            tooltip: scanning ? '停止扫描' : '重新扫描',
            onPressed: scanning
                ? onCancelScan
                : canScan
                    ? onScan
                    : null,
            icon: Icon(
              scanning ? Icons.stop_circle_outlined : Icons.refresh_rounded,
              size: 20,
            ),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(
                MeloDimensions.desktopToolbarControlHeight,
              ),
              backgroundColor: MeloColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: MeloRadii.sm,
                side: BorderSide(color: MeloColors.border),
              ),
            ),
          ),
        ],
      );
}

extension on LocalLibraryController {
  Widget get loadingView {
    if (isLoading && tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (roots.isEmpty) return const _EmptyLibrary();
    return _TrackList(controller: this);
  }
}

class _TrackList extends ConsumerWidget {
  const _TrackList({required this.controller});

  final LocalLibraryController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (controller.tracks.isEmpty) {
      return const Center(child: Text('没有找到匹配的本地歌曲'));
    }
    final repository = ref.read(demoRepositoryProvider);
    final currentRef = ref.watch(
      demoRepositoryProvider.select((repo) => repo.queue.current?.track.ref),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.lg,
        border: Border.all(color: MeloColors.border),
        boxShadow: MeloShadows.card,
      ),
      child: ClipRRect(
        borderRadius: MeloRadii.lg,
        child: Column(
          children: [
            const _LocalLibraryTableHeader(),
            const Divider(height: 1, color: MeloColors.border),
            Expanded(
              child: ListView.builder(
                itemCount:
                    controller.tracks.length + (controller.hasMore ? 1 : 0),
                itemExtent: MeloListMetrics.rowHeight,
                itemBuilder: (context, index) {
                  if (index == controller.tracks.length) {
                    return Center(
                      child: TextButton.icon(
                        onPressed:
                            controller.isLoading ? null : controller.loadMore,
                        icon: const Icon(Icons.expand_more_rounded),
                        label: const Text('加载更多'),
                      ),
                    );
                  }
                  final local = controller.tracks[index];
                  final track = local.toSourceTrack();
                  return MeloDesktopTrackRow(
                    index: index + 1,
                    title: track.title,
                    artists: track.artists,
                    artwork: track.artwork,
                    album: track.album ?? '未知专辑',
                    year: local.year?.toString() ?? '—',
                    isActive: currentRef == track.ref,
                    // 播放时再校验文件，以便失效曲目能显示具体错误。
                    onDoubleTap: () => unawaited(
                      repository.playOrToggleTrack(track),
                    ),
                    trailing: SizedBox(
                      width: MeloDimensions.desktopTrackActionColumnWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!local.isAvailable)
                            const Tooltip(
                              message: '文件不存在或磁盘不可用',
                              child: Icon(
                                Icons.link_off_rounded,
                                color: MeloColors.warning,
                                size: 18,
                              ),
                            )
                          else
                            MeloTrackMoreMenu(track: track),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalLibraryTableHeader extends StatelessWidget {
  const _LocalLibraryTableHeader();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: MeloColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        );
    return Container(
      height: MeloDimensions.desktopTrackTableHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: MeloSpacing.md),
      color: MeloColors.surfaceMuted,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#', style: labelStyle, textAlign: TextAlign.center),
          ),
          const SizedBox(width: MeloSpacing.md),
          Expanded(flex: 3, child: Text('歌曲', style: labelStyle)),
          Expanded(flex: 3, child: Text('专辑', style: labelStyle)),
          SizedBox(
            width: MeloDimensions.desktopTrackMetadataColumnWidth,
            child: Text('年份', style: labelStyle, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: MeloDimensions.desktopTrackActionColumnWidth,
            child: Text('操作', style: labelStyle, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({
    required this.searchController,
    required this.query,
    required this.visibleCount,
    required this.sort,
    required this.onSortChanged,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.onPlayAll,
  });

  final TextEditingController searchController;
  final String query;
  final int visibleCount;
  final LocalLibrarySortOrder sort;
  final ValueChanged<LocalLibrarySortOrder> onSortChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onPlayAll;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            '共 $visibleCount 首歌曲',
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
              alignment: Alignment.center,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
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
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: MeloColors.textSecondary,
                    size: 20,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: MeloDimensions.desktopToolbarControlHeight,
                    minHeight: MeloDimensions.desktopToolbarControlHeight,
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清除搜索',
                          onPressed: onClearSearch,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: MeloColors.textSecondary,
                            size: 16,
                          ),
                        ),
                  hintText: '搜索歌曲、歌手或专辑',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MeloColors.textTertiary,
                      ),
                  contentPadding: const EdgeInsets.only(
                    right: MeloSpacing.sm,
                    top: 2,
                    bottom: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: MeloSpacing.toolbarControlGap),
          _LocalSortButton(sort: sort, onSelected: onSortChanged),
          const SizedBox(width: MeloSpacing.toolbarControlGap),
          FilledButton.icon(
            onPressed: onPlayAll,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('播放全部'),
            style: FilledButton.styleFrom(
              fixedSize: const Size.fromHeight(
                MeloDimensions.desktopToolbarControlHeight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: MeloSpacing.md),
              shape: const RoundedRectangleBorder(borderRadius: MeloRadii.sm),
              elevation: 0,
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      );
}

class _LocalSortButton extends StatefulWidget {
  const _LocalSortButton({required this.sort, required this.onSelected});

  final LocalLibrarySortOrder sort;
  final ValueChanged<LocalLibrarySortOrder> onSelected;

  @override
  State<_LocalSortButton> createState() => _LocalSortButtonState();
}

class _LocalSortButtonState extends State<_LocalSortButton> {
  final GlobalKey<PopupMenuButtonState<LocalLibrarySortOrder>> _menuKey =
      GlobalKey();

  @override
  Widget build(BuildContext context) => PopupMenuButton<LocalLibrarySortOrder>(
        key: _menuKey,
        tooltip: '排序',
        onSelected: widget.onSelected,
        offset: const Offset(0, MeloSpacing.page),
        shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
        itemBuilder: (context) => [
          for (final item in LocalLibrarySortOrder.values)
            PopupMenuItem(
              value: item,
              child: Row(
                children: [
                  Icon(
                    item == widget.sort
                        ? Icons.check_rounded
                        : Icons.sort_rounded,
                    size: 18,
                    color: item == widget.sort
                        ? MeloColors.localForeground
                        : MeloColors.textTertiary,
                  ),
                  const SizedBox(width: MeloSpacing.toolbarControlGap),
                  Text(_localSortLabel(item)),
                ],
              ),
            ),
        ],
        child: IconButton(
          tooltip: '排序',
          onPressed: () => _menuKey.currentState?.showButtonMenu(),
          icon: const Icon(
            Icons.tune_rounded,
            size: 20,
            color: MeloColors.textSecondary,
          ),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(
              MeloDimensions.desktopToolbarControlHeight,
            ),
            backgroundColor: MeloColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: MeloRadii.sm,
              side: BorderSide(color: MeloColors.border),
            ),
          ),
        ),
      );
}

String _localSortLabel(LocalLibrarySortOrder sort) => switch (sort) {
      LocalLibrarySortOrder.album => '按专辑',
      LocalLibrarySortOrder.title => '按歌曲',
      LocalLibrarySortOrder.artist => '按歌手',
    };

class _RootStrip extends StatelessWidget {
  const _RootStrip({required this.controller});
  final LocalLibraryController controller;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.roots.length,
          separatorBuilder: (_, __) => const SizedBox(width: MeloSpacing.xxs),
          itemBuilder: (context, index) {
            final root = controller.roots[index];
            return _RootTabButton(
              root: root,
              enabled: !controller.isScanning,
              onTap: () => controller.scanRoot(root.id),
              onRemove: () => controller.removeRoot(root.id),
            );
          },
        ),
      );
}

class _RootTabButton extends StatefulWidget {
  const _RootTabButton({
    required this.root,
    required this.enabled,
    required this.onTap,
    required this.onRemove,
  });

  final LocalLibraryRoot root;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  State<_RootTabButton> createState() => _RootTabButtonState();
}

class _RootTabButtonState extends State<_RootTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered && widget.enabled
        ? MeloColors.textPrimary
        : widget.enabled
            ? MeloColors.textSecondary
            : MeloColors.textTertiary;
    return Tooltip(
      message: widget.root.path,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        // 保持扫描和删除手势为兄弟节点，避免点击竞争。
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: widget.enabled ? widget.onTap : null,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.transparent,
                      width: 3.0,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MeloLocalMark(size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(
                      widget.root.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            // 扫描期间也可删除；控制器会先终止扫描。
            Padding(
              padding: const EdgeInsets.only(right: 10, left: 4),
              child: Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: widget.onRemove,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: _hovered
                          ? MeloColors.textSecondary
                          : MeloColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: MeloColors.localBackground,
                borderRadius: MeloRadii.xl,
              ),
              alignment: Alignment.center,
              child: const MeloLocalMark(size: 56),
            ),
            const SizedBox(height: MeloSpacing.lg),
            Text('把音乐留在原处', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: MeloSpacing.xs),
            Text(
              '添加一个或多个目录，MeloUnion 只建立索引，不移动文件。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
}
