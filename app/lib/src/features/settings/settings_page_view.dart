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

class _MobileMineView extends StatelessWidget {
  const _MobileMineView({
    required this.playbackQuality,
    required this.onPlaybackQualityChanged,
  });

  final AudioQuality playbackQuality;
  final Future<void> Function(AudioQuality quality) onPlaybackQualityChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      children: [
        Text(
          '我的',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '账号来源、本地内容和播放偏好。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
        const SizedBox(height: 18),
        Text(
          '账号与来源',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        const _MusicSourcesSettings(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
        ),
        const SizedBox(height: 18),
        Text(
          '本地与下载',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        _SettingsCard(
          title: '下载管理',
          subtitle: '查看进行中、已完成与失败任务。',
          leading: Icons.download_done_rounded,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.go(AppDestination.downloads.path),
        ),
        const SizedBox(height: 18),
        Text(
          '应用设置',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
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
        const SizedBox(height: 12),
        const _SettingsCard(
          title: '关于 MeloUnion',
          subtitle: 'Flutter MVP · Provider 可扩展音乐库。',
          leading: Icons.info_outline_rounded,
        ),
      ],
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
                '管理音乐来源、播放行为、下载与应用偏好。',
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
          subtitle: '下载只在来源和账号明确支持时可用。',
          children: [
            _SettingsCard(
              title: '下载管理',
              subtitle: '查看进行中、已完成与失败任务。',
              leading: Icons.download_done_rounded,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go(AppDestination.downloads.path),
            ),
            const SizedBox(height: MeloSpacing.md),
            _SettingsCard(
              title: '网络策略',
              subtitle: '控制下载任务启动条件。',
              leading: Icons.wifi_rounded,
              child: _SettingsSwitchRow(
                title: '仅 Wi-Fi 下载',
                subtitle: '移动网络下等待手动确认。',
                value: wifiOnly,
                onChanged: onWifiOnlyChanged,
              ),
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
  final Widget? trailing;
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
                trailing!,
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
    return InkWell(
      onTap: onTap,
      borderRadius: MeloRadii.lg,
      child: content,
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
