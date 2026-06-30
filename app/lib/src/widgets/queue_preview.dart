part of 'right_sidebar.dart';

class _QueuePreview extends ConsumerWidget {
  const _QueuePreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final queue = repository.queue;
    if (queue.entries.isEmpty) return const Center(child: Text('队列为空'));
    return ListView.builder(
      itemCount: queue.entries.length,
      itemBuilder: (context, index) {
        final entry = queue.entries[index];
        final selected = index == queue.currentIndex;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: selected ? MeloColors.surfaceMuted : Colors.transparent,
            borderRadius: MeloRadii.sm,
            child: InkWell(
              borderRadius: MeloRadii.sm,
              onDoubleTap: () =>
                  repository.playOrToggleQueueTrack(entry.track.ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Row(
                  children: [
                    QueueTrackCover(
                      seed: entry.track.title,
                      artwork: entry.track.artwork,
                      isPlaying: selected,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: selected
                                      ? MeloColors.primary700
                                      : MeloColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.track.artists.join(' / '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: MeloColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
