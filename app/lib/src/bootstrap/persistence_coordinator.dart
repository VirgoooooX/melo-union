import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:music_data/music_data.dart';

final class PersistenceCoordinator {
  PersistenceCoordinator({
    required this.store,
    required this.snapshotProvider,
    Duration? delay,
  }) : delay = delay ??
            (Platform.environment.containsKey('FLUTTER_TEST')
                ? Duration.zero
                : const Duration(milliseconds: 400));

  final MeloSnapshotStore? store;
  final MeloDataSnapshot Function() snapshotProvider;
  final Duration delay;

  Timer? _fullWriteTimer;
  Timer? _playbackWriteTimer;

  // Sequential task queue to ensure no parallel writes.
  final List<Future<void> Function()> _queue = [];

  void scheduleFullWrite() {
    _fullWriteTimer?.cancel();
    _fullWriteTimer = Timer(delay, () {
      _enqueueWrite(() async {
        final storeLocal = store;
        if (storeLocal != null) {
          final snapshot = snapshotProvider();
          await storeLocal.write(snapshot);
        }
      });
    });
  }

  void schedulePlaybackStateWrite(
    PlaybackPreferencesSnapshot preferences,
    PlaybackQueueSnapshot? queue,
  ) {
    _playbackWriteTimer?.cancel();
    _playbackWriteTimer = Timer(delay, () {
      _enqueueWrite(() async {
        final storeLocal = store;
        if (storeLocal is PlaybackStateStore) {
          await (storeLocal as PlaybackStateStore).writePlaybackState(
            preferences: preferences,
            queue: queue,
          );
        } else if (storeLocal != null) {
          // Fallback if the store does not support incremental playback state writes (e.g. mock/test stores).
          final snapshot = snapshotProvider();
          await storeLocal.write(snapshot);
        }
      });
    });
  }

  Future<void> persistNow() async {
    _fullWriteTimer?.cancel();
    _playbackWriteTimer?.cancel();
    
    final completer = Completer<void>();
    _enqueueWrite(() async {
      try {
        final storeLocal = store;
        if (storeLocal != null) {
          final snapshot = snapshotProvider();
          await storeLocal.write(snapshot);
        }
        completer.complete();
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    await completer.future;
  }

  void _enqueueWrite(Future<void> Function() task) {
    _queue.add(task);
    _processQueue();
  }

  bool _processing = false;
  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      while (_queue.isNotEmpty) {
        final task = _queue.removeAt(0);
        try {
          await task();
        } catch (e, st) {
          debugPrint('PersistenceCoordinator write error: $e\n$st');
        }
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> close() async {
    _fullWriteTimer?.cancel();
    _playbackWriteTimer?.cancel();
    await persistNow();
  }
}
