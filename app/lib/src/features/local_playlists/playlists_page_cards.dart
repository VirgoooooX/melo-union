part of 'local_playlists_page.dart';

class _PlaylistGrid extends ConsumerWidget {
  const _PlaylistGrid({required this.playlists});
  final List<LocalPlaylist> playlists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final width = MediaQuery.sizeOf(context).width;
    final count = width >= 1240
        ? 4
        : width >= 980
            ? 3
            : 2;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: .92,
      ),
      itemCount: playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const _CreatePlaylistCard();
        final playlist = playlists[index - 1];
        final selected = playlist.id == repository.selectedPlaylistId;
        return InkWell(
          onTap: () => repository.selectPlaylist(playlist.id),
          borderRadius: MeloRadii.lg,
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MeloColors.surface,
              borderRadius: MeloRadii.lg,
              border: Border.all(
                  color: selected ? MeloColors.primary500 : MeloColors.border),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: MeloRadii.md,
                    gradient: LinearGradient(
                        colors: [Color(0xFF3AAEAA), Color(0xFF5B7DBA)]),
                  ),
                  child: const Icon(Icons.queue_music_rounded,
                      size: 46, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${playlist.items.length} 首 · 混合',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: MeloColors.textSecondary)),
            ]),
          ),
        );
      },
    );
  }
}

class _CreatePlaylistCard extends StatelessWidget {
  const _CreatePlaylistCard();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: MeloColors.surfaceMuted,
            borderRadius: MeloRadii.lg,
            border:
                Border.all(color: MeloColors.border, style: BorderStyle.solid)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_circle_outline_rounded,
              size: 38, color: MeloColors.primary600),
          const SizedBox(height: 10),
          Text('新建本地歌单',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MeloColors.primary700, fontWeight: FontWeight.w700)),
        ]),
      );
}
