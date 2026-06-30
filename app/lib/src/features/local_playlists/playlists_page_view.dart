part of 'local_playlists_page.dart';

class LocalPlaylistsPage extends ConsumerStatefulWidget {
  const LocalPlaylistsPage({super.key});

  @override
  ConsumerState<LocalPlaylistsPage> createState() => _LocalPlaylistsPageState();
}

class _LocalPlaylistsPageState extends ConsumerState<LocalPlaylistsPage> {
  String _selectedTab = 'local';
  String? _selectedRemotePlaylistId;

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
          label: _providerLabel(entry.descriptor.id),
        ),
      const ProviderTabItem(
        id: 'more',
        label: '更多平台',
        trailing: Icons.keyboard_arrow_down_rounded,
      ),
    ];
    final selected =
        tabs.any((item) => item.id == _selectedTab) ? _selectedTab : 'local';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        children: [
          ProviderTabs(
            items: tabs,
            selectedId: selected,
            onSelected: (id) {
              if (id == 'more') {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('后续 Provider 歌单会显示在这里。')));
              } else {
                setState(() {
                  _selectedTab = id;
                  _selectedRemotePlaylistId = null;
                });
              }
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
                ? _PlaylistGrid(playlists: repository.playlistList)
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
    }
  }
}

String _providerLabel(ProviderId id) {
  if (id.value.contains('netease')) return '网易云';
  if (id.value.contains('beacon')) return 'QQ音乐';
  return id.value;
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
