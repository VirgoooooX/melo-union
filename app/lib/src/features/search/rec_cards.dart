part of 'search_page.dart';

class _RecommendationList extends ConsumerWidget {
  const _RecommendationList({required this.tracks});
  final List<SourceTrack> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    if (tracks.isEmpty) return const Center(child: Text('当前来源暂未提供推荐内容。'));
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: MeloColors.border),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
                borderRadius: MeloRadii.sm,
                gradient: LinearGradient(
                    colors: [Color(0xFF7D8CD0), Color(0xFF42A5A0)])),
            child: const Icon(Icons.music_note_rounded, color: Colors.white),
          ),
          title: Text(track.title,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle:
              Text('${track.artists.join(' / ')} · ${track.album ?? '推荐单曲'}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                onPressed: () => repository.playTrack(track),
                icon: const Icon(Icons.play_arrow_rounded)),
            IconButton(
                onPressed: () => repository.toggleFavorite(
                    track: track, liked: !track.isFavorited),
                icon: Icon(
                    track.isFavorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: track.isFavorited
                        ? MeloColors.favorite
                        : MeloColors.textTertiary)),
          ]),
        );
      },
    );
  }
}
