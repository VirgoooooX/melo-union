import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:music_domain/music_domain.dart';
import 'package:music_data/music_data.dart';
import 'package:provider_kugou/provider_kugou.dart';
import 'audio_cache_manager.dart';
import 'demo_repository.dart';
import 'kugou_session_store.dart';
import 'kugou_session_store_factory.dart';
import 'managed_snapshot_store.dart';
import 'netease_session_store.dart';
import 'netease_session_store_factory.dart';
import 'qq_music_session_store.dart';
import 'qq_music_session_store_factory.dart';
import 'snapshot_store_factory.dart';
import '../local_library/local_library_controller.dart';
import '../local_library/local_library_scanner.dart';

typedef SnapshotStoreFactory = Future<ManagedSnapshotStore> Function();
typedef NeteaseSessionStoreFactory = NeteaseSessionStore Function();
typedef QqMusicSessionStoreFactory = QqMusicSessionStore Function();
typedef KugouSessionStoreFactory = KugouSessionStore Function();

final class AppBootstrap {
  AppBootstrap({
    required this.repository,
    required this.close,
  });

  final DemoRepository repository;
  final Future<void> Function() close;
}

Future<AppBootstrap> createAppBootstrap({
  SnapshotStoreFactory createStore = createSnapshotStore,
  NeteaseSessionStoreFactory createNeteaseStore = createNeteaseSessionStore,
  QqMusicSessionStoreFactory createQqMusicStore = createQqMusicSessionStore,
  KugouSessionStoreFactory createKugouStore = createKugouSessionStore,
}) async {
  final managedStore = await createStore();
  final neteaseSessionStore = createNeteaseStore();
  final qqMusicSessionStore = createQqMusicStore();
  final kugouSessionStore = createKugouStore();
  MeloDataSnapshot? snapshot;
  var persistentStoreHealthy = true;
  try {
    snapshot = await managedStore.store?.read();
  } catch (e, stackTrace) {
    persistentStoreHealthy = false;
    debugPrint(
      'Failed to read snapshot from store; preserving the database and '
      'disabling persistence for this run: $e\n$stackTrace',
    );
    snapshot = MeloDataSnapshot();
  }

  // The audio cache and local library share the same Drift database as the
  // snapshot store. If startup hydration failed, keep that database untouched
  // and run without database-backed services so an empty fallback state cannot
  // overwrite recoverable user data.
  final cacheStore =
      persistentStoreHealthy ? managedStore.audioCacheStore : null;
  final cacheDirectory =
      persistentStoreHealthy ? managedStore.audioCacheDirectory : null;
  final audioCacheManager = cacheStore == null || cacheDirectory == null
      ? null
      : await AudioCacheManager.open(
          store: cacheStore,
          directory: cacheDirectory,
          defaultPolicy: AudioCachePolicy(
            enabled: true,
            wifiOnly: true,
            maxBytes: Platform.isAndroid
                ? 1024 * 1024 * 1024
                : 2 * 1024 * 1024 * 1024,
          ),
        );
  final neteaseCredentials = await neteaseSessionStore.read();
  final qqMusicCredentials = await qqMusicSessionStore.read();
  final KugouSession? kugouSession = await kugouSessionStore.read();
  final localRepository =
      persistentStoreHealthy ? managedStore.localLibraryRepository : null;
  final localController =
      !kIsWeb && Platform.isWindows && localRepository != null
          ? LocalLibraryController(
              repository: localRepository,
              scanner: LocalLibraryScanner(
                repository: localRepository,
                artworkDirectory: Directory(
                  '${managedStore.audioCacheDirectory?.parent.path ?? Directory.systemTemp.path}'
                  '${Platform.pathSeparator}local_artwork',
                ),
              ),
            )
          : null;
  final repository = DemoRepository.seeded(
    snapshot: snapshot,
    snapshotStore: persistentStoreHealthy ? managedStore.store : null,
    neteaseCredentials: neteaseCredentials,
    neteaseSessionStore: neteaseSessionStore,
    qqMusicCredentials: qqMusicCredentials,
    qqMusicSessionStore: qqMusicSessionStore,
    kugouSession: kugouSession,
    kugouSessionStore: kugouSessionStore,
    audioCacheManager: audioCacheManager,
    localLibraryController: localController,
  );
  unawaited(repository.refreshQqMusicCredentials());
  if (localController != null) {
    await localController.initialize(scanOnStartup: false);
    unawaited(localController.scanAll());
  }

  return AppBootstrap(
    repository: repository,
    close: () async {
      await repository.close();
      await managedStore.close();
    },
  );
}
