import 'package:flutter/material.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../design/melo_tokens.dart';
import '../presentation/provider_presentation.dart';
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
        track.isFavorited ? MeloColors.favorite : MeloColors.textTertiary;
    final providerPresentation = meloProviderPresentation(
      track.ref.providerId,
      displayName: providerName,
    );

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
                backgroundColor: providerPresentation.backgroundColor,
                foregroundColor: providerPresentation.foregroundColor,
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
              const ProviderBadge(
                label: '下载暂不提供',
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
