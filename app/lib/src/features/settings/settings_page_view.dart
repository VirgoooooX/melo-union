part of 'settings_page.dart';

enum _SettingsSection {
  sources('音乐来源', Icons.account_tree_outlined),
  playback('播放设置', Icons.play_circle_outline),
  downloads('下载设置', Icons.download_outlined),
  backup('备份与恢复', Icons.backup_outlined),
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
                          wifiOnly: _wifiOnly,
                          playbackQuality: repository.playbackQuality,
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
                          wifiOnly: _wifiOnly,
                          playbackQuality: repository.playbackQuality,
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
    final signedInSources =
        sources.where((entry) => entry.provider.isAuthenticated).length;
    final enabledSources = sources.where((entry) => entry.isEnabled).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
      children: [
        _MobileMineHero(
          signedInSources: signedInSources,
          enabledSources: enabledSources,
        ),
        const SizedBox(height: 22),
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
          title: '播放恢复',
          subtitle: '保留队列和进度；重新打开后不会自动播放。',
          leading: Icons.queue_music_rounded,
          child: Column(
            children: [
              _SettingsSwitchRow(
                title: '记住播放队列',
                subtitle: '保留当前播放列表、当前歌曲、循环和随机播放状态。',
                value: repository.rememberQueue,
                onChanged: repository.setRememberQueue,
              ),
              const _SettingsDivider(),
              _SettingsSwitchRow(
                title: '启动后恢复播放进度',
                subtitle: '回到上次播放的歌曲和进度，点播放后继续。',
                value:
                    repository.restorePlaybackState && repository.rememberQueue,
                onChanged: repository.rememberQueue
                    ? repository.setRestorePlaybackState
                    : null,
              ),
            ],
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
        const SizedBox(height: 10),
        _SettingsCard(
          title: '备份与恢复',
          subtitle: '导出 zip 备份或使用 WebDAV 保存数据快照。',
          leading: Icons.backup_outlined,
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showMobileBackupSheet(context),
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

class _MobileMineHero extends StatelessWidget {
  const _MobileMineHero({
    required this.signedInSources,
    required this.enabledSources,
  });

  final int signedInSources;
  final int enabledSources;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '我的',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: MeloColors.textPrimary,
                        fontSize: 48,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
              ),
              const MeloLogoMark(size: 48),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MineHeroStat(
                  icon: Icons.verified_user_outlined,
                  value: signedInSources.toString(),
                  label: '已登录',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MineHeroStat(
                  icon: Icons.radio_button_checked_rounded,
                  value: enabledSources.toString(),
                  label: '已启用',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MineHeroStat extends StatelessWidget {
  const _MineHeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: MeloColors.mobileSurface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.mobileSurfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: MeloColors.primary700, size: 18),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: MeloColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MeloColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
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
            _SourceIcon(entry: entry),
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
    required this.wifiOnly,
    required this.playbackQuality,
    required this.onWifiOnlyChanged,
    required this.onPlaybackQualityChanged,
  });

  final _SettingsSection section;
  final bool wifiOnly;
  final AudioQuality playbackQuality;
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
              subtitle: '保留本机播放队列和上次播放进度；启动后不会自动播放。',
              leading: Icons.queue_music_rounded,
              child: Consumer(
                builder: (context, ref, _) {
                  final repository = ref.watch(demoRepositoryProvider);
                  return Column(
                    children: [
                      _SettingsSwitchRow(
                        title: '记住播放队列',
                        subtitle: '保留当前播放列表、当前歌曲、循环和随机播放状态。',
                        value: repository.rememberQueue,
                        onChanged: repository.setRememberQueue,
                      ),
                      const _SettingsDivider(),
                      _SettingsSwitchRow(
                        title: '启动后恢复播放进度',
                        subtitle: '重新打开应用时回到上次播放的歌曲和进度，不会自动播放。',
                        value: repository.restorePlaybackState &&
                            repository.rememberQueue,
                        onChanged: repository.rememberQueue
                            ? repository.setRestorePlaybackState
                            : null,
                      ),
                    ],
                  );
                },
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
      _SettingsSection.backup => const _BackupSettingsPanel(),
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
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _DownloadDirectoryDialog(
        initialPath: repository.customDownloadDirectory ?? directory ?? '',
      ),
    );
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

class _DownloadDirectoryDialog extends StatefulWidget {
  const _DownloadDirectoryDialog({required this.initialPath});

  final String initialPath;

  @override
  State<_DownloadDirectoryDialog> createState() =>
      _DownloadDirectoryDialogState();
}

class _DownloadDirectoryDialogState extends State<_DownloadDirectoryDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialPath);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}

const _backupZipTypeGroup = XTypeGroup(
  label: 'MeloUnion Backup',
  extensions: ['zip'],
  mimeTypes: ['application/zip'],
);

void _showMobileBackupSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const _MobileBackupSheet(),
  );
}

final class _BackupOptions {
  const _BackupOptions({
    required this.includeAccounts,
    this.password,
  });

  final bool includeAccounts;
  final String? password;
}

final class _RestoreOptions {
  const _RestoreOptions({
    required this.mode,
    this.password,
  });

  final BackupRestoreMode mode;
  final String? password;
}

class _BackupSettingsPanel extends ConsumerStatefulWidget {
  const _BackupSettingsPanel();

  @override
  ConsumerState<_BackupSettingsPanel> createState() =>
      _BackupSettingsPanelState();
}

class _BackupSettingsPanelState extends ConsumerState<_BackupSettingsPanel> {
  bool _busy = false;
  WebDavConfig? _webDavConfig;
  List<BackupRemoteEntry> _remoteEntries = const [];
  String? _remoteError;

  BackupCoordinator get _coordinator => BackupCoordinator.forRepository(
        ref.read(demoRepositoryProvider),
      );

  @override
  void initState() {
    super.initState();
    unawaited(_loadWebDavConfig());
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(demoRepositoryProvider);
    final cacheCount = repository.lastFavoritesData?.length ?? 0;
    return _SettingsPanel(
      title: '备份与恢复',
      subtitle: '导出数据快照，或将备份包保存到 WebDAV。',
      children: [
        _SettingsCard(
          title: '概览',
          subtitle:
              '${repository.playlistList.length} 个本地歌单 · ${repository.downloadCoordinator.localItems.length} 条本地媒体记录 · $cacheCount 首缓存喜欢',
          leading: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: MeloSpacing.md),
        _SettingsCard(
          title: '本地备份',
          subtitle: '创建或导入 .zip 备份文件。',
          leading: Icons.save_alt_rounded,
          child: Wrap(
            spacing: MeloSpacing.xs,
            runSpacing: MeloSpacing.xs,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _createLocalBackup,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('导出备份'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _restoreFromLocalFile,
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('从文件恢复'),
              ),
            ],
          ),
        ),
        const SizedBox(height: MeloSpacing.md),
        _SettingsCard(
          title: 'WebDAV',
          subtitle: _webDavConfig == null
              ? '未配置远端目录。'
              : '${_webDavConfig!.baseUri} · ${_webDavConfig!.remoteDirectory}',
          leading: Icons.cloud_sync_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: MeloSpacing.xs,
                runSpacing: MeloSpacing.xs,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _configureWebDav,
                    icon: const Icon(Icons.settings_ethernet_rounded, size: 18),
                    label: Text(_webDavConfig == null ? '配置 WebDAV' : '修改配置'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _busy || _webDavConfig == null ? null : _uploadWebDav,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: const Text('上传备份'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _busy || _webDavConfig == null ? null : _refreshRemote,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('刷新列表'),
                  ),
                  if (_webDavConfig != null)
                    TextButton.icon(
                      onPressed: _busy ? null : _clearWebDav,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('清除配置'),
                    ),
                ],
              ),
              if (_remoteError != null) ...[
                const SizedBox(height: MeloSpacing.sm),
                Text(
                  _remoteError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MeloColors.error,
                      ),
                ),
              ],
              if (_remoteEntries.isNotEmpty) ...[
                const SizedBox(height: MeloSpacing.md),
                _RemoteBackupTable(
                  entries: _remoteEntries,
                  onRestore: _busy ? null : _restoreRemoteEntry,
                  onDelete: _busy ? null : _deleteRemoteEntry,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: MeloSpacing.md),
        const _SettingsCard(
          title: '安全',
          subtitle: '账号保险箱只在勾选账号备份时写入备份包，并且必须输入密码加密；WebDAV 密码仅保存到平台安全存储。',
          leading: Icons.enhanced_encryption_outlined,
        ),
      ],
    );
  }

  Future<void> _loadWebDavConfig() async {
    final config = await _coordinator.readWebDavConfig();
    if (!mounted) return;
    setState(() => _webDavConfig = config);
    if (config != null) {
      unawaited(_refreshRemote());
    }
  }

  Future<void> _createLocalBackup() async {
    final options = await _askBackupOptions(context);
    if (options == null || !mounted) return;
    await _runTask(() async {
      final backup = await _coordinator.createBackup(
        includeAccounts: options.includeAccounts,
        accountPassword: options.password,
      );
      final target = await getSaveLocation(
        acceptedTypeGroups: const [_backupZipTypeGroup],
        suggestedName: backup.fileName,
        confirmButtonText: '保存备份',
      );
      if (target == null) return;
      await XFile.fromData(
        backup.bytes,
        name: backup.fileName,
        mimeType: 'application/zip',
      ).saveTo(target.path);
      _showToast('已导出备份：${backup.fileName}');
    });
  }

  Future<void> _restoreFromLocalFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [_backupZipTypeGroup],
      confirmButtonText: '选择备份',
    );
    if (file == null || !mounted) return;
    await _restoreBytes(await file.readAsBytes());
  }

  Future<void> _configureWebDav() async {
    final config = await _askWebDavConfig(context, initial: _webDavConfig);
    if (config == null || !mounted) return;
    await _runTask(() async {
      await _coordinator.testWebDav(config);
      await _coordinator.saveWebDavConfig(config);
      if (!mounted) return;
      setState(() {
        _webDavConfig = config;
        _remoteError = null;
      });
      await _refreshRemoteEntries();
      _showToast('WebDAV 配置已保存。');
    });
  }

  Future<void> _uploadWebDav() async {
    final options = await _askBackupOptions(context);
    if (options == null || !mounted) return;
    await _runTask(() async {
      await _coordinator.uploadBackupToWebDav(
        includeAccounts: options.includeAccounts,
        accountPassword: options.password,
      );
      await _refreshRemoteEntries();
      _showToast('备份已上传到 WebDAV。');
    });
  }

  Future<void> _refreshRemote() async {
    if (_webDavConfig == null) return;
    await _runTask(() async {
      await _refreshRemoteEntries();
    }, showError: false);
  }

  Future<void> _refreshRemoteEntries() async {
    final entries = await _coordinator.listWebDavBackups();
    if (!mounted) return;
    setState(() {
      _remoteEntries = entries;
      _remoteError = null;
    });
  }

  Future<void> _restoreRemoteEntry(BackupRemoteEntry entry) async {
    Uint8List? bytes;
    await _runTask(() async {
      bytes = await _coordinator.downloadWebDavBackup(entry);
    });
    if (!mounted || bytes == null) return;
    await _restoreBytes(bytes!);
  }

  Future<void> _deleteRemoteEntry(BackupRemoteEntry entry) async {
    final confirmed = await _confirm(
      context,
      title: '删除远端备份？',
      message: entry.name,
      confirmLabel: '删除',
    );
    if (!confirmed || !mounted) return;
    await _runTask(() async {
      await _coordinator.deleteWebDavBackup(entry);
      await _refreshRemoteEntries();
      _showToast('已删除远端备份。');
    });
  }

  Future<void> _clearWebDav() async {
    final confirmed = await _confirm(
      context,
      title: '清除 WebDAV 配置？',
      message: '远端备份文件不会被删除。',
      confirmLabel: '清除',
    );
    if (!confirmed || !mounted) return;
    await _runTask(() async {
      await _coordinator.clearWebDavConfig();
      if (!mounted) return;
      setState(() {
        _webDavConfig = null;
        _remoteEntries = const [];
        _remoteError = null;
      });
      _showToast('已清除 WebDAV 配置。');
    });
  }

  Future<void> _restoreBytes(List<int> rawBytes) async {
    final bytes = Uint8List.fromList(rawBytes);
    final payload = _coordinator.readBackup(bytes);
    if (!mounted) return;
    final options = await _askRestoreOptions(
      context,
      includesAccountVault: payload.manifest.includesAccountVault,
    );
    if (options == null || !mounted) return;
    final confirmed = await _confirm(
      context,
      title: '确认恢复备份？',
      message: '恢复数据前会自动保存当前状态备份。',
      confirmLabel: '恢复',
    );
    if (!confirmed || !mounted) return;
    await _runTask(() async {
      final result = await _coordinator.restoreFromBackupBytes(
        bytes: bytes,
        mode: options.mode,
        accountPassword: options.password,
      );
      final suffix =
          result.preRestoreBackupPath == null ? '' : ' 当前状态已保存到预恢复备份。';
      _showToast('恢复完成。$suffix');
    });
  }

  Future<void> _runTask(
    Future<void> Function() task, {
    bool showError = true,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } catch (error) {
      if (!mounted) return;
      if (showError) {
        _showToast('操作失败：$error');
      } else {
        setState(() => _remoteError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    MeloSnackbar.show(context: context, message: message);
  }
}

class _MobileBackupSheet extends StatelessWidget {
  const _MobileBackupSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: const _BackupSettingsPanel(),
      ),
    );
  }
}

class _RemoteBackupTable extends StatelessWidget {
  const _RemoteBackupTable({
    required this.entries,
    required this.onRestore,
    required this.onDelete,
  });

  final List<BackupRemoteEntry> entries;
  final Future<void> Function(BackupRemoteEntry entry)? onRestore;
  final Future<void> Function(BackupRemoteEntry entry)? onDelete;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 960;
    if (mobile) {
      return Column(
        children: [
          for (final entry in entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.archive_outlined),
              title: Text(entry.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(_backupEntrySubtitle(entry)),
              trailing: Wrap(
                spacing: 2,
                children: [
                  IconButton(
                    tooltip: '恢复',
                    onPressed:
                        onRestore == null ? null : () => onRestore!(entry),
                    icon: const Icon(Icons.restore_rounded),
                  ),
                  IconButton(
                    tooltip: '删除',
                    onPressed: onDelete == null ? null : () => onDelete!(entry),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.3),
        1: FlexColumnWidth(1.4),
        2: FixedColumnWidth(108),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _remoteTableRow(
          context,
          name: '备份文件',
          detail: '时间 / 大小',
          actions: const SizedBox.shrink(),
          header: true,
        ),
        for (final entry in entries)
          _remoteTableRow(
            context,
            name: entry.name,
            detail: _backupEntrySubtitle(entry),
            actions: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: '恢复',
                  onPressed: onRestore == null ? null : () => onRestore!(entry),
                  icon: const Icon(Icons.restore_rounded),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: onDelete == null ? null : () => onDelete!(entry),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
      ],
    );
  }

  TableRow _remoteTableRow(
    BuildContext context, {
    required String name,
    required String detail,
    required Widget actions,
    bool header = false,
  }) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: header ? MeloColors.textSecondary : MeloColors.textPrimary,
          fontWeight: header ? FontWeight.w800 : FontWeight.w600,
        );
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MeloColors.border.withValues(alpha: .7)),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(name,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(detail,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
        actions,
      ],
    );
  }
}

String _backupEntrySubtitle(BackupRemoteEntry entry) {
  final size = entry.size == null ? '未知大小' : _formatBytes(entry.size!);
  final modified = entry.modifiedAt == null
      ? '未知时间'
      : _formatDateTime(entry.modifiedAt!.toLocal());
  return '$modified · $size';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

String _formatDateTime(DateTime value) {
  String two(int part) => part.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}

Future<_BackupOptions?> _askBackupOptions(BuildContext context) async {
  return showDialog<_BackupOptions>(
    context: context,
    builder: (context) => const _BackupOptionsDialog(),
  );
}

Future<_RestoreOptions?> _askRestoreOptions(
  BuildContext context, {
  required bool includesAccountVault,
}) async {
  return showDialog<_RestoreOptions>(
    context: context,
    builder: (context) =>
        _RestoreOptionsDialog(includesAccountVault: includesAccountVault),
  );
}

class _BackupOptionsDialog extends StatefulWidget {
  const _BackupOptionsDialog();

  @override
  State<_BackupOptionsDialog> createState() => _BackupOptionsDialogState();
}

class _BackupOptionsDialogState extends State<_BackupOptionsDialog> {
  final passwordController = TextEditingController();
  var includeAccounts = false;

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建备份'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: includeAccounts,
              onChanged: (value) =>
                  setState(() => includeAccounts = value ?? false),
              title: const Text('包含账号保险箱'),
              subtitle: const Text('需要输入密码加密。'),
            ),
            if (includeAccounts)
              _BackupPasswordField(
                controller: passwordController,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (includeAccounts && passwordController.text.trim().isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              _BackupOptions(
                includeAccounts: includeAccounts,
                password: includeAccounts ? passwordController.text : null,
              ),
            );
          },
          child: const Text('继续'),
        ),
      ],
    );
  }
}

class _RestoreOptionsDialog extends StatefulWidget {
  const _RestoreOptionsDialog({required this.includesAccountVault});

  final bool includesAccountVault;

  @override
  State<_RestoreOptionsDialog> createState() => _RestoreOptionsDialogState();
}

class _RestoreOptionsDialogState extends State<_RestoreOptionsDialog> {
  final passwordController = TextEditingController();
  late BackupRestoreMode mode;

  @override
  void initState() {
    super.initState();
    mode = widget.includesAccountVault
        ? BackupRestoreMode.dataAndAccounts
        : BackupRestoreMode.dataOnly;
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('恢复选项'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<BackupRestoreMode>(
              groupValue: mode,
              onChanged: (value) {
                if (value == null) return;
                if (!widget.includesAccountVault && value.restoresAccounts) {
                  return;
                }
                setState(() => mode = value);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RadioListTile<BackupRestoreMode>(
                    contentPadding: EdgeInsets.zero,
                    value: BackupRestoreMode.dataOnly,
                    title: Text('只恢复数据'),
                  ),
                  RadioListTile<BackupRestoreMode>(
                    contentPadding: EdgeInsets.zero,
                    value: BackupRestoreMode.accountsOnly,
                    enabled: widget.includesAccountVault,
                    title: const Text('只恢复账号'),
                  ),
                  RadioListTile<BackupRestoreMode>(
                    contentPadding: EdgeInsets.zero,
                    value: BackupRestoreMode.dataAndAccounts,
                    enabled: widget.includesAccountVault,
                    title: const Text('数据和账号都恢复'),
                  ),
                ],
              ),
            ),
            if (mode.restoresAccounts)
              _BackupPasswordField(
                controller: passwordController,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (mode.restoresAccounts &&
                passwordController.text.trim().isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              _RestoreOptions(
                mode: mode,
                password:
                    mode.restoresAccounts ? passwordController.text : null,
              ),
            );
          },
          child: const Text('继续'),
        ),
      ],
    );
  }
}

class _BackupPasswordField extends StatefulWidget {
  const _BackupPasswordField({required this.controller});

  final TextEditingController controller;

  @override
  State<_BackupPasswordField> createState() => _BackupPasswordFieldState();
}

class _BackupPasswordFieldState extends State<_BackupPasswordField> {
  var obscureText = true;

  @override
  Widget build(BuildContext context) {
    final android = Theme.of(context).platform == TargetPlatform.android;
    return TextField(
      controller: widget.controller,
      keyboardType:
          android ? TextInputType.text : TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      obscureText: android ? false : obscureText,
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      autofillHints: const <String>[],
      decoration: InputDecoration(
        labelText: '备份口令',
        suffixIcon: android
            ? null
            : IconButton(
                tooltip: obscureText ? '显示' : '隐藏',
                onPressed: () => setState(() => obscureText = !obscureText),
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
      ),
    );
  }
}

Future<WebDavConfig?> _askWebDavConfig(
  BuildContext context, {
  WebDavConfig? initial,
}) {
  return showDialog<WebDavConfig>(
    context: context,
    builder: (context) => _WebDavConfigDialog(initial: initial),
  );
}

class _WebDavConfigDialog extends StatefulWidget {
  const _WebDavConfigDialog({this.initial});

  final WebDavConfig? initial;

  @override
  State<_WebDavConfigDialog> createState() => _WebDavConfigDialogState();
}

class _WebDavConfigDialogState extends State<_WebDavConfigDialog> {
  late final TextEditingController urlController;
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController directoryController;
  var obscurePassword = true;

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController(
      text: widget.initial?.baseUri.toString() ?? '',
    );
    usernameController = TextEditingController(
      text: widget.initial?.username ?? '',
    );
    passwordController = TextEditingController(
      text: widget.initial?.password ?? '',
    );
    directoryController = TextEditingController(
      text: widget.initial?.remoteDirectory ?? '/MeloUnion/backups/',
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    directoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: MeloSpacing.lg,
        vertical: MeloSpacing.lg,
      ),
      shape: const RoundedRectangleBorder(borderRadius: MeloRadii.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: MeloColors.primary50,
                      borderRadius: MeloRadii.md,
                    ),
                    child: const Icon(
                      Icons.cloud_sync_outlined,
                      color: MeloColors.primary700,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: MeloSpacing.sm),
                  Expanded(
                    child: Text(
                      'WebDAV 设置',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: MeloColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: MeloSpacing.lg),
              TextField(
                controller: urlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: _webDavFieldDecoration(
                  icon: Icons.link_rounded,
                  label: '服务器 URL',
                  hint: 'https://dav.example.com',
                ),
              ),
              const SizedBox(height: MeloSpacing.sm),
              TextField(
                controller: usernameController,
                textInputAction: TextInputAction.next,
                decoration: _webDavFieldDecoration(
                  icon: Icons.person_outline_rounded,
                  label: '用户名',
                ),
              ),
              const SizedBox(height: MeloSpacing.sm),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: _webDavFieldDecoration(
                  icon: Icons.lock_outline_rounded,
                  label: '密码',
                  suffix: IconButton(
                    tooltip: obscurePassword ? '显示密码' : '隐藏密码',
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MeloSpacing.sm),
              TextField(
                controller: directoryController,
                textInputAction: TextInputAction.done,
                decoration: _webDavFieldDecoration(
                  icon: Icons.folder_outlined,
                  label: '远端目录',
                  hint: '/MeloUnion/backups/',
                ),
              ),
              const SizedBox(height: MeloSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: MeloSpacing.sm),
                  FilledButton.icon(
                    onPressed: () {
                      final url = urlController.text.trim();
                      final username = usernameController.text.trim();
                      final password = passwordController.text;
                      if (url.isEmpty || username.isEmpty || password.isEmpty) {
                        return;
                      }
                      Navigator.pop(
                        context,
                        WebDavConfig(
                          baseUri: Uri.parse(url),
                          username: username,
                          password: password,
                          remoteDirectory:
                              directoryController.text.trim().isEmpty
                                  ? '/MeloUnion/backups/'
                                  : directoryController.text.trim(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('测试并保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _webDavFieldDecoration({
  required IconData icon,
  required String label,
  String? hint,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: MeloColors.surfaceMuted,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: MeloSpacing.md,
      vertical: 17,
    ),
    border: OutlineInputBorder(
      borderRadius: MeloRadii.md,
      borderSide: const BorderSide(color: MeloColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: MeloRadii.md,
      borderSide: const BorderSide(color: MeloColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: MeloRadii.md,
      borderSide: const BorderSide(
        color: MeloColors.primary500,
        width: 1.5,
      ),
    ),
  );
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
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
    final mobile = MediaQuery.sizeOf(context).width < 960;
    return Material(
      color: mobile ? MeloColors.mobileSurface : MeloColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: MeloRadii.lg,
        side: BorderSide(
          color: mobile ? MeloColors.mobileSurfaceBorder : MeloColors.border,
        ),
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
  final ValueChanged<bool>? onChanged;

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
          color: selected
              ? MeloColors.mobileAccentSurface
              : MeloColors.mobileSurfaceMuted,
          borderRadius: MeloRadii.md,
          border: Border.all(
            color: selected
                ? MeloColors.primary300.withValues(alpha: 0.78)
                : MeloColors.mobileSurfaceBorder,
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
