part of 'settings_page.dart';

class _MusicSourcesSettings extends ConsumerWidget {
  const _MusicSourcesSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final sources = repository.providerEntries
        .where((entry) =>
            entry.descriptor.supports(ProviderCapability.authenticate) ||
            repository.sessionActionFor(entry.descriptor.id) != null)
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
    final presentation = meloProviderPresentation(
      descriptor.id,
      displayName: descriptor.displayName,
    );
    final signedIn = entry.provider.isAuthenticated;
    final canSyncFavorites =
        descriptor.supports(ProviderCapability.readFavorites);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: presentation.backgroundColor,
        borderRadius: MeloRadii.lg,
        border: Border.all(
          color: presentation.foregroundColor.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          _SourceIcon(entry: entry),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      presentation.fullName,
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
            onChanged: (value) =>
                repository.setProviderEnabled(descriptor.id, value),
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
    final presentation = meloProviderPresentation(
      entry.descriptor.id,
      displayName: entry.descriptor.displayName,
    );
    final sessionAction = repository.sessionActionFor(entry.descriptor.id);
    final signedIn = entry.provider.isAuthenticated;
    final supportsCookieImportFallback =
        entry.descriptor.id == neteaseProviderId ||
            entry.descriptor.id == qqMusicProviderId;
    return AlertDialog(
      title: Text('管理 ${presentation.fullName}'),
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
              sessionAction?.description ??
                  '后续真实 Provider 接入后，此处将提供二维码登录、会话状态、同步时间和账号移除操作。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MeloColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            if (entry.descriptor.id == qqMusicProviderId && signedIn) ...[
              const SizedBox(height: 14),
              _QqMusicRefreshStatus(repository: repository),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        if (sessionAction?.kind == ProviderSessionActionKind.cookieImport)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (signedIn) ...[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog<void>(
                      context: context,
                      builder: (context) => _cookieImportDialogFor(
                        context,
                        ref,
                        entry.descriptor.id,
                      ),
                    );
                  },
                  child: const Text('重新导入 Cookie'),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                onPressed: () async {
                  if (signedIn) {
                    await sessionAction?.clear?.call();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    return;
                  }
                  Navigator.pop(context);
                  await showDialog<void>(
                    context: context,
                    builder: (context) => _cookieImportDialogFor(
                      context,
                      ref,
                      entry.descriptor.id,
                    ),
                  );
                },
                icon: Icon(
                  signedIn ? Icons.logout_rounded : Icons.login_rounded,
                ),
                label: Text(signedIn ? '清除会话' : '导入 Cookie'),
              ),
            ],
          )
        else if (sessionAction?.kind == ProviderSessionActionKind.qrLogin)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (supportsCookieImportFallback) ...[
                TextButton(
                  onPressed: signedIn
                      ? null
                      : () {
                          Navigator.pop(context);
                          showDialog<void>(
                            context: context,
                            builder: (context) => _cookieImportDialogFor(
                              context,
                              ref,
                              entry.descriptor.id,
                            ),
                          );
                        },
                  child: const Text('导入 Cookie'),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                onPressed: () async {
                  if (signedIn) {
                    await sessionAction?.clear?.call();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    return;
                  }
                  Navigator.pop(context);
                  await showDialog<void>(
                    context: context,
                    builder: (context) => entry.descriptor.id == kugouProviderId
                        ? const _KugouQrLoginDialog()
                        : const _NeteaseQrLoginDialog(),
                  );
                },
                icon: Icon(
                  signedIn ? Icons.logout_rounded : Icons.qr_code_2_rounded,
                ),
                label: Text(signedIn ? '清除会话' : '扫码登录'),
              ),
            ],
          )
        else
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

class _QqMusicRefreshStatus extends StatelessWidget {
  const _QqMusicRefreshStatus({required this.repository});

  final DemoRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = repository.qqMusicRefreshInProgress
        ? '正在尝试自动续期…'
        : repository.qqMusicRefreshError != null
            ? '最近一次续期未成功（已保留旧会话）'
            : repository.qqMusicLastRefreshSuccessAt != null
                ? '最近一次续期成功'
                : '尚未尝试自动续期';
    final statusColor = repository.qqMusicRefreshInProgress
        ? theme.colorScheme.primary
        : repository.qqMusicRefreshError != null
            ? theme.colorScheme.error
            : theme.colorScheme.primary;
    final successAt = repository.qqMusicLastRefreshSuccessAt;
    final attemptAt = repository.qqMusicLastRefreshAttemptAt;
    final timestamp = repository.qqMusicRefreshError != null ||
            repository.qqMusicRefreshInProgress
        ? attemptAt
        : successAt ?? attemptAt;
    final timestampText = timestamp == null
        ? '暂无'
        : timestamp.toLocal().toString().substring(0, 16);
    final nextRefreshAt = repository.qqMusicNextRefreshAt;
    final nextRefreshText = nextRefreshAt == null
        ? '暂无'
        : nextRefreshAt.toLocal().toString().substring(0, 16);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自动续期状态',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
            ),
            if (repository.qqMusicRefreshError case final error?) ...[
              const SizedBox(height: 3),
              Text(
                '原因：$error',
                style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '时间：$timestampText',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '密钥指纹：${repository.qqMusicKeyFingerprint ?? '暂无'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '刷新令牌：${repository.qqMusicHasRefreshToken ? '已包含' : '未包含'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '计划续期：$nextRefreshText',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: repository.qqMusicRefreshInProgress
                    ? null
                    : repository.refreshQqMusicCredentials,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('立即尝试续期'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _cookieImportDialogFor(
  BuildContext context,
  WidgetRef ref,
  ProviderId providerId,
) {
  final repository = ref.read(demoRepositoryProvider);
  if (providerId == qqMusicProviderId) {
    return _CookieImportDialog(
      title: '导入 QQ 音乐 Cookie',
      hintText: 'pgv_pvid=...; ...',
      helpText: '仅用于本机账号读取测试；不要提交或分享 Cookie。写收藏、播放和下载仍需后续官方端验证。',
      onSave: ({required cookie, userId}) {
        return repository.saveQqMusicCredentials(
          QqMusicCredentials(cookie: cookie),
        );
      },
    );
  }
  return _CookieImportDialog(
    title: '导入网易云 Cookie',
    hintText: 'MUSIC_U=...; ...',
    helpText:
        '请从浏览器已登录的 music.163.com 请求中复制完整 Cookie，至少需要包含 MUSIC_U。不要提交或分享 Cookie。',
    userIdLabel: '用户 ID（可选）',
    onSave: ({required cookie, userId}) {
      return repository.saveNeteaseCredentials(
        cookie: cookie,
        userId: userId,
      );
    },
  );
}

class _NeteaseQrLoginDialog extends ConsumerStatefulWidget {
  const _NeteaseQrLoginDialog();

  @override
  ConsumerState<_NeteaseQrLoginDialog> createState() =>
      _NeteaseQrLoginDialogState();
}

class _NeteaseQrLoginDialogState extends ConsumerState<_NeteaseQrLoginDialog> {
  NeteaseQrLoginSession? _session;
  NeteaseQrLoginStatus _status = NeteaseQrLoginStatus.waiting;
  Timer? _timer;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_createSession());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _createSession() async {
    setState(() {
      _error = null;
      _session = null;
      _status = NeteaseQrLoginStatus.waiting;
    });
    try {
      final session =
          await ref.read(demoRepositoryProvider).createNeteaseQrLoginSession();
      if (!mounted) return;
      setState(() => _session = session);
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_checkSession()),
      );
      await _checkSession();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _checkSession() async {
    final session = _session;
    if (session == null) return;
    try {
      final result = await ref
          .read(demoRepositoryProvider)
          .checkNeteaseQrLoginSession(session);
      ref.invalidate(allFavoritesProvider);
      if (!mounted) return;
      setState(() => _status = result.status);
      if (result.status == NeteaseQrLoginStatus.authorized) {
        _timer?.cancel();
        Navigator.pop(context);
      } else if (result.status == NeteaseQrLoginStatus.expired) {
        _timer?.cancel();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return AlertDialog(
      title: const Text('网易云扫码登录'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session == null && _error == null)
              const SizedBox(
                width: 160,
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (session != null)
              Container(
                width: 192,
                height: 192,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: MeloRadii.md,
                  border: Border.all(color: MeloColors.border),
                ),
                child: QrImageView(
                  data: session.loginUri.toString(),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
              ),
            const SizedBox(height: 14),
            Text(
              _neteaseQrStatusLabel(_status),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                '扫码登录失败：$_error',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MeloColors.error,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed:
              _status == NeteaseQrLoginStatus.expired ? _createSession : null,
          child: const Text('刷新二维码'),
        ),
      ],
    );
  }
}

String _neteaseQrStatusLabel(NeteaseQrLoginStatus status) => switch (status) {
      NeteaseQrLoginStatus.waiting => '请使用网易云音乐 App 扫描二维码',
      NeteaseQrLoginStatus.scanned => '已扫码，请在手机上确认登录',
      NeteaseQrLoginStatus.authorized => '登录成功，正在保存会话',
      NeteaseQrLoginStatus.expired => '二维码已过期，请刷新',
    };

typedef _CookieImportSave = Future<void> Function({
  required String cookie,
  String? userId,
});

class _CookieImportDialog extends ConsumerStatefulWidget {
  const _CookieImportDialog({
    required this.title,
    required this.hintText,
    required this.helpText,
    required this.onSave,
    this.userIdLabel,
  });

  final String title;
  final String hintText;
  final String helpText;
  final String? userIdLabel;
  final _CookieImportSave onSave;

  @override
  ConsumerState<_CookieImportDialog> createState() =>
      _CookieImportDialogState();
}

class _CookieImportDialogState extends ConsumerState<_CookieImportDialog> {
  final _cookieController = TextEditingController();
  final _userIdController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _cookieController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _cookieController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Cookie',
                hintText: widget.hintText,
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.userIdLabel != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: widget.userIdLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              widget.helpText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MeloColors.textSecondary,
                    height: 1.45,
                  ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MeloColors.error,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '保存中' : '保存会话'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final cookie = _cookieController.text.trim();
    if (cookie.isEmpty) {
      setState(() => _error = 'Cookie 不能为空。');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(
        cookie: cookie,
        userId: widget.userIdLabel == null ? null : _userIdController.text,
      );
      ref.invalidate(allFavoritesProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败：$error';
        });
      }
    }
  }
}

class _AdvancedSourceInfo extends StatelessWidget {
  const _AdvancedSourceInfo({required this.entry});

  final ProviderRegistryEntry entry;

  @override
  Widget build(BuildContext context) {
    final values =
        entry.descriptor.capabilities.map((item) => item.label).join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MeloColors.surfaceMuted,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
      ),
      child: Text(
        '${meloProviderPresentation(
          entry.descriptor.id,
          displayName: entry.descriptor.displayName,
        ).fullName}：$values',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MeloColors.textSecondary,
              height: 1.45,
            ),
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.entry});

  final ProviderRegistryEntry entry;

  @override
  Widget build(BuildContext context) {
    final id = entry.descriptor.id.value.toLowerCase();
    final isNetease = id == 'netease_cloud_music' ||
        id.contains('aurora') ||
        id.contains('netease');
    final isQQ = id == 'qq_music' || id.contains('beacon') || id.contains('qq');
    final isKugou = id == 'kugou' || id.contains('kugou');
    if (isNetease || isQQ || isKugou) {
      final presentation = meloProviderPresentation(
        entry.descriptor.id,
        displayName: entry.descriptor.displayName,
      );
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: presentation.backgroundColor,
          borderRadius: MeloRadii.md,
          border: Border.all(
            color: presentation.foregroundColor.withValues(alpha: 0.22),
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          isNetease
              ? 'assets/images/netease_logo.png'
              : (isQQ
                  ? 'assets/images/qq_logo.png'
                  : 'assets/images/kugou_logo.png'),
          fit: BoxFit.contain,
        ),
      );
    }

    final presentation = meloProviderPresentation(
      entry.descriptor.id,
      displayName: entry.descriptor.displayName,
    );
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: presentation.backgroundColor,
        borderRadius: MeloRadii.md,
      ),
      child: Icon(
        presentation.icon,
        color: presentation.foregroundColor,
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

class _KugouQrLoginDialog extends ConsumerStatefulWidget {
  const _KugouQrLoginDialog();

  @override
  ConsumerState<_KugouQrLoginDialog> createState() =>
      _KugouQrLoginDialogState();
}

class _KugouQrLoginDialogState extends ConsumerState<_KugouQrLoginDialog> {
  KugouQrLoginSession? _session;
  KugouQrLoginStatus _status = KugouQrLoginStatus.waiting;
  Timer? _timer;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_createSession());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _createSession() async {
    setState(() {
      _error = null;
      _session = null;
      _status = KugouQrLoginStatus.waiting;
    });
    try {
      final session =
          await ref.read(demoRepositoryProvider).createKugouQrLoginSession();
      if (!mounted) return;
      setState(() => _session = session);
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_checkSession()),
      );
      await _checkSession();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _checkSession() async {
    final session = _session;
    if (session == null) return;
    try {
      final result = await ref
          .read(demoRepositoryProvider)
          .checkKugouQrLoginSession(session);
      ref.invalidate(allFavoritesProvider);
      if (!mounted) return;
      setState(() => _status = result.status);
      if (result.status == KugouQrLoginStatus.authorized) {
        _timer?.cancel();
        Navigator.pop(context);
      } else if (result.status == KugouQrLoginStatus.expired) {
        _timer?.cancel();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return AlertDialog(
      title: const Text('酷狗音乐扫码登录'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session == null && _error == null)
              const SizedBox(
                width: 160,
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (session != null)
              Container(
                width: 192,
                height: 192,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: MeloRadii.md,
                  border: Border.all(color: MeloColors.border),
                ),
                child: QrImageView(
                  data: session.loginUri.toString(),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
              ),
            const SizedBox(height: 14),
            Text(
              _kugouQrStatusLabel(_status),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MeloColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                '扫码登录失败：$_error',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MeloColors.error,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed:
              _status == KugouQrLoginStatus.expired ? _createSession : null,
          child: const Text('刷新二维码'),
        ),
      ],
    );
  }
}

String _kugouQrStatusLabel(KugouQrLoginStatus status) => switch (status) {
      KugouQrLoginStatus.waiting => '请使用酷狗音乐 App 扫描二维码',
      KugouQrLoginStatus.scanned => '已扫码，请在手机上确认登录',
      KugouQrLoginStatus.authorized => '登录成功，正在保存会话',
      KugouQrLoginStatus.expired => '二维码已过期，请刷新',
      KugouQrLoginStatus.failed => '登录失败，请重新扫码',
    };
