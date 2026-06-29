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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设置',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '管理音乐来源、播放行为、下载与应用偏好。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MeloColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: compact
                ? _SettingsContent(
                    section: _selected,
                    autoPlay: _autoPlay,
                    rememberQueue: _rememberQueue,
                    wifiOnly: _wifiOnly,
                    onAutoPlayChanged: (value) => setState(() => _autoPlay = value),
                    onRememberQueueChanged: (value) => setState(() => _rememberQueue = value),
                    onWifiOnlyChanged: (value) => setState(() => _wifiOnly = value),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 208,
                        child: _SettingsNav(
                          selected: _selected,
                          onSelected: (value) => setState(() => _selected = value),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _SettingsContent(
                          section: _selected,
                          autoPlay: _autoPlay,
                          rememberQueue: _rememberQueue,
                          wifiOnly: _wifiOnly,
                          onAutoPlayChanged: (value) => setState(() => _autoPlay = value),
                          onRememberQueueChanged: (value) => setState(() => _rememberQueue = value),
                          onWifiOnlyChanged: (value) => setState(() => _wifiOnly = value),
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

class _SettingsNav extends StatelessWidget {
  const _SettingsNav({required this.selected, required this.onSelected});

  final _SettingsSection selected;
  final ValueChanged<_SettingsSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.lg,
        border: Border.all(color: MeloColors.border),
      ),
      child: Column(
        children: [
          for (final section in _SettingsSection.values)
            _SettingsNavItem(
              section: section,
              selected: section == selected,
              onTap: () => onSelected(section),
            ),
        ],
      ),
    );
  }
}

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _SettingsSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MeloColors.primary700 : MeloColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: MeloRadii.sm,
      child: Ink(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? MeloColors.primary50 : Colors.transparent,
          borderRadius: MeloRadii.sm,
        ),
        child: Row(
          children: [
            Icon(section.icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              section.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
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
    required this.onAutoPlayChanged,
    required this.onRememberQueueChanged,
    required this.onWifiOnlyChanged,
  });

  final _SettingsSection section;
  final bool autoPlay;
  final bool rememberQueue;
  final bool wifiOnly;
  final ValueChanged<bool> onAutoPlayChanged;
  final ValueChanged<bool> onRememberQueueChanged;
  final ValueChanged<bool> onWifiOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      _SettingsSection.sources => const _MusicSourcesSettings(),
      _SettingsSection.playback => _SettingsPanel(
          title: '播放设置',
          subtitle: '控制默认播放行为与队列恢复。',
          children: [
            SwitchListTile.adaptive(
              value: autoPlay,
              onChanged: onAutoPlayChanged,
              title: const Text('启动后恢复播放状态'),
              subtitle: const Text('重新打开应用时恢复上一次播放上下文。'),
            ),
            const Divider(height: 1),
            SwitchListTile.adaptive(
              value: rememberQueue,
              onChanged: onRememberQueueChanged,
              title: const Text('记住播放队列'),
              subtitle: const Text('保留当前队列与播放位置。'),
            ),
          ],
        ),
      _SettingsSection.downloads => _SettingsPanel(
          title: '下载设置',
          subtitle: '下载只在来源和账号明确支持时可用。',
          children: [
            ListTile(
              title: const Text('下载管理'),
              subtitle: const Text('查看进行中、已完成与失败任务。'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go(AppDestination.downloads.path),
            ),
            const Divider(height: 1),
            SwitchListTile.adaptive(
              value: wifiOnly,
              onChanged: onWifiOnlyChanged,
              title: const Text('仅 Wi-Fi 下载'),
              subtitle: const Text('移动网络下等待手动确认。'),
            ),
          ],
        ),
      _SettingsSection.appearance => const _SettingsPanel(
          title: '外观与快捷键',
          subtitle: '当前使用浅色主题，桌面端支持系统媒体键。',
          children: [
            ListTile(
              title: Text('主题'),
              subtitle: Text('浅色 · 深色主题将在完整 Variant 中启用'),
            ),
            Divider(height: 1),
            ListTile(
              title: Text('快捷键'),
              subtitle: Text('Space 播放/暂停 · Ctrl+K 打开搜索'),
            ),
          ],
        ),
      _SettingsSection.about => const _SettingsPanel(
          title: '关于 MeloUnion',
          subtitle: '一个可扩展 Provider 的统一音乐库与播放客户端。',
          children: [
            ListTile(title: Text('版本'), subtitle: Text('Flutter MVP · Phase 1–5')),
            Divider(height: 1),
            ListTile(title: Text('数据边界'), subtitle: Text('登录凭证仅保存在本机安全存储中。')),
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
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MeloColors.textSecondary)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: MeloColors.surface,
            borderRadius: MeloRadii.lg,
            border: Border.all(color: MeloColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
