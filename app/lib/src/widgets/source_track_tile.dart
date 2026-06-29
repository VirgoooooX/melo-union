import 'package:flutter/material.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import 'provider_badge.dart';

class SourceTrackTile extends StatelessWidget {
  const SourceTrackTile({
    required this.track,
    required this.providerName,
    required this.favoriteAvailability,
    required this.playlists,
    required this.isDownloadSupported,
    this.downloadTask,
    this.onPlay,
    this.onEnqueue,
    this.onFavoriteChanged,
    this.onAddToPlaylist,
    this.onDownload,
    this.onPauseDownload,
    this.onCancelDownload,
    super.key,
  });

  final SourceTrack track;
  final String providerName;
  final FavoriteWriteAvailability favoriteAvailability;
  final List<LocalPlaylist> playlists;
  final bool isDownloadSupported;
  final DownloadTask? downloadTask;
  final VoidCallback? onPlay;
  final VoidCallback? onEnqueue;
  final ValueChanged<bool>? onFavoriteChanged;
  final ValueChanged<String>? onAddToPlaylist;
  final VoidCallback? onDownload;
  final VoidCallback? onPauseDownload;
  final VoidCallback? onCancelDownload;

  @override
  Widget build(BuildContext context) {
    final favoriteColor =
        track.isFavorited ? const Color(0xFFF06292) : const Color(0xFF8796A5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141A21),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF262F3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${track.artists.join(' / ')} · ${_formatDuration(track.duration)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8D9BA8),
                          ),
                    ),
                    if (track.album != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        track.album!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF728190),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: track.isPlayable ? '立即播放' : '该来源不可播放',
                    onPressed: track.isPlayable ? onPlay : null,
                    icon: const Icon(Icons.play_arrow),
                  ),
                  IconButton(
                    tooltip: '加入队列',
                    onPressed: onEnqueue,
                    icon: const Icon(Icons.queue_music),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '加入本地歌单',
                    enabled: playlists.isNotEmpty && onAddToPlaylist != null,
                    onSelected: onAddToPlaylist,
                    itemBuilder: (context) => [
                      for (final playlist in playlists)
                        PopupMenuItem<String>(
                          value: playlist.id,
                          child: Text(playlist.name),
                        ),
                    ],
                    icon: const Icon(Icons.playlist_add),
                  ),
                  Tooltip(
                    message: favoriteAvailability.reason ?? '切换收藏状态',
                    child: IconButton(
                      onPressed: favoriteAvailability.isEnabled &&
                              onFavoriteChanged != null
                          ? () => onFavoriteChanged!(!track.isFavorited)
                          : null,
                      icon: Icon(
                        track.isFavorited
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: favoriteColor,
                      ),
                    ),
                  ),
                  if (!isDownloadSupported)
                    Tooltip(
                      message: '该来源不支持下载',
                      child: IconButton(
                        onPressed: null,
                        icon: const Icon(Icons.download),
                      ),
                    )
                  else if (downloadTask == null)
                    Tooltip(
                      message: '下载歌曲',
                      child: IconButton(
                        onPressed: onDownload,
                        icon: const Icon(Icons.download),
                      ),
                    )
                  else if (downloadTask!.status == DownloadStatus.queued ||
                      downloadTask!.status == DownloadStatus.paused ||
                      downloadTask!.status == DownloadStatus.failed ||
                      downloadTask!.status == DownloadStatus.cancelled)
                    Tooltip(
                      message: '开始/继续下载',
                      child: IconButton(
                        onPressed: onDownload,
                        icon: const Icon(Icons.play_arrow),
                      ),
                    )
                  else if (downloadTask!.status == DownloadStatus.downloading ||
                      downloadTask!.status == DownloadStatus.resolving)
                    Tooltip(
                      message: '暂停下载',
                      child: IconButton(
                        onPressed: onPauseDownload,
                        icon: const Icon(Icons.pause),
                      ),
                    )
                  else if (downloadTask!.status == DownloadStatus.completed)
                    const Tooltip(
                      message: '已下载到本地',
                      child: IconButton(
                        onPressed: null,
                        icon: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ),
                  if (downloadTask != null &&
                      downloadTask!.status != DownloadStatus.completed &&
                      downloadTask!.status != DownloadStatus.cancelled)
                    Tooltip(
                      message: '取消下载',
                      child: IconButton(
                        onPressed: onCancelDownload,
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ProviderBadge(
                label: providerName,
                backgroundColor: const Color(0xFF203040),
                foregroundColor: const Color(0xFFB7D5F1),
              ),
              ProviderBadge(
                label: track.isFavorited ? '来源已喜欢' : '来源未喜欢',
                backgroundColor: track.isFavorited
                    ? const Color(0xFF3A1D2A)
                    : const Color(0xFF222A31),
                foregroundColor: track.isFavorited
                    ? const Color(0xFFF6AEC8)
                    : const Color(0xFFB0BEC5),
              ),
              ProviderBadge(
                label: track.isPlayable ? '可播放' : '仅目录/补充',
                backgroundColor: track.isPlayable
                    ? const Color(0xFF1D3A33)
                    : const Color(0xFF353123),
                foregroundColor: track.isPlayable
                    ? const Color(0xFF97E2D4)
                    : const Color(0xFFE1C07A),
              ),
              if (isDownloadSupported) ...[
                if (downloadTask != null)
                  ProviderBadge(
                    label:
                        '下载: ${_statusLabel(downloadTask!.status)} ${downloadTask!.status == DownloadStatus.downloading ? "(${(downloadTask!.progress * 100).toInt()}%)" : ""}',
                    backgroundColor: _downloadStatusColor(downloadTask!.status),
                    foregroundColor: Colors.white,
                  )
                else
                  const ProviderBadge(
                    label: '可下载',
                    backgroundColor: Color(0xFF1D3C23),
                    foregroundColor: Color(0xFF97E2D4),
                  )
              ] else
                const ProviderBadge(
                  label: '不支持下载',
                  backgroundColor: Color(0xFF3A1D1D),
                  foregroundColor: Color(0xFFE29797),
                ),
            ],
          ),
          if (!favoriteAvailability.isEnabled &&
              favoriteAvailability.reason != null) ...[
            const SizedBox(height: 10),
            Text(
              '收藏不可写：${favoriteAvailability.reason}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE1C07A),
                  ),
            ),
          ],
          if (downloadTask != null && downloadTask!.error != null) ...[
            const SizedBox(height: 10),
            Text(
              '下载错误：${downloadTask!.error}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE29797),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.queued => '等待中',
      DownloadStatus.resolving => '解析中',
      DownloadStatus.downloading => '下载中',
      DownloadStatus.paused => '已暂停',
      DownloadStatus.completed => '已完成',
      DownloadStatus.failed => '失败',
      DownloadStatus.cancelled => '已取消',
    };
  }

  Color _downloadStatusColor(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.queued => const Color(0xFF3C3C1D),
      DownloadStatus.resolving => const Color(0xFF1D353C),
      DownloadStatus.downloading => const Color(0xFF1D3C23),
      DownloadStatus.paused => const Color(0xFF3C2C1D),
      DownloadStatus.completed => const Color(0xFF1D3A33),
      DownloadStatus.failed => const Color(0xFF3A1D1D),
      DownloadStatus.cancelled => const Color(0xFF2B3137),
    };
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
