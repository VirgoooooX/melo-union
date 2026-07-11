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
        return _QueuePreviewRow(
          entry: entry,
          selected: selected,
          playNextStatus: repository.playNextStatusForEntry(entry.entryId),
          onPlay: () => repository.playOrToggleQueueTrack(entry.track.ref),
          onPlayNext: () async {
            await repository.moveQueueEntryNext(entry.entryId);
            if (context.mounted) {
              MeloSnackbar.show(
                context: context,
                message: '已设为下一首：${entry.track.title}',
              );
            }
          },
          onRemove: () => repository.removeQueueEntry(index),
        );
      },
    );
  }
}

class _QueuePreviewRow extends StatefulWidget {
  const _QueuePreviewRow({
    required this.entry,
    required this.selected,
    required this.playNextStatus,
    required this.onPlay,
    required this.onPlayNext,
    required this.onRemove,
  });

  final PlaybackQueueEntry entry;
  final bool selected;
  final PlayNextButtonStatus playNextStatus;
  final VoidCallback onPlay;
  final VoidCallback onPlayNext;
  final VoidCallback onRemove;

  @override
  State<_QueuePreviewRow> createState() => _QueuePreviewRowState();
}

class _QueuePreviewRowState extends State<_QueuePreviewRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final showRemove = _hovered || widget.selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: widget.selected ? MeloColors.surfaceMuted : Colors.transparent,
          borderRadius: MeloRadii.sm,
          child: InkWell(
            borderRadius: MeloRadii.sm,
            onDoubleTap: widget.onPlay,
            onSecondaryTap: widget.onRemove,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  QueueTrackCover(
                    seed: widget.entry.track.title,
                    artwork: widget.entry.track.artwork,
                    isPlaying: widget.selected,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: widget.selected
                                        ? MeloColors.primary700
                                        : MeloColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.entry.track.artists.join(' / '),
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
                  MeloPlayNextButton(
                    status: widget.playNextStatus,
                    onPressed: widget.onPlayNext,
                    size: 18,
                    showTooltip: false,
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: showRemove ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !showRemove,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onRemove,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
