import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path/path.dart' as path;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

final desktopLifecycleController = DesktopLifecycleController();

class DesktopLifecycleController extends ChangeNotifier
    with WindowListener, TrayListener {
  static const _showWindowKey = 'show_window';
  static const _exitAppKey = 'exit_app';

  bool _initialized = false;
  bool _trayReady = false;
  bool _launchAtStartupEnabled = false;
  bool _launchAtStartupUpdating = false;
  bool _keepInTray = false;
  bool _quitting = false;
  String? _error;
  Future<void> Function()? _onExit;

  bool get isSupported => Platform.isWindows;
  bool get initialized => _initialized;
  bool get trayReady => _trayReady;
  bool get launchAtStartupEnabled => _launchAtStartupEnabled;
  bool get launchAtStartupUpdating => _launchAtStartupUpdating;
  bool get keepInTray => _keepInTray;
  String? get error => _error;

  void setExitHandler(Future<void> Function() onExit) {
    _onExit = onExit;
  }

  Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    _initialized = true;
    await _loadPreferences();

    const packageName = 'MeloUnion.MeloUnion';
    final executable = Platform.resolvedExecutable;
    final runningFromMsix =
        executable.contains('WindowsApps') && executable.contains(packageName);
    launchAtStartup.setup(
      appName: 'MeloUnion',
      // The registry-based Windows implementation does not quote paths itself.
      // MSIX uses a shortcut and requires the unquoted target path.
      appPath: runningFromMsix ? executable : '"$executable"',
      packageName: packageName,
      args: const ['--hidden'],
    );

    try {
      _launchAtStartupEnabled = await launchAtStartup.isEnabled();
      if (_launchAtStartupEnabled && runningFromMsix) {
        // MSIX install paths are versioned. Refresh the existing shortcut so
        // an app update does not leave startup pointing at the old package.
        await launchAtStartup.enable();
      }
    } catch (_) {
      _error = '无法读取 Windows 开机启动状态';
    }

    try {
      await trayManager.setIcon('windows/runner/resources/app_icon.ico');
      await trayManager.setToolTip('MeloUnion');
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: _showWindowKey, label: '显示 MeloUnion'),
            MenuItem.separator(),
            MenuItem(key: _exitAppKey, label: '退出'),
          ],
        ),
      );
      trayManager.addListener(this);
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);
      _trayReady = true;
    } catch (error, stackTrace) {
      debugPrint('Windows tray initialization failed: $error\n$stackTrace');
      _error = 'Windows 托盘初始化失败，关闭窗口将正常退出';
      trayManager.removeListener(this);
      windowManager.removeListener(this);
      await windowManager.setPreventClose(false);
    }
    notifyListeners();
  }

  Future<void> setLaunchAtStartup(bool enabled) async {
    if (!isSupported || _launchAtStartupUpdating) return;
    _launchAtStartupUpdating = true;
    _error = null;
    notifyListeners();
    try {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      _launchAtStartupEnabled = await launchAtStartup.isEnabled();
      if (_launchAtStartupEnabled != enabled) {
        _error = enabled ? 'Windows 未允许开机启动' : 'Windows 未移除开机启动';
      }
    } catch (_) {
      _error = enabled ? '启用开机启动失败' : '关闭开机启动失败';
    } finally {
      _launchAtStartupUpdating = false;
      notifyListeners();
    }
  }

  Future<void> setKeepInTray(bool enabled) async {
    if (!isSupported) return;
    _keepInTray = enabled;
    await _writePreferences();
    notifyListeners();
  }

  Future<void> showWindow() async {
    if (!isSupported) return;
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> exitApplication() async {
    if (!isSupported || _quitting) return;
    _quitting = true;
    try {
      // Hide first so a slow persistence/audio teardown never leaves a
      // visible window that looks frozen to the user.
      await windowManager.hide();
      await _onExit?.call();
    } finally {
      await windowManager.setPreventClose(false);
      await trayManager.destroy();
      await windowManager.destroy();
    }
  }

  @override
  void onWindowClose() {
    if (_quitting || !_trayReady) return;
    if (_keepInTray) {
      unawaited(windowManager.hide());
    } else {
      unawaited(exitApplication());
    }
  }

  @override
  void onWindowMinimize() {
    if (!_trayReady || !_keepInTray) return;
    unawaited(windowManager.hide());
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(showWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case _showWindowKey:
        unawaited(showWindow());
      case _exitAppKey:
        unawaited(exitApplication());
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final file = _preferenceFile;
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<Object?, Object?>) {
        _keepInTray = decoded['keepInTray'] as bool? ?? false;
      }
    } catch (_) {
      _error = '无法读取 Windows 后台运行偏好';
    }
  }

  Future<void> _writePreferences() async {
    try {
      final file = _preferenceFile;
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode({'keepInTray': _keepInTray}));
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
    } catch (_) {
      _error = '无法保存 Windows 后台运行偏好';
    }
  }

  File get _preferenceFile {
    final environment = Platform.environment;
    final explicitDataDirectory = environment['MELO_UNION_DATA_DIR'];
    final root =
        explicitDataDirectory != null && explicitDataDirectory.trim().isNotEmpty
            ? explicitDataDirectory
            : path.join(
                environment['APPDATA'] ??
                    environment['LOCALAPPDATA'] ??
                    Directory.systemTemp.path,
                'MeloUnion',
              );
    return File(path.join(root, 'desktop_preferences.json'));
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }
}
