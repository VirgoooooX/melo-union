import 'package:music_data/music_data.dart';

final class ManagedSnapshotStore {
  ManagedSnapshotStore({
    required this.store,
    Future<void> Function()? close,
  }) : close = close ?? _closeNoop;

  final MeloSnapshotStore? store;
  final Future<void> Function() close;

  static Future<void> _closeNoop() async {}
}
