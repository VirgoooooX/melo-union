part of 'all_favorites_page.dart';

class _FavoritesList extends ConsumerWidget {
  const _FavoritesList({required this.selectedProviderId, required this.query});

  final String? selectedProviderId;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(allFavoritesProvider);
    return favorites.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('喜欢列表加载失败：$error')),
      data: (tracks) {
        final visible = tracks.where((track) {
          final providerMatch = selectedProviderId == null || track.variants.any((item) => item.ref.providerId.value == selectedProviderId);
          final queryMatch = query.isEmpty || '${track.title} ${track.artists.join(' ')}'.toLowerCase().contains(query);
          return providerMatch && queryMatch;
        }).toList(growable: false);
        if (visible.isEmpty) return const Center(child: Text('这里还没有符合条件的喜欢歌曲。'));
        return ListView.separated(
          itemCount: visible.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: MeloColors.border),
          itemBuilder: (context, index) => _FavoriteRow(index: index + 1, track: visible[index], providerId: selectedProviderId),
        );
      },
    );
  }
}
