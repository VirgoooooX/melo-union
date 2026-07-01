part of 'local_playlists_page.dart';

class LocalPlaylistsPage extends ConsumerStatefulWidget {
  const LocalPlaylistsPage({super.key});

  @override
  ConsumerState<LocalPlaylistsPage> createState() => _LocalPlaylistsPageState();
}

class _LocalPlaylistsPageState extends ConsumerState<LocalPlaylistsPage> {
  String _selectedTab = 'local';
  String? _selectedRemotePlaylistId;
  bool _showLocalPlaylistDetails = false;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final remoteProviders = repository.providerEntries
        .where(
          (entry) =>
              entry.isEnabled &&
              entry.provider.isAuthenticated &&
              entry.descriptor.supports(ProviderCapability.readUserPlaylists),
        )
        .toList(growable: false);
    final tabs = [
      const ProviderTabItem(id: 'local', label: '本地歌单'),
      for (final entry in remoteProviders)
        ProviderTabItem(
          id: entry.descriptor.id.value,
          label: meloProviderPresentation(
            entry.descriptor.id,
            displayName: entry.descriptor.displayName,
          ).shortName,
        ),
      const ProviderTabItem(
        id: 'more',
        label: '更多平台',
        trailing: Icons.keyboard_arrow_down_rounded,
      ),
    ];
    final selected =
        tabs.any((item) => item.id == _selectedTab) ? _selectedTab : 'local';
    final isMobile = MediaQuery.sizeOf(context).width < 960;
    if (isMobile) {
      return _MobilePlaylistsView(
        tabs: tabs,
        selected: selected,
        showLocalPlaylistDetails: _showLocalPlaylistDetails,
        selectedRemotePlaylistId: _selectedRemotePlaylistId,
        repository: repository,
        onTabSelected: (id) {
          setState(() {
            _selectedTab = id;
            _selectedRemotePlaylistId = null;
            _showLocalPlaylistDetails = false;
          });
        },
        onMorePressed: () {
          MeloSnackbar.show(
            context: context,
            message: '后续 Provider 歌单会显示在这里。',
          );
        },
        onCreatePlaylist: () => _showCreateDialog(context, repository),
        onLocalSelected: (playlistId) {
          repository.selectPlaylist(playlistId);
          setState(() => _showLocalPlaylistDetails = true);
        },
        onLocalBack: () => setState(() => _showLocalPlaylistDetails = false),
        onRemoteSelected: (playlistId) =>
            setState(() => _selectedRemotePlaylistId = playlistId),
        onRemoteBack: () => setState(() => _selectedRemotePlaylistId = null),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        children: [
          ProviderTabs(
            items: tabs,
            selectedId: selected,
            onSelected: (id) {
              setState(() {
                _selectedTab = id;
                _selectedRemotePlaylistId = null;
                _showLocalPlaylistDetails = false;
              });
            },
            onMorePressed: () {
              MeloSnackbar.show(
                context: context,
                message: '后续 Provider 歌单会显示在这里。',
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(
                  width: 270,
                  child: TextField(
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: '搜索歌单'))),
              const Spacer(),
              OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('卡片视图')),
              const SizedBox(width: 8),
              FilledButton.icon(
                  onPressed: () => _showCreateDialog(context, repository),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新建歌单')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: selected == 'local'
                ? (_showLocalPlaylistDetails &&
                        repository.selectedPlaylist != null
                    ? _LocalPlaylistTracks(
                        playlist: repository.selectedPlaylist!,
                        repository: repository,
                        onBack: () =>
                            setState(() => _showLocalPlaylistDetails = false),
                      )
                    : _PlaylistGrid(
                        playlists: repository.playlistList,
                        selectedPlaylistId: repository.selectedPlaylistId,
                        onSelected: (playlistId) {
                          repository.selectPlaylist(playlistId);
                          setState(() => _showLocalPlaylistDetails = true);
                        },
                      ))
                : _RemotePlaylistsPanel(
                    providerId: ProviderId(selected),
                    selectedPlaylistId: _selectedRemotePlaylistId,
                    onSelected: (playlistId) =>
                        setState(() => _selectedRemotePlaylistId = playlistId),
                    onBack: () =>
                        setState(() => _selectedRemotePlaylistId = null),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(
      BuildContext context, DemoRepository repository) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建歌单'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '歌单名称')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('创建')),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      repository.createPlaylist(name.trim());
      if (mounted) {
        setState(() => _showLocalPlaylistDetails = true);
      }
    }
  }
}

class _MobilePlaylistsView extends StatelessWidget {
  const _MobilePlaylistsView({
    required this.tabs,
    required this.selected,
    required this.showLocalPlaylistDetails,
    required this.selectedRemotePlaylistId,
    required this.repository,
    required this.onTabSelected,
    required this.onCreatePlaylist,
    required this.onLocalSelected,
    required this.onLocalBack,
    required this.onRemoteSelected,
    required this.onRemoteBack,
    this.onMorePressed,
  });

  final List<ProviderTabItem> tabs;
  final String selected;
  final bool showLocalPlaylistDetails;
  final String? selectedRemotePlaylistId;
  final DemoRepository repository;
  final ValueChanged<String> onTabSelected;
  final VoidCallback onCreatePlaylist;
  final ValueChanged<String> onLocalSelected;
  final VoidCallback onLocalBack;
  final ValueChanged<String> onRemoteSelected;
  final VoidCallback onRemoteBack;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: ProviderTabs(
            items: tabs,
            selectedId: selected,
            onSelected: onTabSelected,
            onMorePressed: onMorePressed,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Text(
                selected == 'local' ? '本地歌单' : '云端歌单',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              if (selected == 'local')
                FilledButton.icon(
                  onPressed: onCreatePlaylist,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('新建'),
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: MeloRadii.pill,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: selected == 'local'
              ? (showLocalPlaylistDetails && repository.selectedPlaylist != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: _LocalPlaylistTracks(
                        playlist: repository.selectedPlaylist!,
                        repository: repository,
                        onBack: onLocalBack,
                      ),
                    )
                  : _MobileLocalPlaylistList(
                      repository: repository,
                      onSelected: onLocalSelected,
                    ))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _RemotePlaylistsPanel(
                    providerId: ProviderId(selected),
                    selectedPlaylistId: selectedRemotePlaylistId,
                    onSelected: onRemoteSelected,
                    onBack: onRemoteBack,
                  ),
                ),
        ),
      ],
    );
  }
}

class _MobileLocalPlaylistList extends StatelessWidget {
  const _MobileLocalPlaylistList({
    required this.repository,
    required this.onSelected,
  });

  final DemoRepository repository;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final playlists = repository.playlistList;
    if (playlists.isEmpty) {
      return const MeloEmptyState(
        icon: Icons.library_music_outlined,
        title: '还没有本地歌单',
        subtitle: '点右上角新建，把喜欢的歌加入歌单。',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 156),
      itemCount: playlists.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: MeloColors.border),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final playableTracks = [
          for (final item in playlist.items)
            if (repository.sourceTrackByRef(item.trackRef) case final track?)
              track,
        ];
        return InkWell(
          onTap: () => onSelected(playlist.id),
          borderRadius: MeloRadii.md,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: MeloPlaylistCover(title: playlist.name),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.items.length} 首 · 本地歌单',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MeloColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '播放歌单',
                  onPressed: playableTracks.isEmpty
                      ? null
                      : () => repository.playTracks(playableTracks),
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RemotePlaylistPlaceholder extends StatelessWidget {
  const _RemotePlaylistPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_outlined,
              size: 44, color: MeloColors.textTertiary),
          const SizedBox(height: 12),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: MeloColors.textSecondary)),
        ]),
      );
}
