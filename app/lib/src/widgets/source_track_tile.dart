import 'package:flutter/material.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../design/melo_tokens.dart';
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

  Color _getProviderBg(ProviderId providerId) {
    final val = providerId.value.toLowerCase();
    if (val.contains('aurora') || val.contains('netease')) {
      return MeloColors.neteaseBackground;
    }
    if (val.contains('beacon')) return MeloColors.qqBackground;
    if (val.contains('local')) return MeloColors.localBackground;
    return MeloColors.surfaceMuted;
  }

  Color _getProviderFg(ProviderId providerId) {
    final val = providerId.value.toLowerCase();
    if (val.contains('aurora') || val.contains('netease')) {
      return MeloColors.neteaseForeground;
    }
    if (val.contains('beacon')) return MeloColors.qqForeground;
    if (val.contains('local')) return MeloColors.localForeground;
    return MeloColors.textSecondary;
  }

  Color _downloadStatusColor(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.queued => MeloColors.warning,
      DownloadStatus.resolving => MeloColors.info,
      DownloadStatus.downloading => MeloColors.primary600,
      DownloadStatus.paused => MeloColors.warning,
      DownloadStatus.completed => MeloColors.success,
      DownloadStatus.failed => MeloColors.error,
      DownloadStatus.cancelled => MeloColors.textTertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final favoriteColor =
        track.isFavorited ? MeloColors.favorite : MeloColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
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
                            color: MeloColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${track.artists.join(' / ')} · ${_formatDuration(track.duration)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MeloColors.textSecondary,
                          ),
                    ),
                    if (track.album != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        track.album!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MeloColors.textTertiary,
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
                    const Tooltip(
                      message: '该来源不支持下载',
                      child: IconButton(
                        onPressed: null,
                        icon: Icon(Icons.download),
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
                        icon:
                            Icon(Icons.check_circle, color: MeloColors.success),
                      ),
                    ),
                  if (downloadTask != null &&
                      downloadTask!.status != DownloadStatus.completed &&
                      downloadTask!.status != DownloadStatus.cancelled)
                    Tooltip(
                      message: '取消下载',
                      child: IconButton(
                        onPressed: onCancelDownload,
                        icon: const Icon(Icons.cancel, color: MeloColors.error),
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
                backgroundColor: _getProviderBg(track.ref.providerId),
                foregroundColor: _getProviderFg(track.ref.providerId),
              ),
              ProviderBadge(
                label: track.isFavorited ? '来源已喜欢' : '来源未喜欢',
                backgroundColor: track.isFavorited
                    ? MeloColors.favorite.withValues(alpha: 0.1)
                    : MeloColors.surfaceMuted,
                foregroundColor: track.isFavorited
                    ? MeloColors.favorite
                    : MeloColors.textSecondary,
              ),
              ProviderBadge(
                label: track.isPlayable ? '可播放' : '仅目录/补充',
                backgroundColor: track.isPlayable
                    ? MeloColors.success.withValues(alpha: 0.1)
                    : MeloColors.warning.withValues(alpha: 0.1),
                foregroundColor:
                    track.isPlayable ? MeloColors.success : MeloColors.warning,
              ),
              if (isDownloadSupported) ...[
                if (downloadTask != null)
                  ProviderBadge(
                    label:
                        '下载: ${_statusLabel(downloadTask!.status)} ${downloadTask!.status == DownloadStatus.downloading ? "(${(downloadTask!.progress * 100).toInt()}%)" : ""}',
                    backgroundColor: _downloadStatusColor(downloadTask!.status)
                        .withValues(alpha: 0.1),
                    foregroundColor: _downloadStatusColor(downloadTask!.status),
                  )
                else
                  const ProviderBadge(
                    label: '可下载',
                    backgroundColor: MeloColors.primary50,
                    foregroundColor: MeloColors.primary700,
                  )
              ] else
                const ProviderBadge(
                  label: '不支持下载',
                  backgroundColor: MeloColors.surfaceMuted,
                  foregroundColor: MeloColors.textTertiary,
                ),
            ],
          ),
          if (!favoriteAvailability.isEnabled &&
              favoriteAvailability.reason != null) ...[
            const SizedBox(height: 10),
            Text(
              '收藏不可写：${favoriteAvailability.reason}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MeloColors.warning,
                  ),
            ),
          ],
          if (downloadTask != null && downloadTask!.error != null) ...[
            const SizedBox(height: 10),
            Text(
              '下载错误：${downloadTask!.error}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MeloColors.error,
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

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
