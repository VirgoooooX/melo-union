import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../bootstrap/qq_music_background_refresh.dart';

final windowsQqRefreshTaskController = WindowsQqRefreshTaskController();

typedef WindowsProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

class WindowsQqRefreshTaskController extends ChangeNotifier {
  WindowsQqRefreshTaskController({
    bool? supportedOverride,
    String? executablePath,
    Map<String, String>? environment,
    WindowsProcessRunner? processRunner,
    File? stateFile,
  })  : _supportedOverride = supportedOverride,
        _executablePath = executablePath ?? Platform.resolvedExecutable,
        _environment = environment ?? Platform.environment,
        _processRunner = processRunner ?? _runProcess,
        _stateFileOverride = stateFile;

  static const taskName = 'MeloUnion QQ Music Credential Refresh';

  final bool? _supportedOverride;
  final String _executablePath;
  final Map<String, String> _environment;
  final WindowsProcessRunner _processRunner;
  final File? _stateFileOverride;

  bool _loaded = false;
  bool _desiredEnabled = true;
  bool _hasQqSession = false;
  bool _taskRegistered = false;
  bool _updating = false;
  DateTime? _lastRunAt;
  QqMusicBackgroundRefreshStatus? _lastStatus;
  String? _lastMessage;
  String? _error;

  bool get isSupported => _supportedOverride ?? Platform.isWindows;
  bool get desiredEnabled => _desiredEnabled;
  bool get hasQqSession => _hasQqSession;
  bool get taskRegistered => _taskRegistered;
  bool get updating => _updating;
  DateTime? get lastRunAt => _lastRunAt;
  QqMusicBackgroundRefreshStatus? get lastStatus => _lastStatus;
  String? get lastMessage => _lastMessage;
  String? get error => _error;

  Future<void> initialize({required bool hasQqSession}) async {
    if (!isSupported) return;
    await _loadState();
    _hasQqSession = hasQqSession;
    await _reconcileTask();
  }

  Future<void> onQqSessionChanged(bool hasSession) async {
    if (!isSupported) return;
    await _loadState();
    _hasQqSession = hasSession;
    await _reconcileTask();
  }

  Future<void> setEnabled(bool enabled) async {
    if (!isSupported || _updating) return;
    await _loadState();
    _desiredEnabled = enabled;
    await _writeState();
    await _reconcileTask();
  }

  Future<void> recordRefreshOutcome(
    QqMusicBackgroundRefreshOutcome outcome, {
    DateTime? occurredAt,
  }) async {
    await _loadState();
    _lastRunAt = (occurredAt ?? DateTime.now()).toUtc();
    _lastStatus = outcome.status;
    _lastMessage = outcome.message;
    await _writeState();
    notifyListeners();
  }

  Future<void> _reconcileTask() async {
    if (!isSupported || _updating) return;
    _updating = true;
    _error = null;
    notifyListeners();
    try {
      if (_desiredEnabled && _hasQqSession) {
        final result = await _processRunner('schtasks.exe', [
          '/Create',
          '/TN',
          taskName,
          '/TR',
          '"${_executablePath.replaceAll('"', '')}" '
              '--refresh-qq-and-exit',
          '/SC',
          'HOURLY',
          '/MO',
          '1',
          '/RL',
          'LIMITED',
          '/IT',
          '/F',
        ]);
        _taskRegistered = result.exitCode == 0;
        if (!_taskRegistered) {
          _error = 'Windows 计划任务注册失败（退出码 ${result.exitCode}）';
        }
      } else {
        final query = await _processRunner('schtasks.exe', [
          '/Query',
          '/TN',
          taskName,
        ]);
        if (query.exitCode == 0) {
          final result = await _processRunner('schtasks.exe', [
            '/Delete',
            '/TN',
            taskName,
            '/F',
          ]);
          if (result.exitCode != 0) {
            _error = 'Windows 计划任务删除失败（退出码 ${result.exitCode}）';
          }
        }
        _taskRegistered = false;
      }
      await _writeState();
    } catch (error) {
      _taskRegistered = false;
      _error = 'Windows 计划任务操作异常（${error.runtimeType}）';
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  Future<void> _loadState() async {
    if (_loaded) return;
    _loaded = true;
    final file = _stateFile;
    try {
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<Object?, Object?>) return;
      final state = decoded.map((key, value) => MapEntry('$key', value));
      _desiredEnabled = state['enabled'] as bool? ?? true;
      _lastRunAt = DateTime.tryParse(state['lastRunAt']?.toString() ?? '');
      _lastStatus = QqMusicBackgroundRefreshStatus.values
          .where((status) => status.name == state['lastStatus'])
          .firstOrNull;
      _lastMessage = state['lastMessage']?.toString();
    } catch (_) {
      _error = '无法读取 QQ 音乐计划任务状态';
    }
  }

  Future<void> _writeState() async {
    final file = _stateFile;
    try {
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode({
        'enabled': _desiredEnabled,
        if (_lastRunAt != null) 'lastRunAt': _lastRunAt!.toIso8601String(),
        if (_lastStatus != null) 'lastStatus': _lastStatus!.name,
        if (_lastMessage != null) 'lastMessage': _lastMessage,
      }));
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
    } catch (_) {
      _error ??= '无法保存 QQ 音乐计划任务状态';
    }
  }

  File get _stateFile {
    final override = _stateFileOverride;
    if (override != null) return override;
    final explicitDataDirectory = _environment['MELO_UNION_DATA_DIR'];
    final root =
        explicitDataDirectory != null && explicitDataDirectory.trim().isNotEmpty
            ? explicitDataDirectory
            : path.join(
                _environment['APPDATA'] ??
                    _environment['LOCALAPPDATA'] ??
                    Directory.systemTemp.path,
                'MeloUnion',
              );
    return File(path.join(root, 'qq_refresh_task.json'));
  }

  static Future<ProcessResult> _runProcess(
    String executable,
    List<String> arguments,
  ) {
    return Process.run(executable, arguments, runInShell: false);
  }
}
