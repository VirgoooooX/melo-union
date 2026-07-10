import 'dart:async';
import 'dart:io';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

final class DownloadManager {
  DownloadManager({
    required this.coordinator,
    required this.onProgressOrStatusChanged,
    required this.resolveDownloadFile,
    required this.embedMetadata,
  });

  final DownloadCoordinator coordinator;
  final void Function() onProgressOrStatusChanged;
  final Future<File> Function(SourceTrack track, DownloadTicket ticket) resolveDownloadFile;
  final Future<void> Function(File file, SourceTrack track, DownloadTicket ticket) embedMetadata;

  final Map<ProviderTrackRef, _ActiveDownload> _activeDownloads = {};

  Future<void> startDownload(ProviderTrackRef ref) async {
    if (_activeDownloads.containsKey(ref)) return;

    await coordinator.startTask(ref);
    onProgressOrStatusChanged();

    final task = coordinator.getTask(ref);
    final ticket = task?.ticket;
    if (task == null ||
        task.status != DownloadStatus.downloading ||
        ticket == null) {
      return;
    }

    final active = _ActiveDownload();
    _activeDownloads[ref] = active;

    unawaited(_materializeDownload(ref, active, task, ticket));
  }

  void pauseDownload(ProviderTrackRef ref) {
    coordinator.pauseTask(ref);
    final active = _activeDownloads.remove(ref);
    active?.cancel();
    onProgressOrStatusChanged();
  }

  void cancelDownload(ProviderTrackRef ref) {
    coordinator.cancelTask(ref);
    coordinator.removeTask(ref);
    final active = _activeDownloads.remove(ref);
    active?.cancel();
    onProgressOrStatusChanged();
  }

  Future<void> _materializeDownload(
    ProviderTrackRef ref,
    _ActiveDownload active,
    DownloadTask task,
    DownloadTicket ticket,
  ) async {
    final uri = ticket.mediaUri;
    if (!uri.isScheme('http') && !uri.isScheme('https')) {
      coordinator.failTask(
        ref,
        'Unsupported download URI scheme: ${uri.scheme}',
      );
      _activeDownloads.remove(ref);
      onProgressOrStatusChanged();
      return;
    }

    File? tempFile;
    IOSink? sink;
    final client = HttpClient();
    active.client = client;

    try {
      final target = await resolveDownloadFile(task.track, ticket);
      await target.parent.create(recursive: true);
      tempFile = File('${target.path}.part');
      
      final request = await client.getUrl(uri);
      active.request = request;
      ticket.headers.forEach(request.headers.add);
      
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<List<int>>(<int>[]);
        throw HttpException(
          'Download failed with HTTP ${response.statusCode}.',
          uri: uri,
        );
      }

      sink = tempFile.openWrite();
      active.sink = sink;

      var received = 0;
      final total = response.contentLength;

      final completer = Completer<void>();
      late StreamSubscription<List<int>> subscription;

      subscription = response.listen(
        (chunk) {
          if (active.isCancelled) {
            subscription.cancel();
            completer.completeError(const _DownloadCancelledException());
            return;
          }
          try {
            sink!.add(chunk);
            received += chunk.length;
            if (total > 0) {
              coordinator.updateProgress(ref, received / total);
              onProgressOrStatusChanged();
            }
          } catch (e) {
            subscription.cancel();
            completer.completeError(e);
          }
        },
        onError: (Object error) {
          completer.completeError(error);
        },
        onDone: () {
          completer.complete();
        },
        cancelOnError: true,
      );

      active.subscription = subscription;

      await completer.future;

      await sink.close();
      sink = null;

      if (active.isCancelled) {
        throw const _DownloadCancelledException();
      }

      if (await target.exists()) {
        await target.delete();
      }
      await tempFile.rename(target.path);
      await embedMetadata(target, task.track, ticket);
      final fileSize = await target.length();
      
      if (active.isCancelled) {
        if (await target.exists()) {
          await target.delete();
        }
        throw const _DownloadCancelledException();
      }

      coordinator.completeTask(
        ref: ref,
        filePath: target.path,
        fileSize: fileSize,
      );
      onProgressOrStatusChanged();
    } on _DownloadCancelledException {
      try {
        await sink?.close();
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    } catch (error) {
      if (!active.isCancelled) {
        coordinator.failTask(ref, error);
        onProgressOrStatusChanged();
        try {
          await sink?.close();
          if (tempFile != null && await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
      }
    } finally {
      client.close(force: true);
      _activeDownloads.remove(ref);
    }
  }

  void close() {
    final downloads = List<MapEntry<ProviderTrackRef, _ActiveDownload>>.from(_activeDownloads.entries);
    for (final entry in downloads) {
      coordinator.pauseTask(entry.key);
      entry.value.cancel();
    }
    _activeDownloads.clear();
  }
}

final class _ActiveDownload {
  HttpClient? client;
  HttpClientRequest? request;
  StreamSubscription<List<int>>? subscription;
  IOSink? sink;
  bool isCancelled = false;

  void cancel() {
    isCancelled = true;
    subscription?.cancel();
    try {
      request?.abort();
    } catch (_) {}
    try {
      client?.close(force: true);
    } catch (_) {}
    try {
      sink?.close();
    } catch (_) {}
  }
}

class _DownloadCancelledException implements Exception {
  const _DownloadCancelledException();
}
