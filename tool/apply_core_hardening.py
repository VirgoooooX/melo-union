from __future__ import annotations

from pathlib import Path
import textwrap

ROOT = Path(__file__).resolve().parents[1]


def write(rel: str, content: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(content).lstrip(), encoding="utf-8")


def replace_once(rel: str, old: str, new: str) -> None:
    path = ROOT / rel
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"Expected text not found in {rel}: {old[:120]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def replace_region(rel: str, start: str, end: str, replacement: str) -> None:
    path = ROOT / rel
    text = path.read_text(encoding="utf-8")
    i = text.find(start)
    if i < 0:
        raise RuntimeError(f"Start marker not found in {rel}: {start!r}")
    j = text.find(end, i)
    if j < 0:
        raise RuntimeError(f"End marker not found in {rel}: {end!r}")
    patched = text[:i] + textwrap.dedent(replacement).lstrip() + "\n\n" + text[j:]
    path.write_text(patched, encoding="utf-8")


write(
    "packages/music_domain/lib/src/downloads/download_models.dart",
    r'''
    import 'package:provider_contract/provider_contract.dart';

    enum DownloadStatus {
      queued,
      resolving,
      downloading,
      paused,
      completed,
      failed,
      cancelled;
    }

    enum DownloadFailureKind {
      ticketExpired,
      authenticationRequired,
      unavailable,
      networkTimeout,
      connectionLost,
      rateLimited,
      serverError,
      insufficientStorage,
      permissionDenied,
      invalidContent,
      unknown;
    }

    const _downloadTaskUnset = Object();

    final class DownloadTask {
      DownloadTask({
        required this.track,
        required this.quality,
        this.status = DownloadStatus.queued,
        this.progress = 0.0,
        this.receivedBytes = 0,
        this.totalBytes,
        this.targetFilePath,
        this.temporaryFilePath,
        this.etag,
        this.lastModified,
        this.attempt = 0,
        this.failureKind,
        this.error,
        this.ticket,
        this.savedFilePath,
        DateTime? createdAt,
        DateTime? updatedAt,
      })  : createdAt = createdAt ?? DateTime.now().toUtc(),
            updatedAt = updatedAt ?? DateTime.now().toUtc();

      final SourceTrack track;
      final AudioQuality quality;
      final DownloadStatus status;
      final double progress;
      final int receivedBytes;
      final int? totalBytes;
      final String? targetFilePath;
      final String? temporaryFilePath;
      final String? etag;
      final String? lastModified;
      final int attempt;
      final DownloadFailureKind? failureKind;
      final String? error;
      final DownloadTicket? ticket;
      final String? savedFilePath;
      final DateTime createdAt;
      final DateTime updatedAt;

      String get identityKey =>
          '${track.ref.providerId.value}:${track.ref.trackId}:${quality.name}';

      DownloadTask copyWith({
        DownloadStatus? status,
        double? progress,
        int? receivedBytes,
        Object? totalBytes = _downloadTaskUnset,
        Object? targetFilePath = _downloadTaskUnset,
        Object? temporaryFilePath = _downloadTaskUnset,
        Object? etag = _downloadTaskUnset,
        Object? lastModified = _downloadTaskUnset,
        int? attempt,
        Object? failureKind = _downloadTaskUnset,
        Object? error = _downloadTaskUnset,
        Object? ticket = _downloadTaskUnset,
        Object? savedFilePath = _downloadTaskUnset,
        DateTime? updatedAt,
      }) {
        return DownloadTask(
          track: track,
          quality: quality,
          status: status ?? this.status,
          progress: progress ?? this.progress,
          receivedBytes: receivedBytes ?? this.receivedBytes,
          totalBytes: identical(totalBytes, _downloadTaskUnset)
              ? this.totalBytes
              : totalBytes as int?,
          targetFilePath: identical(targetFilePath, _downloadTaskUnset)
              ? this.targetFilePath
              : targetFilePath as String?,
          temporaryFilePath: identical(temporaryFilePath, _downloadTaskUnset)
              ? this.temporaryFilePath
              : temporaryFilePath as String?,
          etag: identical(etag, _downloadTaskUnset)
              ? this.etag
              : etag as String?,
          lastModified: identical(lastModified, _downloadTaskUnset)
              ? this.lastModified
              : lastModified as String?,
          attempt: attempt ?? this.attempt,
          failureKind: identical(failureKind, _downloadTaskUnset)
              ? this.failureKind
              : failureKind as DownloadFailureKind?,
          error: identical(error, _downloadTaskUnset)
              ? this.error
              : error as String?,
          ticket: identical(ticket, _downloadTaskUnset)
              ? this.ticket
              : ticket as DownloadTicket?,
          savedFilePath: identical(savedFilePath, _downloadTaskUnset)
              ? this.savedFilePath
              : savedFilePath as String?,
          createdAt: createdAt,
          updatedAt: updatedAt ?? DateTime.now().toUtc(),
        );
      }
    }

    final class LocalMediaItem {
      const LocalMediaItem({
        required this.sourceRef,
        required this.title,
        required this.artists,
        required this.duration,
        required this.filePath,
        required this.fileSize,
        required this.downloadedAt,
        this.quality = AudioQuality.low,
      });

      final ProviderTrackRef sourceRef;
      final String title;
      final List<String> artists;
      final Duration duration;
      final String filePath;
      final int fileSize;
      final DateTime downloadedAt;

      /// The quality actually returned by the provider, not merely requested.
      final AudioQuality quality;
    }
    ''',
)

write(
    "packages/music_domain/lib/src/downloads/download_coordinator.dart",
    r'''
    import 'package:provider_contract/provider_contract.dart';

    import 'download_models.dart';

    class DownloadCoordinator {
      DownloadCoordinator({
        required this.registry,
        List<DownloadTask> seedTasks = const [],
        List<LocalMediaItem> seedLocalItems = const [],
      })  : _tasks = {
              for (final task in seedTasks)
                task.track.ref: _normalizeSeedTask(task),
            },
            _localLibrary = {
              for (final item in seedLocalItems) item.sourceRef: item,
            };

      final StaticProviderRegistry registry;
      final Map<ProviderTrackRef, DownloadTask> _tasks;
      final Map<ProviderTrackRef, LocalMediaItem> _localLibrary;

      List<DownloadTask> get allTasks => _tasks.values.toList(growable: false);
      List<LocalMediaItem> get localItems =>
          _localLibrary.values.toList(growable: false);

      void replaceState({
        List<DownloadTask> tasks = const [],
        List<LocalMediaItem> localItems = const [],
      }) {
        _tasks
          ..clear()
          ..addEntries(tasks.map(
            (task) => MapEntry(task.track.ref, _normalizeSeedTask(task)),
          ));
        _localLibrary
          ..clear()
          ..addEntries(localItems.map((item) => MapEntry(item.sourceRef, item)));
      }

      bool isAvailableLocally(ProviderTrackRef ref) =>
          _localKeyFor(ref) != null;

      LocalMediaItem? getLocalItem(ProviderTrackRef ref) {
        final key = _localKeyFor(ref);
        return key == null ? null : _localLibrary[key];
      }

      LocalMediaItem? findLocalItem(
        ProviderTrackRef ref, {
        required AudioQuality requestedQuality,
        required bool allowLowerQuality,
      }) {
        final matches = _localLibrary.values
            .where((item) =>
                item.sourceRef.providerId == ref.providerId &&
                item.sourceRef.trackId == ref.trackId)
            .toList(growable: false);
        if (matches.isEmpty) return null;
        final eligible = allowLowerQuality
            ? matches
            : matches
                .where((item) => item.quality.meetsOrExceeds(requestedQuality))
                .toList(growable: false);
        if (eligible.isEmpty) return null;
        eligible.sort(
          (left, right) => right.quality.index.compareTo(left.quality.index),
        );
        return eligible.first;
      }

      void addTask(
        SourceTrack track, {
        AudioQuality quality = AudioQuality.standard,
      }) {
        if (_localKeyFor(track.ref) != null) return;
        final existing = _taskKeyFor(track.ref);
        if (existing != null) _tasks.remove(existing);
        _tasks[track.ref] = DownloadTask(
          track: track,
          quality: quality,
          status: DownloadStatus.queued,
        );
      }

      DownloadTask? getTask(ProviderTrackRef ref) {
        final key = _taskKeyFor(ref);
        return key == null ? null : _tasks[key];
      }

      void queueTask(ProviderTrackRef ref) {
        final task = getTask(ref);
        if (task == null || task.status == DownloadStatus.completed) return;
        _updateTask(task.copyWith(
          status: DownloadStatus.queued,
          error: null,
          failureKind: null,
          ticket: null,
        ));
      }

      Future<void> startTask(ProviderTrackRef ref) async {
        final task = getTask(ref);
        if (task == null || task.status == DownloadStatus.completed) return;

        _updateTask(task.copyWith(
          status: DownloadStatus.resolving,
          error: null,
          failureKind: null,
          ticket: null,
        ));

        try {
          final ticket = await _resolveTicket(task.track.ref, task.quality);
          final latest = getTask(task.track.ref);
          if (latest == null || latest.status != DownloadStatus.resolving) {
            return;
          }
          _updateTask(latest.copyWith(
            status: DownloadStatus.downloading,
            ticket: ticket,
          ));
        } catch (error) {
          final latest = getTask(task.track.ref);
          if (latest == null || latest.status != DownloadStatus.resolving) {
            return;
          }
          _updateTask(latest.copyWith(
            status: DownloadStatus.failed,
            failureKind: DownloadFailureKind.unknown,
            error: error.toString(),
            ticket: null,
          ));
        }
      }

      void recordAttempt(ProviderTrackRef ref, int attempt) {
        final task = getTask(ref);
        if (task == null) return;
        _updateTask(task.copyWith(attempt: attempt));
      }

      void updateTransferState(
        ProviderTrackRef ref, {
        required int receivedBytes,
        required int? totalBytes,
        String? targetFilePath,
        String? temporaryFilePath,
        String? etag,
        String? lastModified,
      }) {
        final task = getTask(ref);
        if (task == null) return;
        final progress = totalBytes == null || totalBytes <= 0
            ? task.progress
            : (receivedBytes / totalBytes).clamp(0.0, 0.99).toDouble();
        _updateTask(task.copyWith(
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
          targetFilePath: targetFilePath ?? task.targetFilePath,
          temporaryFilePath: temporaryFilePath ?? task.temporaryFilePath,
          etag: etag ?? task.etag,
          lastModified: lastModified ?? task.lastModified,
          progress: progress,
        ));
      }

      void updateProgress(ProviderTrackRef ref, double progress) {
        final task = getTask(ref);
        if (task == null || task.status != DownloadStatus.downloading) return;
        _updateTask(task.copyWith(
          progress: progress.clamp(0.0, 0.99).toDouble(),
        ));
      }

      LocalMediaItem? completeTask({
        required ProviderTrackRef ref,
        required String filePath,
        required int fileSize,
      }) {
        final task = getTask(ref);
        if (task == null) return null;
        final canonicalRef = task.track.ref;
        final item = LocalMediaItem(
          sourceRef: canonicalRef,
          title: task.track.title,
          artists: task.track.artists,
          duration: task.track.duration,
          filePath: filePath,
          fileSize: fileSize,
          downloadedAt: DateTime.now().toUtc(),
          quality: task.ticket?.quality ?? task.quality,
        );
        final existingLocalKey = _localKeyFor(canonicalRef);
        if (existingLocalKey != null) _localLibrary.remove(existingLocalKey);
        _localLibrary[canonicalRef] = item;
        _updateTask(task.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          receivedBytes: fileSize,
          totalBytes: fileSize,
          savedFilePath: filePath,
          targetFilePath: filePath,
          temporaryFilePath: null,
          ticket: null,
          failureKind: null,
          error: null,
        ));
        return item;
      }

      void failTask(
        ProviderTrackRef ref,
        Object error, {
        DownloadFailureKind kind = DownloadFailureKind.unknown,
      }) {
        final task = getTask(ref);
        if (task == null) return;
        _updateTask(task.copyWith(
          status: DownloadStatus.failed,
          failureKind: kind,
          error: error.toString(),
          ticket: null,
        ));
      }

      void pauseTask(ProviderTrackRef ref) {
        final task = getTask(ref);
        if (task == null) return;
        if (task.status == DownloadStatus.downloading ||
            task.status == DownloadStatus.resolving ||
            task.status == DownloadStatus.queued) {
          _updateTask(task.copyWith(
            status: DownloadStatus.paused,
            ticket: null,
          ));
        }
      }

      Future<void> resumeTask(ProviderTrackRef ref) => startTask(ref);

      void cancelTask(ProviderTrackRef ref) {
        final task = getTask(ref);
        if (task == null) return;
        _updateTask(task.copyWith(
          status: DownloadStatus.cancelled,
          ticket: null,
          progress: 0.0,
          receivedBytes: 0,
          totalBytes: null,
          temporaryFilePath: null,
          etag: null,
          lastModified: null,
        ));
      }

      void removeTask(ProviderTrackRef ref) {
        final key = _taskKeyFor(ref);
        if (key != null) _tasks.remove(key);
      }

      void removeLocalItem(ProviderTrackRef ref) {
        final localKey = _localKeyFor(ref);
        if (localKey != null) _localLibrary.remove(localKey);
        final task = getTask(ref);
        if (task != null) {
          _updateTask(task.copyWith(
            status: DownloadStatus.cancelled,
            progress: 0.0,
            receivedBytes: 0,
            totalBytes: null,
            ticket: null,
            savedFilePath: null,
            targetFilePath: null,
            temporaryFilePath: null,
            etag: null,
            lastModified: null,
          ));
        }
      }

      void simulateProgressStep(ProviderTrackRef ref) {
        final task = getTask(ref);
        if (task == null || task.status != DownloadStatus.downloading) return;

        final ticket = task.ticket;
        if (ticket == null || ticket.isExpired) {
          failTask(
            ref,
            'Download ticket has expired.',
            kind: DownloadFailureKind.ticketExpired,
          );
          return;
        }

        final nextProgress = (task.progress + 0.2).clamp(0.0, 1.0);
        if (nextProgress >= 1.0) {
          final filePath =
              'local://downloads/${ref.providerId.value}/${ref.trackId}.${ticket.fileExtension ?? 'mp3'}';
          completeTask(
            ref: ref,
            filePath: filePath,
            fileSize: ticket.bytes ?? (1024 * 1024 * 5),
          );
        } else {
          _updateTask(task.copyWith(progress: nextProgress));
        }
      }

      Future<void> runSimulationToCompletion(ProviderTrackRef ref) async {
        final task = getTask(ref);
        if (task == null) return;
        if (task.status == DownloadStatus.queued ||
            task.status == DownloadStatus.paused) {
          await startTask(ref);
        }
        while (getTask(ref)?.status == DownloadStatus.downloading) {
          simulateProgressStep(ref);
        }
      }

      void _updateTask(DownloadTask task) {
        final oldKey = _taskKeyFor(task.track.ref);
        if (oldKey != null && oldKey != task.track.ref) _tasks.remove(oldKey);
        _tasks[task.track.ref] = task;
      }

      ProviderTrackRef? _taskKeyFor(ProviderTrackRef ref) {
        if (_tasks.containsKey(ref)) return ref;
        for (final key in _tasks.keys) {
          if (key.providerId == ref.providerId && key.trackId == ref.trackId) {
            return key;
          }
        }
        return null;
      }

      ProviderTrackRef? _localKeyFor(ProviderTrackRef ref) {
        if (_localLibrary.containsKey(ref)) return ref;
        for (final key in _localLibrary.keys) {
          if (key.providerId == ref.providerId && key.trackId == ref.trackId) {
            return key;
          }
        }
        return null;
      }

      static DownloadTask _normalizeSeedTask(DownloadTask task) {
        if (task.status != DownloadStatus.resolving &&
            task.status != DownloadStatus.downloading) {
          return task.copyWith(ticket: null);
        }
        return task.copyWith(
          status: DownloadStatus.paused,
          ticket: null,
          error: null,
          failureKind: null,
        );
      }

      Future<DownloadTicket> _resolveTicket(
        ProviderTrackRef ref,
        AudioQuality quality,
      ) async {
        final entry = registry.entryOf(ref.providerId);
        if (entry == null) {
          throw ProviderException(
            providerId: ref.providerId,
            message: 'Provider ${ref.providerId.value} is not registered.',
          );
        }
        if (!entry.isEnabled) {
          throw ProviderDisabledException(
            providerId: ref.providerId,
            message: 'Provider ${ref.providerId.value} is disabled.',
          );
        }
        final provider = entry.provider;
        if (!provider.descriptor.supports(ProviderCapability.resolveDownload)) {
          throw CapabilityUnavailableException(
            providerId: ref.providerId,
            capability: ProviderCapability.resolveDownload,
            message: 'Provider ${ref.providerId.value} does not support downloads.',
          );
        }
        return provider.createDownloadTicket(track: ref, quality: quality);
      }
    }
    ''',
)

write(
    "app/lib/src/bootstrap/persistence_coordinator.dart",
    r'''
    import 'dart:async';
    import 'dart:io';

    import 'package:flutter/foundation.dart';
    import 'package:music_data/music_data.dart';
    import 'package:music_domain/music_domain.dart';
    import 'package:provider_contract/provider_contract.dart';

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
      Future<void> _tail = Future<void>.value();
      bool _closed = false;

      void scheduleFullWrite() {
        if (_closed || store == null) return;
        _fullWriteTimer?.cancel();
        _fullWriteTimer = Timer(delay, () {
          unawaited(_enqueue(_writeFullSnapshot));
        });
      }

      void schedulePlaybackStateWrite(
        PlaybackPreferencesSnapshot preferences,
        PlaybackQueueSnapshot? queue,
      ) {
        if (_closed || store == null) return;
        _playbackWriteTimer?.cancel();
        _playbackWriteTimer = Timer(delay, () {
          unawaited(_enqueue(() async {
            final currentStore = store;
            if (currentStore is PlaybackStateStore) {
              await currentStore.writePlaybackState(
                preferences: preferences,
                queue: queue,
              );
            } else {
              await _writeFullSnapshot();
            }
          }));
        });
      }

      void scheduleDownloadTaskWrite(DownloadTask task, int sortIndex) {
        if (_closed || store == null) return;
        final currentStore = store;
        if (currentStore is! DownloadStateStore) {
          scheduleFullWrite();
          return;
        }
        unawaited(_enqueue(() => currentStore.upsertDownloadTask(
              task,
              sortIndex: sortIndex,
            )));
      }

      void scheduleDownloadTaskDelete(ProviderTrackRef ref) {
        if (_closed || store == null) return;
        final currentStore = store;
        if (currentStore is! DownloadStateStore) {
          scheduleFullWrite();
          return;
        }
        unawaited(_enqueue(() => currentStore.deleteDownloadTask(ref)));
      }

      void scheduleLocalMediaWrite(LocalMediaItem item, int sortIndex) {
        if (_closed || store == null) return;
        final currentStore = store;
        if (currentStore is! DownloadStateStore) {
          scheduleFullWrite();
          return;
        }
        unawaited(_enqueue(() => currentStore.upsertLocalMediaItem(
              item,
              sortIndex: sortIndex,
            )));
      }

      void scheduleLocalMediaDelete(ProviderTrackRef ref) {
        if (_closed || store == null) return;
        final currentStore = store;
        if (currentStore is! DownloadStateStore) {
          scheduleFullWrite();
          return;
        }
        unawaited(_enqueue(() => currentStore.deleteLocalMediaItem(ref)));
      }

      Future<void> persistNow() async {
        if (_closed) return;
        _fullWriteTimer?.cancel();
        _playbackWriteTimer?.cancel();
        await _enqueue(_writeFullSnapshot);
      }

      Future<void> flush() async {
        await _tail;
      }

      Future<void> close() async {
        if (_closed) return;
        _fullWriteTimer?.cancel();
        _playbackWriteTimer?.cancel();
        await _enqueue(_writeFullSnapshot);
        await flush();
        _closed = true;
      }

      Future<void> _writeFullSnapshot() async {
        final currentStore = store;
        if (currentStore == null) return;
        await currentStore.write(snapshotProvider());
      }

      Future<void> _enqueue(Future<void> Function() task) {
        final previous = _tail;
        final completer = Completer<void>();
        _tail = () async {
          try {
            await previous;
          } catch (_) {
            // The previous caller already received/logged its own failure.
          }
          try {
            await task();
            if (!completer.isCompleted) completer.complete();
          } catch (error, stackTrace) {
            debugPrint('PersistenceCoordinator write error: $error\n$stackTrace');
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          }
        }();
        return completer.future;
      }
    }
    ''',
)

write(
    "app/lib/src/bootstrap/download_manager.dart",
    r'''
    import 'dart:async';
    import 'dart:collection';
    import 'dart:io';

    import 'package:music_domain/music_domain.dart';
    import 'package:provider_contract/provider_contract.dart';

    typedef DownloadTaskChanged = void Function(DownloadTask task);
    typedef DownloadTaskRemoved = void Function(ProviderTrackRef ref);
    typedef LocalMediaItemChanged = void Function(LocalMediaItem item);

    final class DownloadManager {
      DownloadManager({
        required this.coordinator,
        required this.onTaskChanged,
        required this.onTaskRemoved,
        required this.onLocalItemChanged,
        required this.resolveDownloadFile,
        required this.embedMetadata,
        this.maxConcurrent = 2,
        this.maxAttempts = 3,
        this.progressInterval = const Duration(milliseconds: 200),
        this.retryBaseDelay = const Duration(milliseconds: 500),
      }) : assert(maxConcurrent > 0);

      final DownloadCoordinator coordinator;
      final DownloadTaskChanged onTaskChanged;
      final DownloadTaskRemoved onTaskRemoved;
      final LocalMediaItemChanged onLocalItemChanged;
      final Future<File> Function(SourceTrack track, DownloadTicket ticket)
          resolveDownloadFile;
      final Future<void> Function(
        File file,
        SourceTrack track,
        DownloadTicket ticket,
      ) embedMetadata;
      final int maxConcurrent;
      final int maxAttempts;
      final Duration progressInterval;
      final Duration retryBaseDelay;

      final Queue<ProviderTrackRef> _pending = Queue<ProviderTrackRef>();
      final Set<String> _pendingKeys = <String>{};
      final Map<String, _ActiveDownload> _active = <String, _ActiveDownload>{};
      bool _closed = false;

      Future<void> startDownload(ProviderTrackRef ref) async {
        if (_closed) return;
        final task = coordinator.getTask(ref);
        if (task == null || task.status == DownloadStatus.completed) return;
        final key = _key(task.track.ref);
        if (_active.containsKey(key) || !_pendingKeys.add(key)) return;
        coordinator.queueTask(task.track.ref);
        _emitTask(task.track.ref);
        _pending.add(task.track.ref);
        _pump();
      }

      Future<void> pauseDownload(ProviderTrackRef ref) async {
        final task = coordinator.getTask(ref);
        if (task == null) return;
        final key = _key(task.track.ref);
        _removePending(key);
        final active = _active[key];
        if (active != null) {
          await active.requestStop(preservePartial: true);
          await active.done;
        }
        coordinator.pauseTask(task.track.ref);
        _emitTask(task.track.ref);
      }

      Future<void> cancelDownload(ProviderTrackRef ref) async {
        final task = coordinator.getTask(ref);
        if (task == null) return;
        final canonicalRef = task.track.ref;
        final key = _key(canonicalRef);
        _removePending(key);
        final active = _active[key];
        if (active != null) {
          await active.requestStop(preservePartial: false);
          await active.done;
        }
        await _deletePartial(coordinator.getTask(canonicalRef) ?? task);
        coordinator.cancelTask(canonicalRef);
        coordinator.removeTask(canonicalRef);
        onTaskRemoved(canonicalRef);
      }

      Future<void> close() async {
        if (_closed) return;
        _closed = true;
        final pending = _pending.toList(growable: false);
        _pending.clear();
        _pendingKeys.clear();
        for (final ref in pending) {
          coordinator.pauseTask(ref);
          _emitTask(ref);
        }
        final active = _active.values.toList(growable: false);
        await Future.wait(
          active.map((job) => job.requestStop(preservePartial: true)),
        );
        await Future.wait(active.map((job) => job.done));
        for (final job in active) {
          coordinator.pauseTask(job.ref);
          _emitTask(job.ref);
        }
      }

      void _pump() {
        if (_closed) return;
        while (_active.length < maxConcurrent && _pending.isNotEmpty) {
          final ref = _pending.removeFirst();
          final key = _key(ref);
          _pendingKeys.remove(key);
          final task = coordinator.getTask(ref);
          if (task == null || task.status == DownloadStatus.completed) continue;
          final active = _ActiveDownload(ref: task.track.ref);
          _active[key] = active;
          unawaited(_run(active));
        }
      }

      Future<void> _run(_ActiveDownload active) async {
        final ref = active.ref;
        final key = _key(ref);
        try {
          await coordinator.startTask(ref);
          _emitTask(ref);
          active.throwIfStopped();
          final task = coordinator.getTask(ref);
          final ticket = task?.ticket;
          if (task == null ||
              task.status != DownloadStatus.downloading ||
              ticket == null) {
            throw StateError(task?.error ?? 'Unable to resolve download ticket.');
          }
          await _downloadWithRetries(active);
        } on _DownloadStoppedException catch (stopped) {
          if (stopped.preservePartial) {
            coordinator.pauseTask(ref);
            _emitTask(ref);
          } else {
            final task = coordinator.getTask(ref);
            if (task != null) await _deletePartial(task);
          }
        } catch (error) {
          final kind = _failureKind(error);
          coordinator.failTask(ref, error, kind: kind);
          _emitTask(ref);
        } finally {
          await active.releaseTransport();
          if (identical(_active[key], active)) _active.remove(key);
          active.complete();
          _pump();
        }
      }

      Future<void> _downloadWithRetries(_ActiveDownload active) async {
        var attempt = 0;
        while (true) {
          active.throwIfStopped();
          attempt++;
          coordinator.recordAttempt(active.ref, attempt);
          _emitTask(active.ref);
          final task = coordinator.getTask(active.ref);
          final ticket = task?.ticket;
          if (task == null || ticket == null) {
            throw StateError(task?.error ?? 'Download ticket is missing.');
          }
          try {
            await _transfer(active, task, ticket);
            return;
          } on _RetryDownloadException catch (retry) {
            if (attempt >= maxAttempts) rethrow;
            if (retry.refreshTicket) {
              await coordinator.startTask(active.ref);
              _emitTask(active.ref);
              final refreshed = coordinator.getTask(active.ref);
              if (refreshed?.ticket == null) {
                throw StateError(refreshed?.error ?? 'Ticket refresh failed.');
              }
            }
            if (!retry.immediate) {
              await Future<void>.delayed(retryBaseDelay * attempt);
            }
          } on SocketException catch (error) {
            if (attempt >= maxAttempts) rethrow;
            await Future<void>.delayed(retryBaseDelay * attempt);
            if (error.osError?.errorCode == 28) rethrow;
          } on TimeoutException {
            if (attempt >= maxAttempts) rethrow;
            await Future<void>.delayed(retryBaseDelay * attempt);
          } on HttpException {
            if (attempt >= maxAttempts) rethrow;
            await Future<void>.delayed(retryBaseDelay * attempt);
          }
        }
      }

      Future<void> _transfer(
        _ActiveDownload active,
        DownloadTask task,
        DownloadTicket ticket,
      ) async {
        final uri = ticket.mediaUri;
        if (!uri.isScheme('http') && !uri.isScheme('https')) {
          throw FormatException(
            'Unsupported download URI scheme: ${uri.scheme}',
            uri.toString(),
          );
        }

        final target = task.targetFilePath == null
            ? await resolveDownloadFile(task.track, ticket)
            : File(task.targetFilePath!);
        await target.parent.create(recursive: true);
        final temporary = File(
          task.temporaryFilePath ?? '${target.path}.download.part',
        );
        await temporary.parent.create(recursive: true);
        var existingBytes = await temporary.exists() ? await temporary.length() : 0;

        coordinator.updateTransferState(
          active.ref,
          receivedBytes: existingBytes,
          totalBytes: task.totalBytes,
          targetFilePath: target.path,
          temporaryFilePath: temporary.path,
        );
        _emitTask(active.ref);

        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 20);
        active.setClient(client);
        active.throwIfStopped();
        final request = await client.getUrl(uri);
        active.setRequest(request);
        ticket.headers.forEach(request.headers.add);
        if (existingBytes > 0) {
          request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
          final validator = task.etag ?? task.lastModified;
          if (validator != null && validator.isNotEmpty) {
            request.headers.set('If-Range', validator);
          }
        }

        final response = await request.close().timeout(
              const Duration(seconds: 30),
            );
        active.throwIfStopped();

        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          await response.drain<void>();
          throw const _RetryDownloadException(refreshTicket: true);
        }
        if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
          final remoteTotal = _contentRangeTotal(
            response.headers.value(HttpHeaders.contentRangeHeader),
          );
          await response.drain<void>();
          if (remoteTotal != null && remoteTotal == existingBytes) {
            await _finalize(active, task, ticket, temporary, target);
            return;
          }
          if (await temporary.exists()) await temporary.delete();
          coordinator.updateTransferState(
            active.ref,
            receivedBytes: 0,
            totalBytes: remoteTotal,
            targetFilePath: target.path,
            temporaryFilePath: temporary.path,
            etag: response.headers.value(HttpHeaders.etagHeader),
            lastModified: response.headers.value(HttpHeaders.lastModifiedHeader),
          );
          _emitTask(active.ref);
          throw const _RetryDownloadException(immediate: true);
        }
        if (response.statusCode == HttpStatus.requestTimeout ||
            response.statusCode == HttpStatus.tooManyRequests ||
            response.statusCode >= 500) {
          await response.drain<void>();
          throw _RetryDownloadException(
            message: 'Download failed with HTTP ${response.statusCode}.',
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          await response.drain<void>();
          throw HttpException(
            'Download failed with HTTP ${response.statusCode}.',
            uri: uri,
          );
        }

        final append = existingBytes > 0 &&
            response.statusCode == HttpStatus.partialContent;
        if (!append) existingBytes = 0;
        final totalBytes = response.statusCode == HttpStatus.partialContent
            ? _contentRangeTotal(
                    response.headers.value(HttpHeaders.contentRangeHeader)) ??
                (response.contentLength > 0
                    ? existingBytes + response.contentLength
                    : task.totalBytes)
            : (response.contentLength > 0 ? response.contentLength : null);
        final etag = response.headers.value(HttpHeaders.etagHeader) ?? task.etag;
        final lastModified =
            response.headers.value(HttpHeaders.lastModifiedHeader) ??
                task.lastModified;

        final sink = temporary.openWrite(
          mode: append ? FileMode.append : FileMode.writeOnly,
        );
        var receivedBytes = existingBytes;
        var lastPublishedBytes = receivedBytes;
        var lastPublishedAt = DateTime.now();
        final transfer = Completer<void>();
        late final StreamSubscription<List<int>> subscription;
        subscription = response.listen(
          (chunk) {
            if (active.stopRequested) {
              if (!transfer.isCompleted) {
                transfer.completeError(active.stopException);
              }
              return;
            }
            try {
              sink.add(chunk);
              receivedBytes += chunk.length;
              final now = DateTime.now();
              if (now.difference(lastPublishedAt) >= progressInterval ||
                  receivedBytes - lastPublishedBytes >= 1024 * 1024) {
                lastPublishedAt = now;
                lastPublishedBytes = receivedBytes;
                coordinator.updateTransferState(
                  active.ref,
                  receivedBytes: receivedBytes,
                  totalBytes: totalBytes,
                  targetFilePath: target.path,
                  temporaryFilePath: temporary.path,
                  etag: etag,
                  lastModified: lastModified,
                );
                _emitTask(active.ref);
              }
            } catch (error, stackTrace) {
              if (!transfer.isCompleted) {
                transfer.completeError(error, stackTrace);
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!transfer.isCompleted) {
              transfer.completeError(error, stackTrace);
            }
          },
          onDone: () {
            if (!transfer.isCompleted) transfer.complete();
          },
          cancelOnError: true,
        );
        active.attachTransfer(
          subscription: subscription,
          sink: sink,
          transfer: transfer,
        );

        try {
          await transfer.future;
          active.throwIfStopped();
          await sink.flush();
          await sink.close();
          active.clearSink(sink);
        } finally {
          await subscription.cancel();
          active.clearSubscription(subscription);
        }

        coordinator.updateTransferState(
          active.ref,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
          targetFilePath: target.path,
          temporaryFilePath: temporary.path,
          etag: etag,
          lastModified: lastModified,
        );
        _emitTask(active.ref);

        if (totalBytes != null && receivedBytes != totalBytes) {
          throw HttpException(
            'Download ended early: $receivedBytes of $totalBytes bytes.',
            uri: uri,
          );
        }
        await _finalize(active, task, ticket, temporary, target);
      }

      Future<void> _finalize(
        _ActiveDownload active,
        DownloadTask task,
        DownloadTicket ticket,
        File temporary,
        File target,
      ) async {
        active.throwIfStopped();
        if (!await temporary.exists() || await temporary.length() <= 0) {
          throw const FormatException('Downloaded file is empty.');
        }
        await embedMetadata(temporary, task.track, ticket);
        active.throwIfStopped();
        if (await target.exists()) {
          throw FileSystemException(
            'Refusing to replace an existing download.',
            target.path,
          );
        }
        final committed = await temporary.rename(target.path);
        final fileSize = await committed.length();
        final item = coordinator.completeTask(
          ref: active.ref,
          filePath: committed.path,
          fileSize: fileSize,
        );
        _emitTask(active.ref);
        if (item != null) onLocalItemChanged(item);
      }

      void _removePending(String key) {
        _pending.removeWhere((ref) => _key(ref) == key);
        _pendingKeys.remove(key);
      }

      Future<void> _deletePartial(DownloadTask task) async {
        final path = task.temporaryFilePath;
        if (path == null || path.isEmpty) return;
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } on FileSystemException {
          // Cancellation cleanup is best effort; the startup reconciler can retry.
        }
      }

      void _emitTask(ProviderTrackRef ref) {
        final task = coordinator.getTask(ref);
        if (task != null) onTaskChanged(task);
      }

      String _key(ProviderTrackRef ref) =>
          '${ref.providerId.value}:${ref.trackId}';

      DownloadFailureKind _failureKind(Object error) {
        if (error is TimeoutException) return DownloadFailureKind.networkTimeout;
        if (error is SocketException) {
          if (error.osError?.errorCode == 28) {
            return DownloadFailureKind.insufficientStorage;
          }
          return DownloadFailureKind.connectionLost;
        }
        if (error is FileSystemException) {
          return DownloadFailureKind.permissionDenied;
        }
        if (error is FormatException) return DownloadFailureKind.invalidContent;
        if (error is _RetryDownloadException && error.refreshTicket) {
          return DownloadFailureKind.ticketExpired;
        }
        return DownloadFailureKind.unknown;
      }

      int? _contentRangeTotal(String? value) {
        if (value == null) return null;
        final match = RegExp(r'/([0-9]+)$').firstMatch(value.trim());
        return match == null ? null : int.tryParse(match.group(1)!);
      }
    }

    final class _ActiveDownload {
      _ActiveDownload({required this.ref});

      final ProviderTrackRef ref;
      final Completer<void> _done = Completer<void>();
      HttpClient? _client;
      HttpClientRequest? _request;
      StreamSubscription<List<int>>? _subscription;
      IOSink? _sink;
      Completer<void>? _transfer;
      bool stopRequested = false;
      bool _deletePartialOnStop = false;

      Future<void> get done => _done.future;

      _DownloadStoppedException get stopException =>
          _DownloadStoppedException(preservePartial: !_deletePartialOnStop);

      void throwIfStopped() {
        if (stopRequested) throw stopException;
      }

      void setClient(HttpClient client) {
        _client = client;
        if (stopRequested) client.close(force: true);
      }

      void setRequest(HttpClientRequest request) {
        _request = request;
        if (stopRequested) request.abort(stopException);
      }

      void attachTransfer({
        required StreamSubscription<List<int>> subscription,
        required IOSink sink,
        required Completer<void> transfer,
      }) {
        _subscription = subscription;
        _sink = sink;
        _transfer = transfer;
        if (stopRequested && !transfer.isCompleted) {
          transfer.completeError(stopException);
        }
      }

      void clearSink(IOSink sink) {
        if (identical(_sink, sink)) _sink = null;
      }

      void clearSubscription(StreamSubscription<List<int>> subscription) {
        if (identical(_subscription, subscription)) _subscription = null;
      }

      Future<void> requestStop({required bool preservePartial}) async {
        stopRequested = true;
        if (!preservePartial) _deletePartialOnStop = true;
        final error = stopException;
        final transfer = _transfer;
        if (transfer != null && !transfer.isCompleted) {
          transfer.completeError(error);
        }
        try {
          await _subscription?.cancel();
        } catch (_) {}
        try {
          _request?.abort(error);
        } catch (_) {}
        try {
          _client?.close(force: true);
        } catch (_) {}
        try {
          await _sink?.flush();
          await _sink?.close();
        } catch (_) {}
      }

      Future<void> releaseTransport() async {
        try {
          await _subscription?.cancel();
        } catch (_) {}
        try {
          await _sink?.flush();
          await _sink?.close();
        } catch (_) {}
        try {
          _request?.abort();
        } catch (_) {}
        try {
          _client?.close(force: true);
        } catch (_) {}
        _subscription = null;
        _sink = null;
        _request = null;
        _client = null;
        _transfer = null;
      }

      void complete() {
        if (!_done.isCompleted) _done.complete();
      }
    }

    final class _DownloadStoppedException implements Exception {
      const _DownloadStoppedException({required this.preservePartial});
      final bool preservePartial;
    }

    final class _RetryDownloadException implements Exception {
      const _RetryDownloadException({
        this.refreshTicket = false,
        this.immediate = false,
        this.message,
      });

      final bool refreshTicket;
      final bool immediate;
      final String? message;

      @override
      String toString() => message ?? 'Retryable download failure.';
    }
    ''',
)

write(
    "packages/music_domain/lib/src/playback/playback_coordinator.dart",
    r'''
    import 'dart:async';

    import 'package:provider_contract/provider_contract.dart';

    import 'playback_queue.dart';

    typedef LocalPlaybackResolver = Future<PlaybackTicket?> Function(
      SourceTrack track,
      AudioQuality requestedQuality, {
      required bool allowLowerQuality,
    });

    class PlaybackCoordinator {
      PlaybackCoordinator({
        required this.registry,
        AudioQuality defaultQuality = AudioQuality.standard,
        this.localPlaybackResolver,
      }) : _quality = defaultQuality;

      final StaticProviderRegistry registry;
      final LocalPlaybackResolver? localPlaybackResolver;
      AudioQuality _quality;

      PlaybackQueueState _queueState = PlaybackQueueState.empty();
      PlaybackTicket? _currentTicket;
      PlaybackTicket? _nextTicket;
      Object? _currentError;
      int _selectionGeneration = 0;
      int _prefetchGeneration = 0;
      Future<void>? prefetchFuture;

      PlaybackQueueState get queueState => _queueState;
      PlaybackTicket? get currentTicket => _currentTicket;
      PlaybackTicket? get nextTicket => _nextTicket;
      Object? get currentError => _currentError;
      AudioQuality get quality => _quality;

      set quality(AudioQuality newQuality) {
        if (_quality == newQuality) return;
        _quality = newQuality;
        _selectionGeneration++;
        _prefetchGeneration++;
        _currentTicket = null;
        _nextTicket = null;
      }

      void setQueue(List<SourceTrack> tracks) {
        _selectionGeneration++;
        _prefetchGeneration++;
        _queueState = _queueState.replaceWith(tracks);
        _currentTicket = null;
        _nextTicket = null;
        _currentError = null;
      }

      void restoreQueue(PlaybackQueueState state) {
        _selectionGeneration++;
        _prefetchGeneration++;
        _queueState = state;
        _currentTicket = null;
        _nextTicket = null;
        _currentError = null;
      }

      void enqueue(SourceTrack track) {
        _prefetchGeneration++;
        _queueState = _queueState.enqueue(track);
        _nextTicket = null;
        prefetchFuture = preResolveNext();
        unawaited(prefetchFuture!);
      }

      void removeAt(int index) {
        if (index < 0 || index >= _queueState.entries.length) return;
        final wasCurrent = index == _queueState.currentIndex;
        _prefetchGeneration++;
        if (wasCurrent) _selectionGeneration++;
        _queueState = _queueState.removeAt(index);
        _nextTicket = null;
        if (wasCurrent) {
          _currentTicket = null;
          _currentError = null;
        }
      }

      void updateFavoriteState(ProviderTrackRef trackRef, bool liked) {
        final index =
            _queueState.entries.indexWhere((entry) => entry.track.ref == trackRef);
        if (index == -1) return;
        final entries = [..._queueState.entries];
        final oldEntry = entries[index];
        entries[index] = PlaybackQueueEntry(
          track: oldEntry.track.copyWith(isFavorited: liked),
          queuedAt: oldEntry.queuedAt,
        );
        _queueState = PlaybackQueueState(
          entries: List.unmodifiable(entries),
          currentIndex: _queueState.currentIndex,
        );
      }

      Future<void> next() async {
        _queueState = _queueState.moveNext();
        await _resolveSelectedCurrent();
      }

      Future<void> previous() async {
        _queueState = _queueState.movePrevious();
        await _resolveSelectedCurrent();
      }

      Future<void> selectTrack(ProviderTrackRef trackRef) async {
        final index =
            _queueState.entries.indexWhere((entry) => entry.track.ref == trackRef);
        if (index == -1) {
          _currentError = StateError('Track not found in current queue');
          return;
        }
        _queueState = PlaybackQueueState(
          entries: _queueState.entries,
          currentIndex: index,
        );
        await _resolveSelectedCurrent();
      }

      Future<void> refreshCurrentTicketIfNeeded({bool force = false}) async {
        final currentEntry = _queueState.current;
        if (currentEntry == null) return;
        final ticket = _currentTicket;
        if (!force &&
            ticket != null &&
            ticket.trackRef == currentEntry.track.ref &&
            ticket.quality == _quality &&
            !ticket.isNearExpiry()) {
          return;
        }
        final generation = ++_selectionGeneration;
        final expectedRef = currentEntry.track.ref;
        try {
          final resolved = await _resolveTicketForTrack(currentEntry.track);
          if (!_isCurrent(generation, expectedRef)) return;
          _currentTicket = resolved;
          _currentError = null;
        } catch (error) {
          if (!_isCurrent(generation, expectedRef)) return;
          _currentTicket = null;
          _currentError = error;
        }
      }

      Future<PlaybackTicket> getOrResolveCurrentTicket() async {
        final currentEntry = _queueState.current;
        if (currentEntry == null) {
          throw StateError('Queue is empty or index is invalid');
        }
        await refreshCurrentTicketIfNeeded();
        final ticket = _currentTicket;
        if (ticket != null) return ticket;
        final error = _currentError;
        if (error != null) throw error;
        throw StateError('Failed to resolve current ticket');
      }

      Future<void> _resolveSelectedCurrent() async {
        final currentEntry = _queueState.current;
        final selectionGeneration = ++_selectionGeneration;
        final prefetchGeneration = ++_prefetchGeneration;
        _currentTicket = null;
        _currentError = null;
        if (currentEntry == null) {
          _nextTicket = null;
          return;
        }
        final expectedRef = currentEntry.track.ref;
        final promoted = _nextTicket;
        if (promoted != null &&
            promoted.trackRef == expectedRef &&
            !promoted.isExpired) {
          _currentTicket = promoted;
          _nextTicket = null;
        } else {
          try {
            final resolved = await _resolveTicketForTrack(currentEntry.track);
            if (!_isCurrent(selectionGeneration, expectedRef)) return;
            _currentTicket = resolved;
            _currentError = null;
          } catch (error) {
            if (!_isCurrent(selectionGeneration, expectedRef)) return;
            _currentTicket = null;
            _currentError = error;
          }
        }
        if (!_isCurrent(selectionGeneration, expectedRef)) return;
        prefetchFuture = _preResolveNext(
          prefetchGeneration,
          expectedRef,
        );
        unawaited(prefetchFuture!);
      }

      Future<void> preResolveNext() {
        final currentRef = _queueState.current?.track.ref;
        final generation = ++_prefetchGeneration;
        if (currentRef == null) {
          _nextTicket = null;
          return Future<void>.value();
        }
        return _preResolveNext(generation, currentRef);
      }

      Future<void> _preResolveNext(
        int generation,
        ProviderTrackRef currentRef,
      ) async {
        final nextIndex = _queueState.currentIndex + 1;
        if (nextIndex < 0 || nextIndex >= _queueState.entries.length) {
          if (generation == _prefetchGeneration) _nextTicket = null;
          return;
        }
        final nextTrack = _queueState.entries[nextIndex].track;
        final expectedNextRef = nextTrack.ref;
        try {
          final resolved = await _resolveTicketForTrack(nextTrack);
          if (generation != _prefetchGeneration ||
              _queueState.current?.track.ref != currentRef ||
              _queueState.currentIndex + 1 >= _queueState.entries.length ||
              _queueState.entries[_queueState.currentIndex + 1].track.ref !=
                  expectedNextRef) {
            return;
          }
          _nextTicket = resolved;
        } catch (_) {
          if (generation == _prefetchGeneration &&
              _queueState.current?.track.ref == currentRef) {
            _nextTicket = null;
          }
        }
      }

      bool _isCurrent(int generation, ProviderTrackRef ref) =>
          generation == _selectionGeneration &&
          _queueState.current?.track.ref == ref;

      Future<PlaybackTicket> _resolveTicketForTrack(SourceTrack track) async {
        final local = await localPlaybackResolver?.call(
          track,
          _quality,
          allowLowerQuality: false,
        );
        if (local != null) return local;
        try {
          return await _resolveRemoteTicketForTrack(track);
        } catch (_) {
          final fallback = await localPlaybackResolver?.call(
            track,
            _quality,
            allowLowerQuality: true,
          );
          if (fallback != null) return fallback;
          rethrow;
        }
      }

      Future<PlaybackTicket> _resolveRemoteTicketForTrack(SourceTrack track) async {
        final providerId = track.ref.providerId;
        final entry = registry.entryOf(providerId);
        if (entry == null) {
          throw ProviderException(
            providerId: providerId,
            message: 'Provider ${providerId.value} is not registered.',
          );
        }
        if (!entry.isEnabled) {
          throw ProviderDisabledException(
            providerId: providerId,
            message: 'Provider ${providerId.value} is disabled.',
          );
        }
        final provider = entry.provider;
        if (!provider.descriptor.supports(ProviderCapability.resolvePlayback)) {
          throw CapabilityUnavailableException(
            providerId: providerId,
            capability: ProviderCapability.resolvePlayback,
            message: 'Provider ${providerId.value} does not support playback.',
          );
        }
        final ticket = await provider.createPlaybackTicket(
          track: _resolutionRefForTrack(track),
          quality: _quality,
        );
        if (ticket.trackRef == track.ref) return ticket;
        return PlaybackTicket(
          mediaUri: ticket.mediaUri,
          headers: ticket.headers,
          expiresAt: ticket.expiresAt,
          trackRef: track.ref,
          quality: ticket.quality,
        );
      }

      ProviderTrackRef _resolutionRefForTrack(SourceTrack track) {
        final extraIds = <String, String>{...track.ref.extraIds};
        if (track.title.trim().isNotEmpty) {
          extraIds.putIfAbsent('searchTitle', () => track.title.trim());
        }
        if (track.artists.isNotEmpty) {
          extraIds.putIfAbsent('searchArtists', () => track.artists.join('|'));
        }
        if (track.duration.inMilliseconds > 0) {
          extraIds.putIfAbsent(
            'expectedDurationMs',
            () => track.duration.inMilliseconds.toString(),
          );
        }
        if (_stringMapEquals(extraIds, track.ref.extraIds)) return track.ref;
        return ProviderTrackRef(
          providerId: track.ref.providerId,
          trackId: track.ref.trackId,
          extraIds: extraIds,
        );
      }

      bool _stringMapEquals(
        Map<String, String> left,
        Map<String, String> right,
      ) {
        if (identical(left, right)) return true;
        if (left.length != right.length) return false;
        for (final entry in left.entries) {
          if (right[entry.key] != entry.value) return false;
        }
        return true;
      }
    }
    ''',
)

# Data-store interfaces and incremental codecs.
write(
    "packages/music_data/lib/src/melo_snapshot_store.dart",
    r'''
    import 'package:music_domain/music_domain.dart';
    import 'package:provider_contract/provider_contract.dart';

    import 'melo_data_snapshot.dart';

    abstract interface class MeloSnapshotStore {
      Future<MeloDataSnapshot?> read();
      Future<void> write(MeloDataSnapshot snapshot);
      Future<void> clear();
    }

    abstract interface class PlaybackStateStore {
      Future<PlaybackStateSnapshot?> readPlaybackState();
      Future<void> writePlaybackState({
        required PlaybackPreferencesSnapshot preferences,
        required PlaybackQueueSnapshot? queue,
      });
    }

    abstract interface class DownloadStateStore {
      Future<void> upsertDownloadTask(
        DownloadTask task, {
        required int sortIndex,
      });
      Future<void> deleteDownloadTask(ProviderTrackRef ref);
      Future<void> upsertLocalMediaItem(
        LocalMediaItem item, {
        required int sortIndex,
      });
      Future<void> deleteLocalMediaItem(ProviderTrackRef ref);
    }
    ''',
)

codec = ROOT / "packages/music_data/lib/src/melo_json_codec.dart"
codec_text = codec.read_text(encoding="utf-8")
for old, new in (
    ("_encodeDownloadTask", "encodeDownloadTask"),
    ("_decodeDownloadTask", "decodeDownloadTask"),
    ("_encodeLocalMediaItem", "encodeLocalMediaItem"),
    ("_decodeLocalMediaItem", "decodeLocalMediaItem"),
):
    codec_text = codec_text.replace(old, new)
old_codec_block = """  Map<String, Object?> encodeDownloadTask(DownloadTask task) {\n    return {\n      'track': _encodeSourceTrack(task.track),\n      'quality': task.quality.name,\n      'status': task.status.name,\n      'progress': task.progress,\n      'error': task.error,\n      'savedFilePath': task.savedFilePath,\n      'createdAt': task.createdAt.toUtc().toIso8601String(),\n    };\n  }\n\n  DownloadTask decodeDownloadTask(Map<String, Object?> json) {\n    return DownloadTask(\n      track: _decodeSourceTrack(_requiredMap(json, 'track')),\n      quality: AudioQuality.values.byName(_requiredString(json, 'quality')),\n      status: DownloadStatus.values.byName(_requiredString(json, 'status')),\n      progress: (json['progress'] as num?)?.toDouble() ?? 0,\n      error: json['error'] as String?,\n      savedFilePath: json['savedFilePath'] as String?,\n      createdAt: DateTime.parse(_requiredString(json, 'createdAt')).toUtc(),\n    );\n  }\n"""
new_codec_block = """  Map<String, Object?> encodeDownloadTask(DownloadTask task) {\n    return {\n      'track': _encodeSourceTrack(task.track),\n      'quality': task.quality.name,\n      'status': task.status.name,\n      'progress': task.progress,\n      'receivedBytes': task.receivedBytes,\n      'totalBytes': task.totalBytes,\n      'targetFilePath': task.targetFilePath,\n      'temporaryFilePath': task.temporaryFilePath,\n      'etag': task.etag,\n      'lastModified': task.lastModified,\n      'attempt': task.attempt,\n      'failureKind': task.failureKind?.name,\n      'error': task.error,\n      'savedFilePath': task.savedFilePath,\n      'createdAt': task.createdAt.toUtc().toIso8601String(),\n      'updatedAt': task.updatedAt.toUtc().toIso8601String(),\n    };\n  }\n\n  DownloadTask decodeDownloadTask(Map<String, Object?> json) {\n    final createdAt =\n        DateTime.parse(_requiredString(json, 'createdAt')).toUtc();\n    DownloadFailureKind? failureKind;\n    final failureName = json['failureKind'] as String?;\n    if (failureName != null) {\n      for (final value in DownloadFailureKind.values) {\n        if (value.name == failureName) {\n          failureKind = value;\n          break;\n        }\n      }\n    }\n    return DownloadTask(\n      track: _decodeSourceTrack(_requiredMap(json, 'track')),\n      quality: AudioQuality.values.byName(_requiredString(json, 'quality')),\n      status: DownloadStatus.values.byName(_requiredString(json, 'status')),\n      progress: (json['progress'] as num?)?.toDouble() ?? 0,\n      receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,\n      totalBytes: (json['totalBytes'] as num?)?.toInt(),\n      targetFilePath: json['targetFilePath'] as String?,\n      temporaryFilePath: json['temporaryFilePath'] as String?,\n      etag: json['etag'] as String?,\n      lastModified: json['lastModified'] as String?,\n      attempt: (json['attempt'] as num?)?.toInt() ?? 0,\n      failureKind: failureKind,\n      error: json['error'] as String?,\n      savedFilePath: json['savedFilePath'] as String?,\n      createdAt: createdAt,\n      updatedAt: json['updatedAt'] == null\n          ? createdAt\n          : DateTime.parse(json['updatedAt']! as String).toUtc(),\n    );\n  }\n"""
if old_codec_block not in codec_text:
    raise RuntimeError("Download codec block did not match")
codec_text = codec_text.replace(old_codec_block, new_codec_block, 1)
codec.write_text(codec_text, encoding="utf-8")

# Drift incremental download persistence.
replace_once(
    "packages/music_data/lib/src/drift_melo_data_store.dart",
    "final class DriftMeloDataStore implements MeloSnapshotStore, PlaybackStateStore {",
    "final class DriftMeloDataStore\n    implements MeloSnapshotStore, PlaybackStateStore, DownloadStateStore {",
)
replace_once(
    "packages/music_data/lib/src/drift_melo_data_store.dart",
    "  Future<void> _writeFavoriteProviderRows(\n",
    r'''  @override
  Future<void> upsertDownloadTask(
    DownloadTask task, {
    required int sortIndex,
  }) async {
    await database.into(database.storedDownloadTasks).insert(
          StoredDownloadTasksCompanion.insert(
            refKey: _refKey(task.track.ref),
            sortIndex: sortIndex,
            payloadJson: jsonEncode(_codec.encodeDownloadTask(task)),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<void> deleteDownloadTask(ProviderTrackRef ref) async {
    await (database.delete(database.storedDownloadTasks)
          ..where((row) => row.refKey.equals(_refKey(ref))))
        .go();
  }

  @override
  Future<void> upsertLocalMediaItem(
    LocalMediaItem item, {
    required int sortIndex,
  }) async {
    await database.into(database.storedLocalMediaItems).insert(
          StoredLocalMediaItemsCompanion.insert(
            refKey: _refKey(item.sourceRef),
            sortIndex: sortIndex,
            payloadJson: jsonEncode(_codec.encodeLocalMediaItem(item)),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<void> deleteLocalMediaItem(ProviderTrackRef ref) async {
    await (database.delete(database.storedLocalMediaItems)
          ..where((row) => row.refKey.equals(_refKey(ref))))
        .go();
  }

  Future<void> _writeFavoriteProviderRows(
''',
)

# DemoRepository: incremental download callbacks and tracked subscriptions.
replace_once(
    "app/lib/src/bootstrap/demo_repository.dart",
    """    _downloadManager = DownloadManager(\n      coordinator: downloadCoordinator,\n      onProgressOrStatusChanged: () {\n        _persistSoon();\n        notifyListeners();\n      },\n      resolveDownloadFile: _downloadFileFor,\n      embedMetadata: _embedDownloadedMetadata,\n    );\n""",
    """    _downloadManager = DownloadManager(\n      coordinator: downloadCoordinator,\n      onTaskChanged: _onDownloadTaskChanged,\n      onTaskRemoved: _onDownloadTaskRemoved,\n      onLocalItemChanged: _onLocalMediaItemChanged,\n      resolveDownloadFile: _downloadFileFor,\n      embedMetadata: _embedDownloadedMetadata,\n    );\n""",
)
replace_once(
    "app/lib/src/bootstrap/demo_repository.dart",
    "    _audioPlayer.positionStream.listen((position) {",
    "    _positionSubscription = _audioPlayer.positionStream.listen((position) {",
)
replace_once(
    "app/lib/src/bootstrap/demo_repository.dart",
    "    _audioPlayer.playerStateStream.listen((state) {",
    "    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {",
)
replace_once(
    "app/lib/src/bootstrap/demo_repository.dart",
    "    _audioPlayer.currentIndexStream.listen((index) {",
    "    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {",
)
replace_once(
    "app/lib/src/bootstrap/demo_repository.dart",
    """  final Set<StreamSubscription<double>> _cacheProgressSubscriptions = {};\n  String? _activeAudioCachePath;\n""",
    """  final Set<StreamSubscription<double>> _cacheProgressSubscriptions = {};\n  late final StreamSubscription<Duration> _positionSubscription;\n  late final StreamSubscription<PlayerState> _playerStateSubscription;\n  late final StreamSubscription<int?> _currentIndexSubscription;\n  String? _activeAudioCachePath;\n  int _nativeWindowGeneration = 0;\n  Future<void>? _closeFuture;\n""",
)
replace_once(
    "app/lib/src/bootstrap/demo_repository.dart",
    """  void _persistPlaybackStateSoon() {\n    if (_rememberQueue) {\n      _persistSoon();\n    }\n  }\n""",
    """  void _persistPlaybackStateSoon() {\n    if (!_rememberQueue) return;\n    _persistence.schedulePlaybackStateWrite(\n      PlaybackPreferencesSnapshot(\n        rememberQueue: _rememberQueue,\n        restorePlaybackState: _restorePlaybackState,\n      ),\n      _currentPlaybackQueueSnapshot(),\n    );\n  }\n""",
)

replace_region(
    "app/lib/src/bootstrap/demo_repository.dart",
    "  Future<void> queueNext({bool automatic = false}) async {",
    "  Future<void> queuePrevious() async {",
    r'''  Future<void> queueNext({bool automatic = false}) async {
    final queueState = queue;
    if (queueState.entries.isEmpty) return;

    if (automatic && _repeatMode == PlaybackRepeatMode.one) {
      await _restartCurrentTrack();
      return;
    }

    final nextRef = _nextTrackRef(queueState);
    if (nextRef == null) {
      if (automatic) {
        _playbackRequested = false;
        notifyListeners();
      }
      return;
    }

    final nativeIndex = _nativeAudioSourceRefs.indexOf(nextRef);
    if (nativeIndex >= 0) {
      await _audioPlayer.seek(Duration.zero, index: nativeIndex);
      return;
    }

    await playbackCoordinator.selectTrack(nextRef);
    _clearPendingRestorePosition();
    _playingTrackId = null;
    await _syncNativePlayback(playWhenReady: true);
    _persistPlaybackStateSoon();
    notifyListeners();
  }
''',
)

replace_region(
    "app/lib/src/bootstrap/demo_repository.dart",
    "  void addDownloadTask(SourceTrack track, {AudioQuality? quality}) {",
    "  bool canDownloadTrack(SourceTrack track) {",
    r'''  void _onDownloadTaskChanged(DownloadTask task) {
    final tasks = downloadCoordinator.allTasks;
    final index = tasks.indexWhere(
      (item) => item.track.ref.providerId == task.track.ref.providerId &&
          item.track.ref.trackId == task.track.ref.trackId,
    );
    _persistence.scheduleDownloadTaskWrite(task, index < 0 ? tasks.length : index);
    notifyListeners();
  }

  void _onDownloadTaskRemoved(ProviderTrackRef ref) {
    _persistence.scheduleDownloadTaskDelete(ref);
    notifyListeners();
  }

  void _onLocalMediaItemChanged(LocalMediaItem item) {
    final items = downloadCoordinator.localItems;
    final index = items.indexWhere(
      (candidate) =>
          candidate.sourceRef.providerId == item.sourceRef.providerId &&
          candidate.sourceRef.trackId == item.sourceRef.trackId,
    );
    _persistence.scheduleLocalMediaWrite(item, index < 0 ? items.length : index);
    notifyListeners();
  }

  void addDownloadTask(SourceTrack track, {AudioQuality? quality}) {
    _rememberTrack(track);
    downloadCoordinator.addTask(track, quality: quality ?? _downloadQuality);
    final task = downloadCoordinator.getTask(track.ref);
    if (task != null) _onDownloadTaskChanged(task);
  }
''',
)
replace_once(
    "app/lib/src/bootstrap/demo_repository.dart",
    """      downloadCoordinator.addTask(track, quality: requestedQuality);\n      _persistSoon();\n      notifyListeners();\n""",
    """      downloadCoordinator.addTask(track, quality: requestedQuality);\n      final added = downloadCoordinator.getTask(track.ref);\n      if (added != null) _onDownloadTaskChanged(added);\n""",
)
replace_region(
    "app/lib/src/bootstrap/demo_repository.dart",
    "  Future<void> startDownload(ProviderTrackRef ref) async {",
    "  void simulateDownloadProgress(ProviderTrackRef ref) {",
    r'''  Future<void> startDownload(ProviderTrackRef ref) async {
    await _downloadManager.startDownload(ref);
  }

  void pauseDownload(ProviderTrackRef ref) {
    unawaited(_downloadManager.pauseDownload(ref));
  }

  Future<void> resumeDownload(ProviderTrackRef ref) async {
    await _downloadManager.startDownload(ref);
  }

  void cancelDownload(ProviderTrackRef ref) {
    unawaited(_downloadManager.cancelDownload(ref));
  }

  void removeLocalMedia(ProviderTrackRef ref) {
    final localItem = downloadCoordinator.getLocalItem(ref);
    downloadCoordinator.removeLocalItem(ref);
    _persistence.scheduleLocalMediaDelete(ref);
    final task = downloadCoordinator.getTask(ref);
    if (task != null) _onDownloadTaskChanged(task);
    final filePath = localItem?.filePath;
    if (filePath != null && !filePath.startsWith('local://')) {
      unawaited(File(filePath).delete().catchError((Object _) => File(filePath)));
    }
    notifyListeners();
  }

  Future<void> redownloadLocalMedia(
    ProviderTrackRef ref, {
    AudioQuality? quality,
  }) async {
    final track = sourceTrackByRef(ref);
    if (track == null) {
      removeLocalMedia(ref);
      return;
    }
    removeLocalMedia(ref);
    downloadCoordinator.addTask(track, quality: quality ?? _downloadQuality);
    final task = downloadCoordinator.getTask(ref);
    if (task != null) _onDownloadTaskChanged(task);
    await startDownload(ref);
  }
''',
)

replace_once(
    "app/lib/src/bootstrap/demo_repository.dart",
    "  void _setEffectivePlaybackSource(SourceTrack track, PlaybackTicket ticket) {",
    """  String _playbackKey(ProviderTrackRef ref) =>\n      '${ref.providerId.value}:${ref.trackId}';\n\n  void _setEffectivePlaybackSource(SourceTrack track, PlaybackTicket ticket) {""",
)

replace_region(
    "app/lib/src/bootstrap/demo_repository.dart",
    "  Future<void> _syncNativePlayback({",
    "  Future<bool> _tryRecoverPlayback(",
    r'''  Future<void> _syncNativePlayback({
    required bool playWhenReady,
    bool forceReload = false,
    Duration? initialPosition,
  }) async {
    final queueState = playbackCoordinator.queueState;
    final current = queueState.current?.track;
    final currentTicket = playbackCoordinator.currentTicket;
    if (current == null || currentTicket == null) {
      final error = playbackCoordinator.currentError;
      if (current != null && error != null) {
        _setPlaybackIssue(
          track: current,
          title: '播放链接解析失败',
          message: _playbackErrorMessage(error),
        );
        _playbackRequested = false;
      }
      return;
    }

    _setEffectivePlaybackSource(current, currentTicket);
    final playbackKey = _playbackKey(current.ref);
    if (!forceReload &&
        _playingTrackId == playbackKey &&
        _audioPlayer.playing) {
      return;
    }
    if (!playWhenReady) return;

    final generation = ++_nativeWindowGeneration;
    _playingTrackId = playbackKey;
    _playbackRequested = true;
    try {
      if (!_isSupportedPlaybackUri(currentTicket.mediaUri)) {
        throw FormatException(
          'Unsupported playback URI scheme: ${currentTicket.mediaUri.scheme}',
          currentTicket.mediaUri.toString(),
        );
      }
      debugPrint('AUDIO: playing "${current.title}"');
      await _audioPlayer.stop();
      await audioCacheManager?.releaseInUse(_activeAudioCachePath);
      _activeAudioCachePath = null;
      await _syncAudioLoopMode();
      final currentSource = await _nativeSourceFor(
        current,
        currentTicket,
        cacheWhilePlaying: true,
      );
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: [currentSource.toAudioSource()],
      );
      _nativeAudioSourceRefs = [current.ref];
      _updatingNativeAudioSource = true;
      final startPosition = initialPosition ?? _pendingRestorePosition;
      try {
        await _audioPlayer.setAudioSource(
          playlist,
          initialIndex: 0,
          initialPosition: startPosition,
        );
      } finally {
        _updatingNativeAudioSource = false;
      }
      if (startPosition != null && startPosition > Duration.zero) {
        _lastKnownPlaybackPosition = startPosition;
      }
      _pendingRestorePosition = null;
      _playbackIssue = null;
      await notificationPermissionBridge.requestPostNotifications();
      _startAudioPlayer();
      unawaited(_appendNextToNativeWindow(generation, current.ref));
    } catch (error) {
      _updatingNativeAudioSource = false;
      debugPrint('Audio Error: $error');
      if (await _tryRecoverPlayback(current, currentTicket, initialPosition)) {
        return;
      }
      _playingTrackId = null;
      _playbackRequested = false;
      _setPlaybackIssue(
        track: current,
        title: '播放启动失败',
        message: _playbackErrorMessage(error),
      );
    }
  }
''',
)

# Stable playback identity in recovery.
demo_path = ROOT / "app/lib/src/bootstrap/demo_repository.dart"
demo_text = demo_path.read_text(encoding="utf-8")
demo_text = demo_text.replace(
    "_playingTrackId = track.ref.trackId;",
    "_playingTrackId = _playbackKey(track.ref);",
)
demo_text = demo_text.replace(
    "_playingTrackId = current.ref.trackId;",
    "_playingTrackId = _playbackKey(current.ref);",
)
demo_path.write_text(demo_text, encoding="utf-8")

replace_region(
    "app/lib/src/bootstrap/demo_repository.dart",
    "  Future<void> _handleNativeAudioIndexChange(ProviderTrackRef ref) async {",
    "  Future<_NativePlaybackSource> _nativeSourceFor(",
    r'''  Future<void> _handleNativeAudioIndexChange(ProviderTrackRef ref) async {
    _handlingNativeAudioIndexChange = true;
    final generation = ++_nativeWindowGeneration;
    try {
      await playbackCoordinator.selectTrack(ref);
      _clearPendingRestorePosition();
      final queueState = queue;
      final current = queueState.current?.track;
      final currentTicket = playbackCoordinator.currentTicket;
      if (current == null || currentTicket == null) return;

      _setEffectivePlaybackSource(current, currentTicket);
      _playingTrackId = _playbackKey(current.ref);
      final source = _audioPlayer.audioSource;
      final nativeIndex = _nativeAudioSourceRefs.indexOf(ref);
      if (source is! ConcatenatingAudioSource || nativeIndex < 0) {
        await _syncNativePlayback(playWhenReady: true, forceReload: true);
        return;
      }

      _updatingNativeAudioSource = true;
      try {
        for (var i = 0; i < nativeIndex; i++) {
          await source.removeAt(0);
          _nativeAudioSourceRefs.removeAt(0);
        }
      } finally {
        _updatingNativeAudioSource = false;
      }
      unawaited(_appendNextToNativeWindow(generation, current.ref));
      _persistPlaybackStateSoon();
      notifyListeners();
    } finally {
      _handlingNativeAudioIndexChange = false;
    }
  }

  Future<void> _appendNextToNativeWindow(
    int generation,
    ProviderTrackRef currentRef,
  ) async {
    if (_repeatMode == PlaybackRepeatMode.one) return;
    final prefetched = playbackCoordinator.prefetchFuture;
    if (prefetched != null) await prefetched;
    if (generation != _nativeWindowGeneration ||
        queue.current?.track.ref != currentRef) {
      return;
    }
    final queueState = queue;
    final next = _nextTrackForNotification(queueState);
    if (next == null || _nativeAudioSourceRefs.contains(next.ref)) return;
    final cachedTicket = playbackCoordinator.nextTicket;
    final ticket = cachedTicket != null &&
            cachedTicket.trackRef == next.ref &&
            !cachedTicket.isExpired
        ? cachedTicket
        : await _resolvePlaybackTicketForTrack(next);
    if (ticket == null ||
        generation != _nativeWindowGeneration ||
        queue.current?.track.ref != currentRef) {
      return;
    }
    final source = _audioPlayer.audioSource;
    if (source is! ConcatenatingAudioSource) return;
    final nativeSource = await _nativeSourceFor(next, ticket);
    if (generation != _nativeWindowGeneration ||
        queue.current?.track.ref != currentRef) {
      return;
    }
    _updatingNativeAudioSource = true;
    try {
      await source.add(nativeSource.toAudioSource());
      _nativeAudioSourceRefs = [..._nativeAudioSourceRefs, next.ref];
    } finally {
      _updatingNativeAudioSource = false;
    }
  }

  Future<_NativePlaybackSource> _nativeSourceFor(
''',
)

replace_region(
    "app/lib/src/bootstrap/demo_repository.dart",
    "  @override\n  void dispose() {",
    "  void _persistSoon() {",
    r'''  Future<void> close() {
    return _closeFuture ??= _closeInternal();
  }

  Future<void> _closeInternal() async {
    _nativeWindowGeneration++;
    await _downloadManager.close();
    await _positionSubscription.cancel();
    await _playerStateSubscription.cancel();
    await _currentIndexSubscription.cancel();
    final cacheSubscriptions =
        _cacheProgressSubscriptions.toList(growable: false);
    _cacheProgressSubscriptions.clear();
    await Future.wait(cacheSubscriptions.map((item) => item.cancel()));
    await audioCacheManager?.releaseInUse(_activeAudioCachePath);
    _activeAudioCachePath = null;
    await _persistence.close();
    await _audioPlayer.dispose();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
''',
)

# Bootstrap closes repository before the database.
replace_once(
    "app/lib/src/bootstrap/app_bootstrap.dart",
    """  return AppBootstrap(\n    repository: repository,\n    close: managedStore.close,\n  );\n""",
    """  var closed = false;\n  return AppBootstrap(\n    repository: repository,\n    close: () async {\n      if (closed) return;\n      closed = true;\n      await repository.close();\n      await managedStore.close();\n    },\n  );\n""",
)

# Add a race regression test to the domain suite.
path = ROOT / "packages/music_domain/test/music_domain_test.dart"
text = path.read_text(encoding="utf-8")
insert = r'''

  test('PlaybackCoordinator ignores stale background prefetch results', () async {
    final providerId = ProviderId('stale_prefetch');
    final first = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'first'),
      title: 'First',
      artists: const ['Tester'],
      duration: const Duration(minutes: 3),
      isPlayable: true,
    );
    final slowNext = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'slow'),
      title: 'Slow',
      artists: const ['Tester'],
      duration: const Duration(minutes: 3),
      isPlayable: true,
    );
    final replacement = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'replacement'),
      title: 'Replacement',
      artists: const ['Tester'],
      duration: const Duration(minutes: 3),
      isPlayable: true,
    );
    final provider = _DelayedPlaybackProvider(
      providerId: providerId,
      delays: {
        'slow': const Duration(milliseconds: 80),
        'replacement': const Duration(milliseconds: 5),
      },
    );
    final coordinator = PlaybackCoordinator(
      registry: StaticProviderRegistry([provider]),
    );

    coordinator.setQueue([first, slowNext]);
    await coordinator.selectTrack(first.ref);
    coordinator.setQueue([first, replacement]);
    await coordinator.selectTrack(first.ref);
    await coordinator.prefetchFuture;
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(coordinator.nextTicket?.trackRef, replacement.ref);
  });
'''
idx = text.rfind("\n}")
if idx < 0:
    raise RuntimeError("Unable to append domain test")
text = text[:idx] + insert + text[idx:]
# Append a noSuchMethod-backed provider helper outside main if not already present.
helper = r'''

final class _DelayedPlaybackProvider implements MusicProvider {
  _DelayedPlaybackProvider({
    required ProviderId providerId,
    required this.delays,
  }) : descriptor = ProviderDescriptor(
          id: providerId,
          displayName: 'Delayed playback',
          capabilities: const {ProviderCapability.resolvePlayback},
        );

  @override
  final ProviderDescriptor descriptor;
  final Map<String, Duration> delays;

  @override
  bool get isAuthenticated => true;

  @override
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    await Future<void>.delayed(delays[track.trackId] ?? Duration.zero);
    return PlaybackTicket(
      mediaUri: Uri.parse('https://example.test/${track.trackId}.mp3'),
      headers: const {},
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      trackRef: track,
      quality: quality,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
'''
text += helper
path.write_text(text, encoding="utf-8")

print("Core hardening patches applied.")
