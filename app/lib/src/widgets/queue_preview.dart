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
        return ListTile(
          selected: selected,
          onTap: () => repository.selectTrackInQueue(entry.track.ref),
          leading: QueueTrackCover(
            seed: entry.track.title,
            artwork: entry.track.artwork,
            isPlaying: selected,
          ),
          title: Text(
            entry.track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            entry.track.artists.join(' / '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
