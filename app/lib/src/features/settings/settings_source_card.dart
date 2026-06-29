part of 'settings_page.dart';

class _MusicSourcesSettings extends ConsumerWidget {
  const _MusicSourcesSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final sources = repository.providerEntries
        .where((entry) => entry.descriptor.supports(ProviderCapability.authenticate))
        .toList(growable: false);
    return ListView(
      children: [
        Text(
          '音乐来源',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '登录并启用后，来源会按能力参与喜欢、歌单、推荐、搜索和下载。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        for (final entry in sources) ...[
          _MusicSourceCard(entry: entry),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          title: const Text('高级：来源兼容信息'),
          subtitle: const Text('用于查看当前演示 Provider 的能力和调试状态。'),
          children: [
            for (final entry in sources)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AdvancedSourceInfo(entry: entry),
              ),
          ],
        ),
      ],
    );
  }
}

class _MusicSourceCard extends ConsumerWidget {
  const _MusicSourceCard({required this.entry});

  final ProviderRegistryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final descriptor = entry.descriptor;
    final name = _sourceName(descriptor.id);
    final signedIn = entry.provider.isAuthenticated;
    final canSyncFavorites = descriptor.supports(ProviderCapability.readFavorites);
    final isNetease = descriptor.id.value.contains('aurora');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.lg,
        border: Border.all(color: MeloColors.border),
      ),
      child: Row(
        children: [
          _SourceIcon(isNetease: isNetease),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: signedIn ? '已登录' : '未登录',
                      positive: signedIn,
                    ),
                    if (!entry.isEnabled) ...[
                      const SizedBox(width: 6),
                      const _StatusChip(label: '已停用', positive: false),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  signedIn
                      ? '同步状态：${canSyncFavorites ? '喜欢歌曲和歌单可刷新' : '仅提供部分内容'}'
                      : '登录后可读取此来源的可用内容。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: entry.isEnabled,
            onChanged: (value) => repository.setProviderEnabled(descriptor.id, value),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _showSourceDialog(context, entry),
            child: const Text('管理'),
          ),
        ],
      ),
    );
  }

  void _showSourceDialog(BuildContext context, ProviderRegistryEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) => _SourceManagementDialog(entry: entry),
    );
  }
}

class _SourceManagementDialog extends ConsumerWidget {
  const _SourceManagementDialog({required this.entry});

  final ProviderRegistryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final name = _sourceName(entry.descriptor.id);
    final signedIn = entry.provider.isAuthenticated;
    return AlertDialog(
      title: Text('管理 $name'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              signedIn ? '当前账号已登录。' : '当前未登录。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '后续真实 Provider 接入后，此处将提供二维码登录、会话状态、同步时间和账号移除操作。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MeloColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: () {
            repository.toggleProviderAuthentication(entry.descriptor.id);
            Navigator.pop(context);
          },
          icon: Icon(signedIn ? Icons.logout_rounded : Icons.login_rounded),
          label: Text(signedIn ? '退出登录' : '登录'),
        ),
      ],
    );
  }
}

class _AdvancedSourceInfo extends StatelessWidget {
  const _AdvancedSourceInfo({required this.entry});

  final ProviderRegistryEntry entry;

  @override
  Widget build(BuildContext context) {
    final values = entry.descriptor.capabilities.map((item) => item.label).join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MeloColors.surfaceMuted,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: Text(
        '${_sourceName(entry.descriptor.id)}：$values',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MeloColors.textSecondary,
              height: 1.45,
            ),
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.isNetease});

  final bool isNetease;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isNetease ? MeloColors.neteaseBackground : MeloColors.qqBackground,
        borderRadius: MeloRadii.md,
      ),
      child: Icon(
        isNetease ? Icons.cloud_queue_rounded : Icons.music_note_rounded,
        color: isNetease ? MeloColors.neteaseForeground : MeloColors.qqForeground,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? MeloColors.success : MeloColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: positive ? MeloColors.primary50 : MeloColors.surfaceMuted,
        borderRadius: MeloRadii.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String _sourceName(ProviderId id) {
  if (id.value.contains('aurora')) return '网易云音乐';
  if (id.value.contains('beacon')) return 'QQ音乐';
  return id.value;
}
