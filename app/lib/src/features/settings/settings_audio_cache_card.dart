part of 'settings_page.dart';

class _AudioCacheSettingsCard extends ConsumerWidget {
  const _AudioCacheSettingsCard();

  static const _presets = <int>[
    512 * 1024 * 1024,
    1024 * 1024 * 1024,
    2 * 1024 * 1024 * 1024,
    5 * 1024 * 1024 * 1024,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final policy = repository.audioCachePolicy;
    if (policy == null) return const SizedBox.shrink();
    final selected =
        _presets.contains(policy.maxBytes) ? policy.maxBytes : policy.maxBytes;
    return _SettingsCard(
      title: '歌曲缓存',
      subtitle:
          '已缓存 ${repository.audioCacheTrackCount} 首，占用 ${_formatBytes(repository.audioCacheBytes)} / ${_formatBytes(policy.maxBytes)}。',
      leading: Icons.storage_rounded,
      child: Column(
        children: [
          _SettingsSwitchRow(
            title: '自动缓存已播放歌曲',
            subtitle: '完整播放流会保存在本机，后续相同或更低请求音质直接复用。',
            value: policy.enabled,
            onChanged: repository.setAudioCacheEnabled,
          ),
          if (Platform.isAndroid) ...[
            const _SettingsDivider(),
            _SettingsSwitchRow(
              title: '仅 Wi-Fi 自动缓存',
              subtitle: '移动网络仍可在线播放，但不会主动保存整首歌曲。',
              value: policy.wifiOnly,
              onChanged: repository.setAudioCacheWifiOnly,
            ),
          ],
          const _SettingsDivider(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '缓存上限',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '空间全局共享，超过后按最近使用时间自动清理。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MeloColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MeloSpacing.sm),
              DropdownButton<int>(
                value: selected,
                items: [
                  for (final bytes in _presets)
                    DropdownMenuItem(
                        value: bytes, child: Text(_formatBytes(bytes))),
                  if (!_presets.contains(selected))
                    DropdownMenuItem(
                      value: selected,
                      child: Text(_formatBytes(selected)),
                    ),
                ],
                onChanged: (bytes) {
                  if (bytes != null) {
                    unawaited(repository.setAudioCacheMaxBytes(bytes));
                  }
                },
              ),
              IconButton(
                tooltip: '自定义缓存上限',
                onPressed: () =>
                    _showCustomCacheLimit(context, repository, policy.maxBytes),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: MeloSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _showAudioCacheManager(context, repository),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('管理缓存'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCustomCacheLimit(
  BuildContext context,
  DemoRepository repository,
  int currentBytes,
) async {
  final controller = TextEditingController(
    text: (currentBytes / (1024 * 1024)).round().toString(),
  );
  final value = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('自定义缓存上限'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration:
            const InputDecoration(labelText: 'MB', hintText: '256 - 51200'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, int.tryParse(controller.text.trim())),
          child: const Text('确定'),
        ),
      ],
    ),
  );
  if (value == null) return;
  await repository.setAudioCacheMaxBytes(value * 1024 * 1024);
}

Future<void> _showAudioCacheManager(
  BuildContext context,
  DemoRepository repository,
) async {
  final entries = repository.audioCacheBytesByProvider.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  final action = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('管理歌曲缓存'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('缓存文件可安全删除；主动下载的音乐不会受影响。',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: MeloSpacing.sm),
            for (final entry in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: MeloPlatformIcon(providerId: entry.key),
                title: Text(meloProviderLabel(entry.key)),
                subtitle: Text(_formatBytes(entry.value)),
                trailing: IconButton(
                  tooltip: '清除此来源缓存',
                  onPressed: () =>
                      Navigator.pop(context, 'provider:${entry.key.value}'),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: MeloSpacing.md),
                child: Text('暂无自动缓存的歌曲。'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        FilledButton.tonalIcon(
          onPressed:
              entries.isEmpty ? null : () => Navigator.pop(context, 'all'),
          icon: const Icon(Icons.delete_sweep_outlined, size: 18),
          label: const Text('清空全部'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (action == null) return;
  final providerId =
      action == 'all' ? null : ProviderId(action.replaceFirst('provider:', ''));
  final target = providerId == null ? '全部自动缓存' : meloProviderLabel(providerId);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('确认清理缓存'),
      content: Text('将删除$target，主动下载的音乐不会受影响。'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('清理'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await repository.clearAudioCache(providerId: providerId);
  }
}
