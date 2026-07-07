import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../demo_repository.dart';
import '../kugou_session_store.dart';
import '../netease_session_store.dart';
import '../qq_music_session_store.dart';
import 'account_vault_service.dart';
import 'backup_archive_service.dart';
import 'backup_target.dart';
import 'webdav_config_store.dart';

enum BackupRestoreMode {
  dataOnly,
  accountsOnly,
  dataAndAccounts;

  bool get restoresData => this != accountsOnly;
  bool get restoresAccounts => this != dataOnly;
}

final class BackupBuildResult {
  const BackupBuildResult({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

final class BackupRestoreResult {
  const BackupRestoreResult({
    required this.manifest,
    this.preRestoreBackupPath,
    required this.restoredData,
    required this.restoredAccounts,
  });

  final BackupManifest manifest;
  final String? preRestoreBackupPath;
  final bool restoredData;
  final bool restoredAccounts;
}

final class BackupCoordinator {
  BackupCoordinator({
    required this.repository,
    required this.accountVaultService,
    this.archiveService = const BackupArchiveService(),
    this.webDavConfigStore = const PlatformWebDavConfigStore(),
    Directory? preRestoreDirectory,
    DateTime Function()? now,
  })  : _preRestoreDirectory = preRestoreDirectory,
        _now = now ?? DateTime.now;

  factory BackupCoordinator.forRepository(
    DemoRepository repository, {
    BackupArchiveService archiveService = const BackupArchiveService(),
    WebDavConfigStore webDavConfigStore = const PlatformWebDavConfigStore(),
    Directory? preRestoreDirectory,
    DateTime Function()? now,
  }) {
    return BackupCoordinator(
      repository: repository,
      archiveService: archiveService,
      webDavConfigStore: webDavConfigStore,
      preRestoreDirectory: preRestoreDirectory,
      now: now,
      accountVaultService: AccountVaultService(
        neteaseSessionStore:
            repository.neteaseSessionStore ?? const NullNeteaseSessionStore(),
        qqMusicSessionStore:
            repository.qqMusicSessionStore ?? const NullQqMusicSessionStore(),
        kugouSessionStore:
            repository.kugouSessionStore ?? const NullKugouSessionStore(),
      ),
    );
  }

  final DemoRepository repository;
  final AccountVaultService accountVaultService;
  final BackupArchiveService archiveService;
  final WebDavConfigStore webDavConfigStore;
  final Directory? _preRestoreDirectory;
  final DateTime Function() _now;

  Future<BackupBuildResult> createBackup({
    bool includeAccounts = false,
    String? accountPassword,
  }) async {
    await repository.persistNow();
    final now = _now().toUtc();
    final accountVaultBytes = includeAccounts
        ? await accountVaultService.exportEncrypted(accountPassword ?? '')
        : null;
    return BackupBuildResult(
      fileName: backupFileName(now),
      bytes: archiveService.createArchive(
        snapshot: repository.toSnapshot(),
        deviceName: await _deviceName(),
        platform: Platform.operatingSystem,
        accountVaultBytes: accountVaultBytes,
        now: now,
      ),
    );
  }

  BackupArchivePayload readBackup(Uint8List bytes) {
    return archiveService.readArchive(bytes);
  }

  Future<BackupRestoreResult> restoreFromBackupBytes({
    required Uint8List bytes,
    required BackupRestoreMode mode,
    String? accountPassword,
  }) async {
    final payload = archiveService.readArchive(bytes);
    if (mode.restoresAccounts && payload.accountVaultBytes == null) {
      throw const FormatException('Backup does not include an account vault.');
    }

    var restoredAccounts = false;
    if (mode.restoresAccounts) {
      await accountVaultService.importEncrypted(
        payload.accountVaultBytes!,
        accountPassword ?? '',
      );
      restoredAccounts = true;
    }

    String? preRestorePath;
    if (mode.restoresData) {
      preRestorePath = await createPreRestoreBackup();
      await repository.restoreFromSnapshot(payload.snapshot);
      unawaited(repository.refreshFavoritesAfterRestore());
    }

    return BackupRestoreResult(
      manifest: payload.manifest,
      preRestoreBackupPath: preRestorePath,
      restoredData: mode.restoresData,
      restoredAccounts: restoredAccounts,
    );
  }

  Future<String> createPreRestoreBackup() async {
    final backup = await createBackup();
    final directory = await _resolvedPreRestoreDirectory();
    await directory.create(recursive: true);
    final file = File(path.join(directory.path, backup.fileName));
    await file.writeAsBytes(backup.bytes, flush: true);
    return file.path;
  }

  Future<WebDavConfig?> readWebDavConfig() => webDavConfigStore.read();

  Future<void> saveWebDavConfig(WebDavConfig config) {
    _validateWebDavConfig(config);
    return webDavConfigStore.write(config);
  }

  Future<void> clearWebDavConfig() => webDavConfigStore.clear();

  Future<void> testWebDav(WebDavConfig config) {
    _validateWebDavConfig(config);
    return WebDavBackupTarget(config: config).testConnection();
  }

  Future<List<BackupRemoteEntry>> listWebDavBackups() async {
    final config = await _requireWebDavConfig();
    return WebDavBackupTarget(config: config).listBackups();
  }

  Future<void> uploadBackupToWebDav({
    bool includeAccounts = false,
    String? accountPassword,
  }) async {
    final config = await _requireWebDavConfig();
    final backup = await createBackup(
      includeAccounts: includeAccounts,
      accountPassword: accountPassword,
    );
    await WebDavBackupTarget(config: config).uploadBackup(
      backup.fileName,
      backup.bytes,
    );
  }

  Future<Uint8List> downloadWebDavBackup(BackupRemoteEntry entry) async {
    final config = await _requireWebDavConfig();
    return WebDavBackupTarget(config: config).downloadBackup(entry.path);
  }

  Future<void> deleteWebDavBackup(BackupRemoteEntry entry) async {
    final config = await _requireWebDavConfig();
    return WebDavBackupTarget(config: config).deleteBackup(entry.path);
  }

  Future<WebDavConfig> _requireWebDavConfig() async {
    final config = await webDavConfigStore.read();
    if (config == null) {
      throw const FormatException('WebDAV is not configured.');
    }
    _validateWebDavConfig(config);
    return config;
  }

  void _validateWebDavConfig(WebDavConfig config) {
    if (!config.baseUri.hasScheme || config.baseUri.host.trim().isEmpty) {
      throw const FormatException('WebDAV URL is invalid.');
    }
    if (config.username.trim().isEmpty || config.password.isEmpty) {
      throw const FormatException('WebDAV username and password are required.');
    }
  }

  Future<Directory> _resolvedPreRestoreDirectory() async {
    if (_preRestoreDirectory != null) {
      return _preRestoreDirectory;
    }
    return Directory(
      path.join(_defaultSupportRoot().path, 'MeloUnion', 'pre_restore_backups'),
    );
  }

  Future<String> _deviceName() async {
    try {
      final hostname = Platform.localHostname.trim();
      if (hostname.isNotEmpty) return hostname;
    } catch (_) {}
    return Platform.operatingSystem;
  }

  static String backupFileName(DateTime createdAt) {
    final local = createdAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp = '${local.year}${two(local.month)}${two(local.day)}-'
        '${two(local.hour)}${two(local.minute)}${two(local.second)}';
    return 'melo-union-backup-$stamp.melobak';
  }

  Directory _defaultSupportRoot() {
    final environment = Platform.environment;
    if (Platform.isWindows) {
      return Directory(
        environment['APPDATA'] ??
            environment['LOCALAPPDATA'] ??
            Directory.systemTemp.path,
      );
    }
    if (Platform.isMacOS) {
      final home = environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(path.join(home, 'Library', 'Application Support'));
      }
    }
    if (Platform.isLinux) {
      final xdgDataHome = environment['XDG_DATA_HOME'];
      if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
        return Directory(xdgDataHome);
      }
      final home = environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(path.join(home, '.local', 'share'));
      }
    }
    return Directory.systemTemp;
  }
}
