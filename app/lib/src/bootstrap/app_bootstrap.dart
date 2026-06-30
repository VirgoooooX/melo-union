import 'demo_repository.dart';
import 'managed_snapshot_store.dart';
import 'netease_session_store.dart';
import 'netease_session_store_factory.dart';
import 'qq_music_session_store.dart';
import 'qq_music_session_store_factory.dart';
import 'snapshot_store_factory.dart';

typedef SnapshotStoreFactory = Future<ManagedSnapshotStore> Function();
typedef NeteaseSessionStoreFactory = NeteaseSessionStore Function();
typedef QqMusicSessionStoreFactory = QqMusicSessionStore Function();

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
}) async {
  final managedStore = await createStore();
  final neteaseSessionStore = createNeteaseStore();
  final qqMusicSessionStore = createQqMusicStore();
  final snapshot = await managedStore.store?.read();
  final neteaseCredentials = await neteaseSessionStore.read();
  final qqMusicCredentials = await qqMusicSessionStore.read();
  final repository = DemoRepository.seeded(
    snapshot: snapshot,
    snapshotStore: managedStore.store,
    neteaseCredentials: neteaseCredentials,
    neteaseSessionStore: neteaseSessionStore,
    qqMusicCredentials: qqMusicCredentials,
    qqMusicSessionStore: qqMusicSessionStore,
  );

  return AppBootstrap(
    repository: repository,
    close: managedStore.close,
  );
}
