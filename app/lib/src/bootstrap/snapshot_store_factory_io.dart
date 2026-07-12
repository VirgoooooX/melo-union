import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:music_data/music_data_drift.dart';
import 'package:path/path.dart' as path;

import 'managed_snapshot_store.dart';

const _androidStorageChannel = MethodChannel('melo_union/storage');
const _dataDirOverrideEnv = 'MELO_UNION_DATA_DIR';

Future<ManagedSnapshotStore> createSnapshotStore() async {
  final dataDirectory = await _resolveDataDirectory();
  await dataDirectory.create(recursive: true);

  final database = MeloDriftDatabase(
    NativeDatabase.createInBackground(
      File(path.join(dataDirectory.path, 'melo_union.sqlite')),
    ),
  );

  return ManagedSnapshotStore(
    store: DriftMeloDataStore(database: database),
    audioCacheStore: DriftAudioCacheStore(database: database),
    audioCacheDirectory: await _resolveAudioCacheDirectory(),
    localLibraryRepository:
        Platform.isWindows ? DriftLocalLibraryRepository(database) : null,
    close: database.close,
  );
}

Future<Directory> _resolveAudioCacheDirectory() async {
  if (Platform.isAndroid) {
    try {
      final androidPath = await _androidStorageChannel.invokeMethod<String>(
        'getApplicationCacheDirectory',
      );
      if (androidPath != null && androidPath.trim().isNotEmpty) {
        return Directory(path.join(androidPath, 'melo_union', 'audio'));
      }
    } on MissingPluginException {
      // Unit tests and non-Flutter VM runs use the generic fallback.
    } on PlatformException {
      // Fall through to the generic writable location.
    }
  }
  if (Platform.isWindows) {
    final root =
        Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
    return Directory(path.join(root, 'MeloUnion', 'Cache', 'audio'));
  }
  return Directory(
      path.join(_defaultSupportRoot().path, 'MeloUnion', 'Cache', 'audio'));
}

Future<Directory> _resolveDataDirectory() async {
  final override = Platform.environment[_dataDirOverrideEnv];
  if (override != null && override.trim().isNotEmpty) {
    return Directory(override);
  }

  if (Platform.isAndroid) {
    try {
      final androidPath = await _androidStorageChannel.invokeMethod<String>(
        'getApplicationSupportDirectory',
      );
      if (androidPath != null && androidPath.trim().isNotEmpty) {
        return Directory(path.join(androidPath, 'melo_union'));
      }
    } on MissingPluginException {
      // Unit tests and non-Flutter VM runs do not have the Android host channel.
    } on PlatformException {
      // Fall through to the generic writable location.
    }
  }

  return Directory(path.join(_defaultSupportRoot().path, 'MeloUnion'));
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
