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
        color: MeloColors.surface,
        borderRadius: MeloRadii.lg,
        border: Border.all(color: MeloColors.border),
      ),
      child: Row(
        children: [
          _SourceIcon(presentation: presentation),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        if (sessionAction?.kind == ProviderSessionActionKind.cookieImport)
          FilledButton.icon(
            onPressed: () async {
              if (signedIn) {
                final clear = sessionAction?.clear;
                if (clear != null) {
                  await clear();
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
                return;
              }
              Navigator.pop(context);
              await showDialog<void>(
                context: context,
                builder: (context) => const _NeteaseCookieDialog(),
              );
            },
            icon: Icon(signedIn ? Icons.logout_rounded : Icons.login_rounded),
            label: Text(signedIn ? '清除会话' : '导入 Cookie'),
          )
        else if (sessionAction?.kind == ProviderSessionActionKind.qrLogin)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: signedIn
                    ? null
                    : () {
                        Navigator.pop(context);
                        showDialog<void>(
                          context: context,
                          builder: (context) => const _NeteaseCookieDialog(),
                        );
                      },
                child: const Text('导入 Cookie'),
              ),
              const SizedBox(width: 8),
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
                  if (entry.descriptor.id == qqMusicProviderId) {
                    await showDialog<void>(
                      context: context,
                      builder: (context) => const _QqQrLoginDialog(),
                    );
                  } else {
                    await showDialog<void>(
                      context: context,
                      builder: (context) => const _NeteaseQrLoginDialog(),
                    );
                  }
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

class _QqQrLoginDialog extends ConsumerStatefulWidget {
  const _QqQrLoginDialog();

  @override
  ConsumerState<_QqQrLoginDialog> createState() => _QqQrLoginDialogState();
}

class _QqQrLoginDialogState extends ConsumerState<_QqQrLoginDialog> {
  QqMusicQrLoginMode _mode = QqMusicQrLoginMode.qq;
  QqMusicQrLoginSession? _session;
  QqMusicQrLoginStatus _status = QqMusicQrLoginStatus.waiting;
  Timer? _timer;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_createSession(_mode));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _createSession(QqMusicQrLoginMode mode) async {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _session = null;
      _status = QqMusicQrLoginStatus.waiting;
      _error = null;
    });
    try {
      final session =
          await ref.read(demoRepositoryProvider).createQqMusicQrLoginSession(
                mode,
              );
      if (!mounted) return;
      setState(() => _session = session);
      _timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_checkSession()),
      );
      await _checkSession();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _checkSession() async {
    final session = _session;
    if (session == null) return;
    try {
      final result =
          await ref.read(demoRepositoryProvider).checkQqMusicQrLoginSession(
                session,
              );
      ref.invalidate(allFavoritesProvider);
      if (!mounted) return;
      setState(() => _status = result.status);
      if (result.status == QqMusicQrLoginStatus.authorized) {
        _timer?.cancel();
        Navigator.pop(context);
      } else if (result.status == QqMusicQrLoginStatus.expired ||
          result.status == QqMusicQrLoginStatus.failed) {
        _timer?.cancel();
        if (result.message != null && result.message!.trim().isNotEmpty) {
          setState(() => _error = result.message);
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return AlertDialog(
      title: const Text('QQ 音乐扫码登录'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<QqMusicQrLoginMode>(
              segments: const [
                ButtonSegment(
                  value: QqMusicQrLoginMode.qq,
                  label: Text('QQ'),
                  icon: Icon(Icons.account_circle_rounded),
                ),
                ButtonSegment(
                  value: QqMusicQrLoginMode.wechat,
                  label: Text('微信'),
                  icon: Icon(Icons.chat_bubble_rounded),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) {
                  unawaited(_createSession(values.first));
                }
              },
            ),
            const SizedBox(height: 16),
            if (session == null && _error == null)
              const SizedBox(
                width: 192,
                height: 192,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (session != null)
              Container(
                width: 208,
                height: 208,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: MeloRadii.md,
                  border: Border.all(color: MeloColors.border),
                ),
                child: _QqQrImage(session: session),
              ),
            const SizedBox(height: 14),
            Text(
              _qqQrStatusLabel(_status),
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
          child: const Text('关闭'),
        ),
        TextButton(
          onPressed: _status == QqMusicQrLoginStatus.expired ||
                  _status == QqMusicQrLoginStatus.failed
              ? () => _createSession(_mode)
              : null,
          child: const Text('刷新二维码'),
        ),
      ],
    );
  }
}

class _QqQrImage extends StatelessWidget {
  const _QqQrImage({required this.session});

  final QqMusicQrLoginSession session;

  @override
  Widget build(BuildContext context) {
    final imageDataUri = session.imageDataUri;
    if (imageDataUri != null && imageDataUri.isNotEmpty) {
      return Image.memory(
        _decodeDataUri(imageDataUri),
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }
    final imageUri = session.imageUri;
    if (imageUri != null) {
      return Image.network(
        imageUri.toString(),
        fit: BoxFit.contain,
      );
    }
    final loginUri = session.loginUri;
    if (loginUri != null) {
      return QrImageView(
        data: loginUri.toString(),
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero,
      );
    }
    return const Center(child: Icon(Icons.qr_code_2_rounded, size: 64));
  }
}

Uint8List _decodeDataUri(String dataUri) {
  final commaIndex = dataUri.indexOf(',');
  final base64Text =
      commaIndex == -1 ? dataUri : dataUri.substring(commaIndex + 1);
  return base64Decode(base64Text);
}

String _qqQrStatusLabel(QqMusicQrLoginStatus status) => switch (status) {
      QqMusicQrLoginStatus.waiting => '请扫码登录 QQ 音乐',
      QqMusicQrLoginStatus.scanned => '已扫码，请在手机上确认登录',
      QqMusicQrLoginStatus.authorized => '登录成功，正在保存会话',
      QqMusicQrLoginStatus.expired => '二维码已过期，请刷新',
      QqMusicQrLoginStatus.failed => '扫码登录失败，请刷新重试',
    };

String _neteaseQrStatusLabel(NeteaseQrLoginStatus status) => switch (status) {
      NeteaseQrLoginStatus.waiting => '请使用网易云音乐 App 扫描二维码',
      NeteaseQrLoginStatus.scanned => '已扫码，请在手机上确认登录',
      NeteaseQrLoginStatus.authorized => '登录成功，正在保存会话',
      NeteaseQrLoginStatus.expired => '二维码已过期，请刷新',
    };

class _NeteaseCookieDialog extends ConsumerStatefulWidget {
  const _NeteaseCookieDialog();

  @override
  ConsumerState<_NeteaseCookieDialog> createState() =>
      _NeteaseCookieDialogState();
}

class _NeteaseCookieDialogState extends ConsumerState<_NeteaseCookieDialog> {
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
      title: const Text('导入网易云 Cookie'),
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
              decoration: const InputDecoration(
                labelText: 'Cookie',
                hintText: 'MUSIC_U=...; ...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: '用户 ID（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '仅用于本机账号读取测试；不要提交或分享 Cookie。写收藏、播放和下载仍需后续官方端验证。',
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
      await ref.read(demoRepositoryProvider).saveNeteaseCredentials(
            cookie: cookie,
            userId: _userIdController.text,
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
  const _SourceIcon({required this.presentation});

  final MeloProviderPresentation presentation;

  @override
  Widget build(BuildContext context) {
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
