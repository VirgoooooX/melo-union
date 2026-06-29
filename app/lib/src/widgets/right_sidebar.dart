import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../bootstrap/demo_repository.dart';
import '../design/melo_tokens.dart';
import 'provider_badge.dart';

class RightSidebar extends ConsumerWidget {
  const RightSidebar({super.key});

  Color _getProviderBg(ProviderId providerId) {
    final val = providerId.value.toLowerCase();
    if (val.contains('aurora')) return MeloColors.neteaseBackground;
    if (val.contains('beacon')) return MeloColors.qqBackground;
    if (val.contains('local')) return MeloColors.localBackground;
    return MeloColors.surfaceMuted;
  }

  Color _getProviderFg(ProviderId providerId) {
    final val = providerId.value.toLowerCase();
    if (val.contains('aurora')) return MeloColors.neteaseForeground;
    if (val.contains('beacon')) return MeloColors.qqForeground;
    if (val.contains('local')) return MeloColors.localForeground;
    return MeloColors.textSecondary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final queue = repository.queue;
    final current = queue.current?.track;

    return Container(
      decoration: const BoxDecoration(
        color: MeloColors.surface,
        border: Border(
          left: BorderSide(color: MeloColors.border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前播放',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: MeloColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MeloColors.surfaceMuted,
              borderRadius: MeloRadii.md,
              border: Border.all(color: MeloColors.border),
            ),
            child: current == null
                ? Text(
                    '队列为空',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: MeloColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.artists.join(' / '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: MeloColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      ProviderBadge(
                        label: repository.registry
                                .describe(current.ref.providerId)
                                ?.displayName ??
                            current.ref.providerId.value,
                        backgroundColor: _getProviderBg(current.ref.providerId),
                        foregroundColor: _getProviderFg(current.ref.providerId),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: repository.queuePrevious,
                            icon: const Icon(Icons.skip_previous),
                          ),
                          IconButton(
                            onPressed: repository.queueNext,
                            icon: const Icon(Icons.skip_next),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: MeloColors.border),
                      const SizedBox(height: 8),
                      Text(
                        '音频流票据信息',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MeloColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      if (repository.playbackCoordinator.currentError != null)
                        Text(
                          '错误: ${repository.playbackCoordinator.currentError}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MeloColors.error,
                                  ),
                        )
                      else if (repository.playbackCoordinator.currentTicket !=
                          null) ...[
                        Text(
                          '链接: ${repository.playbackCoordinator.currentTicket!.mediaUri}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MeloColors.info,
                                  ),
                        ),
                        Text(
                          '音质: ${repository.playbackCoordinator.currentTicket!.quality.name.toUpperCase()}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MeloColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          '过期时间: ${repository.playbackCoordinator.currentTicket!.expiresAt.toLocal().toString().split('.').first}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MeloColors.warning,
                                  ),
                        ),
                        if (repository
                            .playbackCoordinator.currentTicket!.isExpired)
                          Text(
                            '已过期',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: MeloColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                      ] else
                        Text(
                          '正在加载/解析票据...',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MeloColors.textTertiary,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(fontSize: 10),
                        ),
                        onPressed: repository.refreshPlaybackTicket,
                        icon: const Icon(Icons.refresh, size: 12),
                        label: const Text('强制刷新票据'),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            '播放队列',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: MeloColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: queue.entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = queue.entries[index];
                final isCurrent = index == queue.currentIndex;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? MeloColors.primary50
                        : MeloColors.surfaceMuted,
                    borderRadius: MeloRadii.sm,
                    border: Border.all(
                      color: isCurrent
                          ? MeloColors.primary500
                          : MeloColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCurrent ? MeloColors.primary700 : MeloColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.track.artists.join(' / '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isCurrent ? MeloColors.primary600.withOpacity(0.8) : MeloColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
