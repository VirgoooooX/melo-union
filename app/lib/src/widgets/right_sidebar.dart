import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/demo_repository.dart';
import 'provider_badge.dart';

class RightSidebar extends ConsumerWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final queue = repository.queue;
    final current = queue.current?.track;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前播放',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151C23),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF29313A)),
            ),
            child: current == null
                ? Text(
                    '队列为空',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8D9BA8),
                        ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.artists.join(' / '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF8D9BA8),
                            ),
                      ),
                      const SizedBox(height: 10),
                      ProviderBadge(
                        label: repository.registry
                                .describe(current.ref.providerId)
                                ?.displayName ??
                            current.ref.providerId.value,
                        backgroundColor: const Color(0xFF203040),
                        foregroundColor: const Color(0xFFB7D5F1),
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
                      const Divider(color: Color(0xFF29313A)),
                      const SizedBox(height: 8),
                      Text(
                        '音频流票据信息',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8D9BA8),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      if (repository.playbackCoordinator.currentError != null)
                        Text(
                          '错误: ${repository.playbackCoordinator.currentError}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFFE29797),
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
                                    color: const Color(0xFFB7D5F1),
                                  ),
                        ),
                        Text(
                          '音质: ${repository.playbackCoordinator.currentTicket!.quality.name.toUpperCase()}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF90C090),
                                  ),
                        ),
                        Text(
                          '过期时间: ${repository.playbackCoordinator.currentTicket!.expiresAt.toLocal().toString().split('.').first}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFFE1C07A),
                                  ),
                        ),
                        if (repository
                            .playbackCoordinator.currentTicket!.isExpired)
                          Text(
                            '已过期',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                      ] else
                        Text(
                          '正在加载/解析票据...',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF8D9BA8),
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
                        ? const Color(0xFF1B2630)
                        : const Color(0xFF131920),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF355064)
                          : const Color(0xFF262F3A),
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
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.track.artists.join(' / '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8D9BA8),
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
