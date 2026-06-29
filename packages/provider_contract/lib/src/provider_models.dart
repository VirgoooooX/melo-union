import 'provider_id.dart';

enum AudioQuality {
  low,
  standard,
  high,
  lossless;
}

final class ProviderAccountProfile {
  const ProviderAccountProfile({
    required this.accountId,
    required this.displayName,
    this.avatarUrl,
  });

  final String accountId;
  final String displayName;
  final Uri? avatarUrl;
}

final class ProviderTrackRef {
  ProviderTrackRef({
    required this.providerId,
    required this.trackId,
    Map<String, String> extraIds = const {},
  }) : extraIds = Map.unmodifiable(extraIds);

  final ProviderId providerId;
  final String trackId;
  final Map<String, String> extraIds;

  @override
  bool operator ==(Object other) {
    return other is ProviderTrackRef &&
        other.providerId == providerId &&
        other.trackId == trackId &&
        _stringMapEquals(other.extraIds, extraIds);
  }

  @override
  int get hashCode =>
      Object.hash(providerId, trackId, _sortedStringMapHash(extraIds));
}

final class SourceTrack {
  const SourceTrack({
    required this.ref,
    required this.title,
    required this.artists,
    required this.duration,
    required this.isFavorited,
    this.album,
    this.isrc,
    this.artwork,
    this.isPlayable = true,
    this.isDownloadable = false,
  });

  final ProviderTrackRef ref;
  final String title;
  final List<String> artists;
  final Duration duration;
  final bool isFavorited;
  final String? album;
  final String? isrc;
  final Uri? artwork;
  final bool isPlayable;
  final bool isDownloadable;

  SourceTrack copyWith({
    ProviderTrackRef? ref,
    String? title,
    List<String>? artists,
    Duration? duration,
    bool? isFavorited,
    String? album,
    String? isrc,
    Uri? artwork,
    bool? isPlayable,
    bool? isDownloadable,
  }) {
    return SourceTrack(
      ref: ref ?? this.ref,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      duration: duration ?? this.duration,
      isFavorited: isFavorited ?? this.isFavorited,
      album: album ?? this.album,
      isrc: isrc ?? this.isrc,
      artwork: artwork ?? this.artwork,
      isPlayable: isPlayable ?? this.isPlayable,
      isDownloadable: isDownloadable ?? this.isDownloadable,
    );
  }
}

final class FavoriteSnapshot {
  FavoriteSnapshot({
    required this.providerId,
    required List<SourceTrack> tracks,
    DateTime? fetchedAt,
    this.partialFailureReason,
  })  : tracks = List.unmodifiable(tracks),
        fetchedAt = fetchedAt ?? DateTime.now().toUtc();

  final ProviderId providerId;
  final List<SourceTrack> tracks;
  final DateTime fetchedAt;
  final String? partialFailureReason;
}

bool _stringMapEquals(Map<String, String> left, Map<String, String> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _sortedStringMapHash(Map<String, String> values) {
  final keys = values.keys.toList(growable: false)..sort();
  return Object.hashAll(keys.map((key) => Object.hash(key, values[key])));
}

final class PlaybackTicket {
  PlaybackTicket({
    required this.mediaUri,
    required Map<String, String> headers,
    required this.expiresAt,
    required this.trackRef,
    required this.quality,
  }) : headers = Map.unmodifiable(headers);

  final Uri mediaUri;
  final Map<String, String> headers;
  final DateTime expiresAt;
  final ProviderTrackRef trackRef;
  final AudioQuality quality;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  bool isNearExpiry([Duration buffer = const Duration(minutes: 5)]) {
    return DateTime.now().toUtc().add(buffer).isAfter(expiresAt.toUtc());
  }
}

final class DownloadTicket {
  DownloadTicket({
    required this.mediaUri,
    required Map<String, String> headers,
    required this.expiresAt,
    required this.trackRef,
    required this.quality,
    this.fileExtension,
    this.bytes,
  }) : headers = Map.unmodifiable(headers);

  final Uri mediaUri;
  final Map<String, String> headers;
  final DateTime expiresAt;
  final ProviderTrackRef trackRef;
  final AudioQuality quality;
  final String? fileExtension;
  final int? bytes;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  bool isNearExpiry([Duration buffer = const Duration(minutes: 5)]) {
    return DateTime.now().toUtc().add(buffer).isAfter(expiresAt.toUtc());
  }
}
