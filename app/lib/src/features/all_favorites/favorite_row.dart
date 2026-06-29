part of 'all_favorites_page.dart';

class _FavoriteRow extends ConsumerWidget {
  const _FavoriteRow({required this.index, required this.track, required this.providerId});

  final int index;
  final UnifiedFavoriteTrack track;
  final String? providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final variants = providerId == null
        ? track.variants
        : track.variants.where((item) => item.ref.providerId.value == providerId).toList(growable: false);
    final primary = variants.first;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => repository.playUnifiedTrack(track),
        child: SizedBox(
          height: 66,
          child: Row(children: [
            SizedBox(width: 34, child: Text('$index'.padLeft(2, '0'))),
            _TrackCover(seed: track.title),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: _TrackIdentity(track: track)),
            Expanded(flex: 2, child: Text(primary.album ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 124, child: Wrap(spacing: 4, runSpacing: 4, children: [for (final item in variants) _SourceTag(provider: item.ref.providerId)])),
            SizedBox(width: 48, child: Text(formatDuration(track.duration))),
            IconButton(
              tooltip: '收藏',
              onPressed: () => _toggle(context, repository, primary),
              icon: Icon(primary.isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: primary.isFavorited ? MeloColors.favorite : MeloColors.textTertiary),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, DemoRepository repository, SourceTrack track) async {
    try {
      await repository.toggleFavorite(track: track, liked: !track.isFavorited);
    } on ProviderException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _TrackIdentity extends StatelessWidget {
  const _TrackIdentity({required this.track});
  final UnifiedFavoriteTrack track;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(track.artists.join(' / '), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MeloColors.textSecondary)),
        ],
      );
}
