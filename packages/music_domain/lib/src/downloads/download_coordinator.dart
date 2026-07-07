import 'dart:async';
import 'package:provider_contract/provider_contract.dart';
import 'download_models.dart';

class DownloadCoordinator {
  DownloadCoordinator({
    required this.registry,
    List<DownloadTask> seedTasks = const [],
    List<LocalMediaItem> seedLocalItems = const [],
  })  : _tasks = {
          for (final task in seedTasks) task.track.ref: task,
        },
        _localLibrary = {
          for (final item in seedLocalItems) item.sourceRef: item,
        };

  final StaticProviderRegistry registry;
  final Map<ProviderTrackRef, DownloadTask> _tasks;
  final Map<ProviderTrackRef, LocalMediaItem> _localLibrary;

  List<DownloadTask> get allTasks => _tasks.values.toList();
  List<LocalMediaItem> get localItems => _localLibrary.values.toList();

  void replaceState({
    List<DownloadTask> tasks = const [],
    List<LocalMediaItem> localItems = const [],
  }) {
    _tasks
      ..clear()
      ..addEntries(tasks.map((task) => MapEntry(task.track.ref, task)));
    _localLibrary
      ..clear()
      ..addEntries(localItems.map((item) => MapEntry(item.sourceRef, item)));
  }

  bool isAvailableLocally(ProviderTrackRef ref) =>
      _localLibrary.containsKey(ref);
  LocalMediaItem? getLocalItem(ProviderTrackRef ref) => _localLibrary[ref];

  void addTask(SourceTrack track,
      {AudioQuality quality = AudioQuality.standard}) {
    if (_localLibrary.containsKey(track.ref)) return;
    _tasks[track.ref] = DownloadTask(
      track: track,
      quality: quality,
      status: DownloadStatus.queued,
    );
  }

  DownloadTask? getTask(ProviderTrackRef ref) => _tasks[ref];

  Future<void> startTask(ProviderTrackRef ref) async {
    final task = _tasks[ref];
    if (task == null) return;

    _updateTask(task.copyWith(
      status: DownloadStatus.resolving,
      error: null,
      ticket: null, // Clear ticket on start to request fresh
    ));

    try {
      final ticket = await _resolveTicket(ref, task.quality);
      _updateTask(_tasks[ref]!.copyWith(
        status: DownloadStatus.downloading,
        ticket: ticket,
      ));
    } catch (e) {
      _updateTask(_tasks[ref]!.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
      ));
    }
  }

  void updateProgress(ProviderTrackRef ref, double progress) {
    final task = _tasks[ref];
    if (task == null || task.status != DownloadStatus.downloading) return;
    _updateTask(task.copyWith(
      progress: progress.clamp(0.0, 0.99).toDouble(),
    ));
  }

  void completeTask({
    required ProviderTrackRef ref,
    required String filePath,
    required int fileSize,
  }) {
    final task = _tasks[ref];
    if (task == null) return;
    final item = LocalMediaItem(
      sourceRef: ref,
      title: task.track.title,
      artists: task.track.artists,
      duration: task.track.duration,
      filePath: filePath,
      fileSize: fileSize,
      downloadedAt: DateTime.now().toUtc(),
    );
    _localLibrary[ref] = item;
    _updateTask(task.copyWith(
      status: DownloadStatus.completed,
      progress: 1.0,
      savedFilePath: filePath,
      ticket: null,
      error: null,
    ));
  }

  void failTask(ProviderTrackRef ref, Object error) {
    final task = _tasks[ref];
    if (task == null) return;
    _updateTask(task.copyWith(
      status: DownloadStatus.failed,
      error: error.toString(),
      ticket: null,
    ));
  }

  void pauseTask(ProviderTrackRef ref) {
    final task = _tasks[ref];
    if (task == null) return;
    if (task.status == DownloadStatus.downloading ||
        task.status == DownloadStatus.resolving ||
        task.status == DownloadStatus.queued) {
      _updateTask(task.copyWith(
        status: DownloadStatus.paused,
        ticket: null, // Clear ticket when paused - do not persist
      ));
    }
  }

  Future<void> resumeTask(ProviderTrackRef ref) async {
    // Resuming is starting again with a fresh ticket resolution
    await startTask(ref);
  }

  void cancelTask(ProviderTrackRef ref) {
    final task = _tasks[ref];
    if (task == null) return;
    _updateTask(task.copyWith(
      status: DownloadStatus.cancelled,
      ticket: null,
      progress: 0.0,
    ));
  }

  void removeTask(ProviderTrackRef ref) {
    _tasks.remove(ref);
  }

  void removeLocalItem(ProviderTrackRef ref) {
    _localLibrary.remove(ref);
    final task = _tasks[ref];
    if (task != null) {
      _updateTask(task.copyWith(
        status: DownloadStatus.cancelled,
        progress: 0.0,
        ticket: null,
        savedFilePath: null,
      ));
    }
  }

  void simulateProgressStep(ProviderTrackRef ref) {
    final task = _tasks[ref];
    if (task == null || task.status != DownloadStatus.downloading) return;

    final ticket = task.ticket;
    if (ticket == null || ticket.isExpired) {
      _updateTask(task.copyWith(
        status: DownloadStatus.failed,
        error: 'Download ticket has expired.',
        ticket: null,
      ));
      return;
    }

    final nextProgress = (task.progress + 0.2).clamp(0.0, 1.0);
    if (nextProgress >= 1.0) {
      final filePath =
          'local://downloads/${ref.providerId.value}/${ref.trackId}.${ticket.fileExtension ?? 'mp3'}';
      final item = LocalMediaItem(
        sourceRef: ref,
        title: task.track.title,
        artists: task.track.artists,
        duration: task.track.duration,
        filePath: filePath,
        fileSize: ticket.bytes ?? (1024 * 1024 * 5),
        downloadedAt: DateTime.now().toUtc(),
      );
      _localLibrary[ref] = item;
      _updateTask(task.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        savedFilePath: filePath,
        ticket: null, // Clear ticket on completion
      ));
    } else {
      _updateTask(task.copyWith(
        progress: nextProgress,
      ));
    }
  }

  Future<void> runSimulationToCompletion(ProviderTrackRef ref) async {
    final task = _tasks[ref];
    if (task == null) return;
    if (task.status == DownloadStatus.queued ||
        task.status == DownloadStatus.paused) {
      await startTask(ref);
    }
    while (_tasks[ref]?.status == DownloadStatus.downloading) {
      simulateProgressStep(ref);
    }
  }

  void _updateTask(DownloadTask task) {
    _tasks[task.track.ref] = task;
  }

  Future<DownloadTicket> _resolveTicket(
      ProviderTrackRef ref, AudioQuality quality) async {
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
    return await provider.createDownloadTicket(track: ref, quality: quality);
  }
}
