part of 'settings_page.dart';

enum _SettingsSection {
  sources('音乐来源', Icons.account_tree_outlined),
  playback('播放设置', Icons.play_circle_outline),
  downloads('下载设置', Icons.download_outlined),
  appearance('外观与快捷键', Icons.palette_outlined),
  about('关于', Icons.info_outline);

  const _SettingsSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  _SettingsSection _selected = _SettingsSection.sources;
  bool _autoPlay = true;
  bool _rememberQueue = true;
  bool _wifiOnly = false;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1120;
    final mobile = MediaQuery.sizeOf(context).width < 960;
    final repository = ref.watch(demoRepositoryProvider);
    if (mobile) {
      return _MobileMineView(
        playbackQuality: repository.playbackQuality,
        onPlaybackQualityChanged: repository.setPlaybackQuality,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsHeader(section: _selected),
          const SizedBox(height: MeloSpacing.lg),
          Expanded(
            child: compact
                ? Column(
                    children: [
                      _SettingsNav(
                        selected: _selected,
                        horizontal: true,
                        onSelected: (value) =>
                            setState(() => _selected = value),
                      ),
                      const SizedBox(height: MeloSpacing.md),
                      Expanded(
                        child: _SettingsContent(
                          section: _selected,
                          autoPlay: _autoPlay,
                          rememberQueue: _rememberQueue,
                          wifiOnly: _wifiOnly,
                          playbackQuality: repository.playbackQuality,
                          onAutoPlayChanged: (value) =>
                              setState(() => _autoPlay = value),
                          onRememberQueueChanged: (value) =>
                              setState(() => _rememberQueue = value),
                          onWifiOnlyChanged: (value) =>
                              setState(() => _wifiOnly = value),
                          onPlaybackQualityChanged:
                              repository.setPlaybackQuality,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 224,
                        child: _SettingsNav(
                          selected: _selected,
                          onSelected: (value) =>
                              setState(() => _selected = value),
                        ),
                      ),
                      const SizedBox(width: MeloSpacing.xl),
                      Expanded(
                        child: _SettingsContent(
                          section: _selected,
                          autoPlay: _autoPlay,
                          rememberQueue: _rememberQueue,
                          wifiOnly: _wifiOnly,
                          playbackQuality: repository.playbackQuality,
                          onAutoPlayChanged: (value) =>
                              setState(() => _autoPlay = value),
                          onRememberQueueChanged: (value) =>
                              setState(() => _rememberQueue = value),
                          onWifiOnlyChanged: (value) =>
                              setState(() => _wifiOnly = value),
                          onPlaybackQualityChanged:
                              repository.setPlaybackQuality,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MobileMineView extends ConsumerWidget {
  const _MobileMineView({
    required this.playbackQuality,
    required this.onPlaybackQualityChanged,
  });

  final AudioQuality playbackQuality;
  final Future<void> Function(AudioQuality quality) onPlaybackQualityChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final sources = repository.providerEntries
        .where((entry) =>
            entry.descriptor.supports(ProviderCapability.authenticate) ||
            repository.sessionActionFor(entry.descriptor.id) != null)
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
      children: [
        Row(
          children: [
            const MeloLogoMark(size: 40),
            const SizedBox(width: MeloSpacing.sm),
            Expanded(
              child: Text(
                '我的',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '账号来源、播放偏好和应用信息。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
        const SizedBox(height: 18),
        const _MineSectionTitle('账号与来源'),
        const SizedBox(height: 10),
        for (final entry in sources) ...[
          _MobileSourceSummaryCard(entry: entry),
          const SizedBox(height: 10),
        ],
        const _MobileMoreSourcesCard(),
        const SizedBox(height: 18),
        const _MineSectionTitle('播放偏好'),
        const SizedBox(height: 10),
        _SettingsCard(
          title: '默认音质',
          subtitle: '新解析的播放链接会优先使用此音质。',
          leading: Icons.high_quality_rounded,
          child: _QualitySelector(
            value: playbackQuality,
            onChanged: onPlaybackQualityChanged,
          ),
        ),
        const SizedBox(height: 10),
        _SettingsCard(
          title: '下载功能',
          subtitle: '管理下载队列、本地音乐和默认下载音质。',
          leading: Icons.download_done_outlined,
          trailing: Icons.chevron_right_rounded,
          onTap: () => context.go(AppDestination.downloads.path),
        ),
        const SizedBox(height: 18),
        const _MineSectionTitle('应用信息'),
        const SizedBox(height: 10),
        const _AboutLogoCard(),
        const SizedBox(height: 10),
        const _SettingsCard(
          title: '版本',
          subtitle: 'v$appDisplayVersion ($appVersion)',
          leading: Icons.info_outline_rounded,
        ),
      ],
    );
  }
}

class _MineSectionTitle extends StatelessWidget {
  const _MineSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _MobileSourceSummaryCard extends ConsumerWidget {
  const _MobileSourceSummaryCard({required this.entry});

  final ProviderRegistryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final descriptor = entry.descriptor;
    final presentation = meloProviderPresentation(
      descriptor.id,
      displayName: descriptor.displayName,
    );
    final signedIn = entry.provider.isAuthenticated;
    final canSyncFavorites =
        descriptor.supports(ProviderCapability.readFavorites);
    return InkWell(
      borderRadius: MeloRadii.lg,
      onTap: () => _showSourceDialog(context),
      child: _SettingsSurface(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _SourceIcon(presentation: presentation),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          presentation.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      _StatusChip(
                        label: signedIn ? '已登录' : '未登录',
                        positive: signedIn,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    signedIn
                        ? (canSyncFavorites ? '喜欢和歌单可同步' : '已连接，提供部分内容')
                        : '点按管理登录、导入 Cookie 或清除会话',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: '管理账号',
              onPressed: () => _showSourceDialog(context),
              icon: const Icon(Icons.manage_accounts_rounded),
            ),
            Switch.adaptive(
              value: entry.isEnabled,
              onChanged: (value) =>
                  repository.setProviderEnabled(descriptor.id, value),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _SourceManagementDialog(entry: entry),
    );
  }
}

class _MobileMoreSourcesCard extends ConsumerWidget {
  const _MobileMoreSourcesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: MeloRadii.lg,
      onTap: () => _showAddSourceSheet(context),
      child: _SettingsSurface(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: MeloColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '更多账号来源',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '添加新的音乐平台账号或自定义 Provider。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  void _showAddSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '添加账号来源',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MeloColors.surfaceMuted,
                  borderRadius: MeloRadii.md,
                  border: Border.all(color: MeloColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.extension_outlined,
                      color: MeloColors.textTertiary,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '暂无可添加来源',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '当前移动端只开放网易云音乐和 QQ 音乐账号入口。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MeloColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.section});

  final _SettingsSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: MeloColors.primary50,
            borderRadius: MeloRadii.md,
          ),
          child: Icon(section.icon, color: MeloColors.primary700, size: 22),
        ),
        const SizedBox(width: MeloSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '设置',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '管理音乐来源、播放行为与应用偏好。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsNav extends StatelessWidget {
  const _SettingsNav({
    required this.selected,
    required this.onSelected,
    this.horizontal = false,
  });

  final _SettingsSection selected;
  final ValueChanged<_SettingsSection> onSelected;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final section in _SettingsSection.values)
        _SettingsNavItem(
          section: section,
          selected: section == selected,
          horizontal: horizontal,
          onTap: () => onSelected(section),
        ),
    ];

    final content = horizontal
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: items),
          )
        : Column(children: items);

    return _SettingsSurface(
      padding: EdgeInsets.all(horizontal ? MeloSpacing.xs : MeloSpacing.sm),
      child: content,
    );
  }
}

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.section,
    required this.selected,
    required this.horizontal,
    required this.onTap,
  });

  final _SettingsSection section;
  final bool selected;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MeloColors.primary700 : MeloColors.textPrimary;
    return Padding(
      padding: EdgeInsets.only(
        right: horizontal ? MeloSpacing.xs : 0,
        bottom: horizontal ? 0 : MeloSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: MeloRadii.sm,
        child: Ink(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: MeloSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? MeloColors.primary50 : Colors.transparent,
            borderRadius: MeloRadii.sm,
            border: Border.all(
              color: selected ? MeloColors.primary100 : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: horizontal ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(section.icon, color: color, size: 19),
              const SizedBox(width: MeloSpacing.xs),
              Text(
                section.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.section,
    required this.autoPlay,
    required this.rememberQueue,
    required this.wifiOnly,
    required this.playbackQuality,
    required this.onAutoPlayChanged,
    required this.onRememberQueueChanged,
    required this.onWifiOnlyChanged,
    required this.onPlaybackQualityChanged,
  });

  final _SettingsSection section;
  final bool autoPlay;
  final bool rememberQueue;
  final bool wifiOnly;
  final AudioQuality playbackQuality;
  final ValueChanged<bool> onAutoPlayChanged;
  final ValueChanged<bool> onRememberQueueChanged;
  final ValueChanged<bool> onWifiOnlyChanged;
  final Future<void> Function(AudioQuality quality) onPlaybackQualityChanged;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      _SettingsSection.sources => const _MusicSourcesSettings(),
      _SettingsSection.playback => _SettingsPanel(
          title: '播放设置',
          subtitle: '控制默认音质、启动恢复和队列保留策略。',
          children: [
            _SettingsCard(
              title: '默认音质',
              subtitle: '新解析的播放链接会优先使用此音质；当前歌曲会在可用时重新解析。',
              leading: Icons.high_quality_rounded,
              child: _QualitySelector(
                value: playbackQuality,
                onChanged: onPlaybackQualityChanged,
              ),
            ),
            const SizedBox(height: MeloSpacing.md),
            _SettingsCard(
              title: '播放行为',
              subtitle: '这些开关先作为本机偏好呈现，后续会随队列恢复一起持久化。',
              leading: Icons.queue_music_rounded,
              child: Column(
                children: [
                  _SettingsSwitchRow(
                    title: '启动后恢复播放状态',
                    subtitle: '重新打开应用时恢复上一次播放上下文。',
                    value: autoPlay,
                    onChanged: onAutoPlayChanged,
                  ),
                  const _SettingsDivider(),
                  _SettingsSwitchRow(
                    title: '记住播放队列',
                    subtitle: '保留当前队列与播放位置。',
                    value: rememberQueue,
                    onChanged: onRememberQueueChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      _SettingsSection.downloads => _SettingsPanel(
          title: '下载设置',
          subtitle: '管理离线下载的保存位置和默认策略。',
          children: [
            const _DownloadLocationSettingsCard(),
          ],
        ),
      _SettingsSection.appearance => const _SettingsPanel(
          title: '外观与快捷键',
          subtitle: '当前使用浅色桌面布局和自定义标题栏。',
          children: [
            _SettingsCard(
              title: '主题',
              subtitle: '浅色 · 深色主题将在完整 Variant 中启用。',
              leading: Icons.light_mode_rounded,
            ),
            SizedBox(height: MeloSpacing.md),
            _SettingsCard(
              title: '快捷键',
              subtitle: 'Space 播放/暂停 · Ctrl+K 打开搜索。',
              leading: Icons.keyboard_rounded,
            ),
          ],
        ),
      _SettingsSection.about => _SettingsPanel(
          title: '关于 MeloUnion',
          subtitle: '一个可扩展 Provider 的统一音乐库与播放客户端。',
          children: [
            const _AboutLogoCard(),
            const SizedBox(height: MeloSpacing.md),
            _SettingsCard(
              title: '版本',
              subtitle: 'v$appDisplayVersion',
              leading: Icons.info_outline_rounded,
            ),
            const SizedBox(height: MeloSpacing.md),
            const _SettingsCard(
              title: '数据边界',
              subtitle: '登录凭证仅保存在本机安全存储中；播放票据不会写入快照。',
              leading: Icons.lock_outline_rounded,
            ),
          ],
        ),
    };
  }
}

class _AboutLogoCard extends StatelessWidget {
  const _AboutLogoCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsSurface(
      child: Row(
        children: [
          const MeloLogoMark(size: 54),
          const SizedBox(width: MeloSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MeloUnion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '麦乐聚合音乐客户端',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadLocationSettingsCard extends ConsumerWidget {
  const _DownloadLocationSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    return FutureBuilder<String>(
      future: repository.downloadDirectoryPath(),
      builder: (context, snapshot) {
        final directory = snapshot.data ?? '正在读取保存位置...';
        return _SettingsCard(
          title: '保存位置',
          subtitle: directory,
          leading: Icons.folder_open_rounded,
          child: Wrap(
            spacing: MeloSpacing.xs,
            runSpacing: MeloSpacing.xs,
            children: [
              FilledButton.icon(
                onPressed: () => _showDownloadDirectoryDialog(
                  context,
                  repository,
                  directory: snapshot.data,
                ),
                icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                label: const Text('修改位置'),
              ),
              OutlinedButton.icon(
                onPressed: snapshot.hasData
                    ? () async {
                        try {
                          await repository.revealDownloadDirectory();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('无法打开保存位置')),
                            );
                          }
                        }
                      }
                    : null,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('打开文件夹'),
              ),
              OutlinedButton.icon(
                onPressed: repository.customDownloadDirectory == null
                    ? null
                    : () async {
                        await repository.setDownloadDirectory(null);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已恢复默认保存位置')),
                          );
                        }
                      },
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('恢复默认'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDownloadDirectoryDialog(
    BuildContext context,
    DemoRepository repository, {
    required String? directory,
  }) async {
    final controller = TextEditingController(
      text: repository.customDownloadDirectory ?? directory ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置下载位置'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '文件夹路径',
            hintText: r'C:\Music\MeloUnion',
          ),
          minLines: 1,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('恢复默认'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !context.mounted) return;

    try {
      await repository.setDownloadDirectory(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.trim().isEmpty ? '已恢复默认保存位置' : '已更新保存位置'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存位置不可用：$error')),
        );
      }
    }
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
        const SizedBox(height: MeloSpacing.md),
        ...children,
      ],
    );
  }
}

class _SettingsSurface extends StatelessWidget {
  const _SettingsSurface({
    required this.child,
    this.padding = const EdgeInsets.all(MeloSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MeloColors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: MeloRadii.lg,
        side: BorderSide(color: MeloColors.border),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.leading,
    this.child,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData leading;
  final Widget? child;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = _SettingsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: MeloColors.primary50,
                  borderRadius: MeloRadii.sm,
                ),
                child: Icon(leading, color: MeloColors.primary700, size: 20),
              ),
              const SizedBox(width: MeloSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MeloColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: MeloSpacing.sm),
                Icon(trailing, color: MeloColors.textTertiary, size: 20),
              ],
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: MeloSpacing.md),
            child!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MeloSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MeloSpacing.md),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: MeloSpacing.lg, color: MeloColors.border);
  }
}

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({required this.value, required this.onChanged});

  final AudioQuality value;
  final Future<void> Function(AudioQuality quality) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: MeloSpacing.sm,
      runSpacing: MeloSpacing.sm,
      children: [
        for (final quality in AudioQuality.values)
          _QualityOption(
            quality: quality,
            selected: quality == value,
            onSelected: onChanged,
          ),
      ],
    );
  }
}

class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.quality,
    required this.selected,
    required this.onSelected,
  });

  final AudioQuality quality;
  final bool selected;
  final Future<void> Function(AudioQuality quality) onSelected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MeloColors.primary700 : MeloColors.textPrimary;
    return InkWell(
      onTap: selected
          ? null
          : () {
              onSelected(quality);
            },
      borderRadius: MeloRadii.md,
      child: Ink(
        width: 150,
        padding: const EdgeInsets.all(MeloSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? MeloColors.primary50 : MeloColors.surfaceMuted,
          borderRadius: MeloRadii.md,
          border: Border.all(
            color: selected ? MeloColors.primary300 : MeloColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.graphic_eq_rounded,
              color: selected ? MeloColors.primary700 : MeloColors.textTertiary,
              size: 18,
            ),
            const SizedBox(width: MeloSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _qualityLabel(quality),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    _qualityDescription(quality),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MeloColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _qualityLabel(AudioQuality quality) => switch (quality) {
      AudioQuality.low => '标准',
      AudioQuality.standard => '较高',
      AudioQuality.high => '极高',
      AudioQuality.lossless => '无损',
    };

String _qualityDescription(AudioQuality quality) => switch (quality) {
      AudioQuality.low => '省流量',
      AudioQuality.standard => '均衡',
      AudioQuality.high => '高码率',
      AudioQuality.lossless => '优先无损',
    };
