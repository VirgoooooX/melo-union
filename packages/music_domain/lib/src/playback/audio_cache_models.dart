import 'package:provider_contract/provider_contract.dart';

/// Device-local policy for automatically cached remote audio.
final class AudioCachePolicy {
  const AudioCachePolicy({
    required this.enabled,
    required this.wifiOnly,
    required this.maxBytes,
  });

  final bool enabled;
  final bool wifiOnly;
  final int maxBytes;

  AudioCachePolicy copyWith({bool? enabled, bool? wifiOnly, int? maxBytes}) {
    return AudioCachePolicy(
      enabled: enabled ?? this.enabled,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      maxBytes: maxBytes ?? this.maxBytes,
    );
  }
}

/// A complete, disposable local copy of a streamed track.
final class AudioCacheEntry {
  const AudioCacheEntry({
    required this.providerId,
    required this.trackId,
    required this.quality,
    required this.filePath,
    required this.fileSize,
    required this.completedAt,
    required this.lastAccessedAt,
  });

  final ProviderId providerId;
  final String trackId;
  final AudioQuality quality;
  final String filePath;
  final int fileSize;
  final DateTime completedAt;
  final DateTime lastAccessedAt;

  String get identityKey => '${providerId.value}:$trackId';

  AudioCacheEntry copyWith({DateTime? lastAccessedAt}) {
    return AudioCacheEntry(
      providerId: providerId,
      trackId: trackId,
      quality: quality,
      filePath: filePath,
      fileSize: fileSize,
      completedAt: completedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}

enum PlaybackSourceKind { network, download, cache, fallback }
