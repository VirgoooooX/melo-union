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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
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
        const _SettingsCard(
          title: '下载功能',
          subtitle: '当前版本暂不提供下载，相关入口已先收起。',
          leading: Icons.download_done_outlined,
        ),
        const SizedBox(height: 18),
        const _MineSectionTitle('应用信息'),
        const SizedBox(height: 10),
        const SizedBox(height: 12),
        const _AboutLogoCard(),
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
    return _SettingsSurface(
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                      : '前往桌面设置可导入或清除账号凭证',
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
          Switch.adaptive(
            value: entry.isEnabled,
            onChanged: (value) =>
                repository.setProviderEnabled(descriptor.id, value),
          ),
        ],
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
      for (final section in _SettingsSection.values
          .where((s) => s != _SettingsSection.downloads))
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
          subtitle: '当前版本暂不提供下载功能。',
          children: [
            const _SettingsCard(
              title: '下载暂未开放',
              subtitle: '离线下载和本地媒体管理会在后续版本重新接入。',
              leading: Icons.download_done_outlined,
            ),
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
          children: const [
            _AboutLogoCard(),
            SizedBox(height: MeloSpacing.md),
            _SettingsCard(
              title: '版本',
              subtitle: 'v$appVersion',
              leading: Icons.info_outline_rounded,
            ),
            SizedBox(height: MeloSpacing.md),
            _SettingsCard(
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
  });

  final String title;
  final String subtitle;
  final IconData leading;
  final Widget? child;

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
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: MeloSpacing.md),
            child!,
          ],
        ],
      ),
    );

    return content;
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
