import 'melo_data_snapshot.dart';

abstract interface class MeloSnapshotStore {
  Future<MeloDataSnapshot?> read();

  Future<void> write(MeloDataSnapshot snapshot);

  Future<void> clear();
}
