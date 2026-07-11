import 'dart:io';

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
  final cacheStore = managedStore.audioCacheStore;
  final cacheDirectory = managedStore.audioCacheDirectory;
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
  MeloDataSnapshot? snapshot;
  try {
    snapshot = await managedStore.store?.read();
  } catch (e, stackTrace) {
    print('Failed to read snapshot from store: $e\n$stackTrace');
    try {
      await managedStore.store?.clear();
    } catch (clearError) {
      print('Failed to clear store after read failure: $clearError');
    }
    snapshot = MeloDataSnapshot();
  }
  final neteaseCredentials = await neteaseSessionStore.read();
  final qqMusicCredentials = await qqMusicSessionStore.read();
  final KugouSession? kugouSession = await kugouSessionStore.read();
  final repository = DemoRepository.seeded(
    snapshot: snapshot,
    snapshotStore: managedStore.store,
    neteaseCredentials: neteaseCredentials,
    neteaseSessionStore: neteaseSessionStore,
    qqMusicCredentials: qqMusicCredentials,
    qqMusicSessionStore: qqMusicSessionStore,
    kugouSession: kugouSession,
    kugouSessionStore: kugouSessionStore,
    audioCacheManager: audioCacheManager,
  );

  return AppBootstrap(
    repository: repository,
    close: () async {
      await repository.close();
      await managedStore.close();
    },
  );
}
