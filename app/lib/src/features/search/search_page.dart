import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../widgets/source_track_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'midnight');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(demoRepositoryProvider);
    final repository = ref.read(demoRepositoryProvider);
    final query = _controller.text.trim();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '搜索',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: MeloColors.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '结果只路由到已启用且声明 search capability 的 Provider。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '搜索歌曲、艺人或目录补充来源',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (query.isEmpty)
          const _SearchHint()
        else
          FutureBuilder<List<ProviderSearchResults>>(
            future: repository.search(query),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }
                return const Center(child: CircularProgressIndicator());
              }

              final groups = snapshot.data!;
              if (groups.isEmpty) {
                return const _SearchHint(
                  message: '当前查询没有命中任何可搜索来源。',
                );
              }

              return Column(
                children: [
                  for (final group in groups) ...[
                    _SearchResultGroup(
                      providerName: group.provider.displayName,
                      tracks: group.tracks,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _SearchResultGroup extends ConsumerWidget {
  const _SearchResultGroup({
    required this.providerName,
    required this.tracks,
  });

  final String providerName;
  final List<SourceTrack> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            providerName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: MeloColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${tracks.length} 条结果',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MeloColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          for (final track in tracks) ...[
            SourceTrackTile(
              track: track,
              providerName: providerName,
              favoriteAvailability: repository.favoriteWriteAvailability(
                track.ref.providerId,
              ),
              playlists: repository.playlistList,
              isDownloadSupported: repository.registry
                      .describe(track.ref.providerId)
                      ?.supports(ProviderCapability.resolveDownload) ??
                  false,
              downloadTask: repository.downloadCoordinator.getTask(track.ref),
              onPlay:
                  track.isPlayable ? () => repository.playTrack(track) : null,
              onEnqueue: () => repository.enqueueTrack(track),
              onAddToPlaylist: (playlistId) => repository.addTrackToPlaylist(
                playlistId: playlistId,
                track: track,
              ),
              onDownload: () {
                repository.addDownloadTask(track);
                repository.startDownload(track.ref);
              },
              onPauseDownload: () => repository.pauseDownload(track.ref),
              onCancelDownload: () => repository.cancelDownload(track.ref),
              onFavoriteChanged: (liked) async {
                try {
                  await repository.toggleFavorite(track: track, liked: liked);
                } on ProviderException catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({
    this.message = '默认查询已填入 `midnight`，方便直接看到同曲多来源和目录型补充来源。',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MeloColors.surfaceMuted,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MeloColors.textSecondary,
            ),
      ),
    );
  }
}
