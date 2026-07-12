import 'dart:io';

import 'package:music_data/music_data.dart';
import 'package:music_domain/music_domain.dart';

final class ManagedSnapshotStore {
  ManagedSnapshotStore({
    required this.store,
    this.audioCacheStore,
    this.audioCacheDirectory,
    this.localLibraryRepository,
    Future<void> Function()? close,
  }) : close = close ?? _closeNoop;

  final MeloSnapshotStore? store;
  final AudioCacheStore? audioCacheStore;
  final Directory? audioCacheDirectory;
  final LocalLibraryRepository? localLibraryRepository;
  final Future<void> Function() close;

  static Future<void> _closeNoop() async {}
}
