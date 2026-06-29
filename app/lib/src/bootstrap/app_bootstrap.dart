import 'demo_repository.dart';
import 'managed_snapshot_store.dart';
import 'snapshot_store_factory.dart';

typedef SnapshotStoreFactory = Future<ManagedSnapshotStore> Function();

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
}) async {
  final managedStore = await createStore();
  final snapshot = await managedStore.store?.read();
  final repository = DemoRepository.seeded(
    snapshot: snapshot,
    snapshotStore: managedStore.store,
  );

  return AppBootstrap(
    repository: repository,
    close: managedStore.close,
  );
}
