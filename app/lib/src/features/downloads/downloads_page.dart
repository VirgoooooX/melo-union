import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../widgets/melo_components.dart';

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  AudioQuality _quality = AudioQuality.standard;

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(demoRepositoryProvider);
    final tasks = ref.watch(
      demoRepositoryProvider.select(
        (r) => r.downloadCoordinator.allTasks
            .where((task) =>
                task.status != DownloadStatus.completed &&
                task.status != DownloadStatus.cancelled)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      ),
    );
    final localItems = ref.watch(
      demoRepositoryProvider.select(
        (r) => r.downloadCoordinator.localItems
          ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt)),
      ),
    );
    final compact = MediaQuery.sizeOf(context).width < 960;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? MeloSpacing.md : 28,
        compact ? MeloSpacing.sm : MeloSpacing.lg,
        compact ? MeloSpacing.md : 28,
        compact ? 108 : MeloSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DownloadsHeader(
            quality: _quality,
            onQualityChanged: (value) => setState(() => _quality = value),
          ),
          const SizedBox(height: MeloSpacing.sm),
          const _DownloadDirectoryNotice(),
          const SizedBox(height: MeloSpacing.lg),
          Expanded(
            child: tasks.isEmpty && localItems.isEmpty
                ? const MeloEmptyState(
                    icon: Icons.download_done_outlined,
                    title: '还没有下载内容',
                    subtitle: '在喜欢、歌单、推荐或搜索结果中打开歌曲菜单，选择“下载”。',
                  )
                : ListView(
                    children: [
                      if (tasks.isNotEmpty) ...[
                        _SectionTitle(
                          title: '下载队列',
                          subtitle: '${tasks.length} 个任务',
                        ),
                        const SizedBox(height: MeloSpacing.xs),
                        for (final task in tasks) ...[
                          _DownloadTaskRow(
                            task: task,
                            onStart: () => repository.startDownload(
                              task.track.ref,
                            ),
                            onPause: () => repository.pauseDownload(
                              task.track.ref,
                            ),
                            onCancel: () => repository.cancelDownload(
                              task.track.ref,
                            ),
                          ),
                          const SizedBox(height: MeloSpacing.xs),
                        ],
                        const SizedBox(height: MeloSpacing.sm),
                      ],
                      if (localItems.isNotEmpty) ...[
                        _SectionTitle(
                          title: '本地音乐',
                          subtitle: '${localItems.length} 首已下载',
                        ),
                        const SizedBox(height: MeloSpacing.xs),
                        for (final item in localItems) ...[
                          _LocalMediaRow(
                            item: item,
                            onDelete: () =>
                                repository.removeLocalMedia(item.sourceRef),
                            onRedownload: () => repository.redownloadLocalMedia(
                              item.sourceRef,
                              quality: _quality,
                            ),
                          ),
                          const SizedBox(height: MeloSpacing.xs),
                        ],
                        const SizedBox(height: MeloSpacing.sm),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DownloadsHeader extends StatelessWidget {
  const _DownloadsHeader({
    required this.quality,
    required this.onQualityChanged,
  });

  final AudioQuality quality;
  final ValueChanged<AudioQuality> onQualityChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: MeloColors.primary50,
            borderRadius: MeloRadii.md,
          ),
          child: const Icon(
            Icons.download_done_rounded,
            color: MeloColors.primary700,
          ),
        ),
        const SizedBox(width: MeloSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '下载',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '下载会从歌曲菜单立即开始；这里显示队列和已保存的本地音乐。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: MeloSpacing.sm),
        DropdownButton<AudioQuality>(
          value: quality,
          onChanged: (value) {
            if (value != null) onQualityChanged(value);
          },
          items: [
            for (final item in AudioQuality.values)
              DropdownMenuItem(
                value: item,
                child: Text(_qualityLabel(item)),
              ),
          ],
        ),
      ],
    );
  }
}

class _DownloadDirectoryNotice extends ConsumerWidget {
  const _DownloadDirectoryNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    return FutureBuilder<String>(
      future: repository.downloadDirectoryPath(),
      builder: (context, snapshot) {
        final directory = snapshot.data ?? '正在读取保存位置...';
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MeloSpacing.sm,
            vertical: MeloSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: MeloColors.surface,
            borderRadius: MeloRadii.md,
            border: Border.all(color: MeloColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.folder_open_rounded,
                color: MeloColors.primary700,
                size: 20,
              ),
              const SizedBox(width: MeloSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '保存位置',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MeloColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      directory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MeloSpacing.sm),
              TextButton.icon(
                onPressed: snapshot.hasData
                    ? () async {
                        try {
                          await repository.revealDownloadDirectory();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('无法打开保存位置')),
                            );
                          }
                        }
                      }
                    : null,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('打开'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(width: MeloSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _DownloadTaskRow extends StatelessWidget {
  const _DownloadTaskRow({
    required this.task,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
  });

  final DownloadTask task;
  final Future<void> Function() onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _DownloadSurface(
      child: Row(
        children: [
          MeloTrackCover(seed: task.track.title, artwork: task.track.artwork),
          const SizedBox(width: MeloSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: MeloSpacing.xxs),
                Text(
                  '${task.track.artists.join(' / ')} · ${_qualityLabel(task.quality)} · ${_statusLabel(task.status)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.textSecondary,
                      ),
                ),
                if (task.error != null) ...[
                  const SizedBox(height: MeloSpacing.xxs),
                  Text(
                    task.error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.error,
                        ),
                  ),
                ],
                if (task.status == DownloadStatus.downloading ||
                    task.status == DownloadStatus.resolving) ...[
                  const SizedBox(height: MeloSpacing.xs),
                  LinearProgressIndicator(
                    value: task.status == DownloadStatus.resolving
                        ? null
                        : task.progress.clamp(0, 1).toDouble(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: MeloSpacing.xs),
          _TaskActions(
            status: task.status,
            onStart: onStart,
            onPause: onPause,
            onCancel: onCancel,
          ),
        ],
      ),
    );
  }
}

class _TaskActions extends StatelessWidget {
  const _TaskActions({
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
  });

  final DownloadStatus status;
  final Future<void> Function() onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final canStart = status == DownloadStatus.queued ||
        status == DownloadStatus.paused ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.cancelled;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canStart)
          _DownloadActionIconButton(
            tooltip: status == DownloadStatus.failed ? '重试' : '开始下载',
            onPressed: () => onStart(),
            icon: Icon(status == DownloadStatus.failed
                ? Icons.refresh_rounded
                : Icons.download_for_offline_rounded),
            emphasized: true,
          ),
        if (status == DownloadStatus.downloading ||
            status == DownloadStatus.resolving)
          Padding(
            padding: const EdgeInsets.only(left: MeloSpacing.xs),
            child: _DownloadActionIconButton(
              tooltip: '暂停',
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: MeloSpacing.xs),
          child: _DownloadActionIconButton(
            tooltip: '取消任务',
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }
}

class _LocalMediaRow extends StatelessWidget {
  const _LocalMediaRow({
    required this.item,
    required this.onDelete,
    required this.onRedownload,
  });

  final LocalMediaItem item;
  final VoidCallback onDelete;
  final VoidCallback onRedownload;

  @override
  Widget build(BuildContext context) {
    return _DownloadSurface(
      child: Row(
        children: [
          const Icon(Icons.offline_pin_rounded, color: MeloColors.success),
          const SizedBox(width: MeloSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: MeloSpacing.xxs),
                Text(
                  '${item.artists.join(' / ')} · ${_formatBytes(item.fileSize)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DownloadActionIconButton(
                tooltip: '重新下载',
                onPressed: onRedownload,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: MeloSpacing.xs),
              _DownloadActionIconButton(
                tooltip: '删除本地文件记录',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DownloadActionIconButton extends StatelessWidget {
  const _DownloadActionIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.emphasized = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(
        backgroundColor:
            emphasized ? MeloColors.primary50 : MeloColors.surfaceMuted,
        foregroundColor:
            emphasized ? MeloColors.primary700 : MeloColors.textSecondary,
        hoverColor: emphasized ? MeloColors.primary100 : MeloColors.border,
        highlightColor:
            emphasized ? MeloColors.primary100 : MeloColors.borderStrong,
        shape: RoundedRectangleBorder(borderRadius: MeloRadii.sm),
      ),
    );
  }
}

class _DownloadSurface extends StatelessWidget {
  const _DownloadSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MeloSpacing.sm),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
        boxShadow: MeloShadows.card,
      ),
      child: child,
    );
  }
}

String _qualityLabel(AudioQuality quality) => switch (quality) {
      AudioQuality.low => '标准',
      AudioQuality.standard => '较高',
      AudioQuality.high => '极高',
      AudioQuality.lossless => '无损',
    };

String _statusLabel(DownloadStatus status) => switch (status) {
      DownloadStatus.queued => '等待中',
      DownloadStatus.resolving => '解析链接',
      DownloadStatus.downloading => '下载中',
      DownloadStatus.paused => '已暂停',
      DownloadStatus.completed => '已完成',
      DownloadStatus.failed => '失败',
      DownloadStatus.cancelled => '已取消',
    };

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}
