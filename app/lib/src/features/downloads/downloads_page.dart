import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final coordinator = repository.downloadCoordinator;
    final activeTasks = coordinator.allTasks
        .where(
          (task) =>
              task.status != DownloadStatus.completed &&
              task.status != DownloadStatus.cancelled,
        )
        .toList(growable: false);
    final completedItems = coordinator.localItems;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Text(
                '离线下载与本地媒体',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              FilledButton.icon(
                onPressed: () => _addDemoTask(repository),
                icon: const Icon(Icons.add),
                label: const Text('添加演示下载任务'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _DownloadTaskPanel(
                          tasks: activeTasks,
                          repository: repository,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(child: _LocalMediaPanel(items: completedItems)),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: _DownloadTaskPanel(
                          tasks: activeTasks,
                          repository: repository,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(child: _LocalMediaPanel(items: completedItems)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static void _addDemoTask(DemoRepository repository) {
    final auroraProvider = repository.providers[ProviderId('aurora_stream')];
    if (auroraProvider == null) {
      return;
    }
    final candidates = auroraProvider.allTracks();
    final unqueued = candidates.firstWhere(
      (track) =>
          !repository.downloadCoordinator.isAvailableLocally(track.ref) &&
          repository.downloadCoordinator.getTask(track.ref) == null,
      orElse: () => candidates.first,
    );
    repository.addDownloadTask(unqueued);
  }
}

class _DownloadTaskPanel extends StatelessWidget {
  const _DownloadTaskPanel({
    required this.tasks,
    required this.repository,
  });

  final List<DownloadTask> tasks;
  final DemoRepository repository;

  @override
  Widget build(BuildContext context) {
    return _DownloadPanelFrame(
      title: '下载队列 (${tasks.length})',
      emptyText: '无活动下载任务',
      isEmpty: tasks.isEmpty,
      child: ListView.separated(
        itemCount: tasks.length,
        separatorBuilder: (context, index) => const Divider(
          color: Color(0xFF29313A),
        ),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _DownloadTaskRow(task: task, repository: repository);
        },
      ),
    );
  }
}

class _LocalMediaPanel extends StatelessWidget {
  const _LocalMediaPanel({required this.items});

  final List<LocalMediaItem> items;

  @override
  Widget build(BuildContext context) {
    return _DownloadPanelFrame(
      title: '本地音乐库 (${items.length})',
      emptyText: '无本地已下载音乐',
      isEmpty: items.isEmpty,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(
          color: Color(0xFF29313A),
        ),
        itemBuilder: (context, index) => _LocalMediaRow(item: items[index]),
      ),
    );
  }
}

class _DownloadPanelFrame extends StatelessWidget {
  const _DownloadPanelFrame({
    required this.title,
    required this.emptyText,
    required this.isEmpty,
    required this.child,
  });

  final String title;
  final String emptyText;
  final bool isEmpty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151C23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isEmpty
                  ? Center(
                      child: Text(
                        emptyText,
                        style: const TextStyle(color: Color(0xFF8D9BA8)),
                      ),
                    )
                  : child,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTaskRow extends StatelessWidget {
  const _DownloadTaskRow({
    required this.task,
    required this.repository,
  });

  final DownloadTask task;
  final DemoRepository repository;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (task.status) {
      DownloadStatus.queued => Colors.orange,
      DownloadStatus.resolving => Colors.cyan,
      DownloadStatus.downloading => Colors.green,
      DownloadStatus.paused => Colors.yellow,
      DownloadStatus.failed => Colors.red,
      DownloadStatus.completed ||
      DownloadStatus.cancelled =>
        const Color(0xFF8D9BA8),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      task.track.artists.join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8D9BA8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 2,
                children: [
                  if (task.status == DownloadStatus.queued ||
                      task.status == DownloadStatus.paused ||
                      task.status == DownloadStatus.failed)
                    IconButton(
                      tooltip: '开始/继续',
                      onPressed: () => repository.startDownload(task.track.ref),
                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                    )
                  else if (task.status == DownloadStatus.downloading ||
                      task.status == DownloadStatus.resolving)
                    IconButton(
                      tooltip: '暂停',
                      onPressed: () => repository.pauseDownload(task.track.ref),
                      icon: const Icon(Icons.pause, color: Colors.yellow),
                    ),
                  if (task.status == DownloadStatus.downloading)
                    IconButton(
                      tooltip: '模拟下载步进',
                      onPressed: () =>
                          repository.simulateDownloadProgress(task.track.ref),
                      icon: const Icon(
                        Icons.trending_flat,
                        color: Colors.blueAccent,
                      ),
                    ),
                  IconButton(
                    tooltip: '取消',
                    onPressed: () => repository.cancelDownload(task.track.ref),
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${task.status.name.toUpperCase()} ${(task.progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 11),
              ),
              if (task.error != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.error!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: task.progress,
            backgroundColor: const Color(0xFF262F3A),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ],
      ),
    );
  }
}

class _LocalMediaRow extends StatelessWidget {
  const _LocalMediaRow({required this.item});

  final LocalMediaItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${item.artists.join(' / ')} · ${_formatDuration(item.duration)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8D9BA8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.filePath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8D9BA8),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(item.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                item.downloadedAt.toLocal().toString().split(' ').first,
                style: const TextStyle(
                  color: Color(0xFF8D9BA8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
