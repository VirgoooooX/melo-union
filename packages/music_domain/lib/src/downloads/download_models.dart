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

final class DownloadTask {
  DownloadTask({
    required this.track,
    required this.quality,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.error,
    this.ticket,
    this.savedFilePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  final SourceTrack track;
  final AudioQuality quality;
  final DownloadStatus status;
  final double progress;
  final String? error;
  final DownloadTicket? ticket;
  final String? savedFilePath;
  final DateTime createdAt;

  DownloadTask copyWith({
    DownloadStatus? status,
    double? progress,
    Object? error = const Object(),
    Object? ticket = const Object(),
    Object? savedFilePath = const Object(),
  }) {
    return DownloadTask(
      track: track,
      quality: quality,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: identical(error, const Object()) ? this.error : (error as String?),
      ticket: identical(ticket, const Object())
          ? this.ticket
          : (ticket as DownloadTicket?),
      savedFilePath: identical(savedFilePath, const Object())
          ? this.savedFilePath
          : (savedFilePath as String?),
      createdAt: createdAt,
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
  });

  final ProviderTrackRef sourceRef;
  final String title;
  final List<String> artists;
  final Duration duration;
  final String filePath;
  final int fileSize;
  final DateTime downloadedAt;
}
