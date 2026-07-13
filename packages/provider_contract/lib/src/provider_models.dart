import 'provider_id.dart';

enum AudioQuality {
  low,
  standard,
  high,
  lossless;
}

extension AudioQualityComparison on AudioQuality {
  bool meetsOrExceeds(AudioQuality requested) => index >= requested.index;
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

final class ProviderArtistRef {
  const ProviderArtistRef({
    required this.providerId,
    required this.artistId,
    required this.name,
  });

  final ProviderId providerId;
  final String artistId;
  final String name;
}

final class SourceTrack {
  const SourceTrack({
    required this.ref,
    required this.title,
    required this.artists,
    required this.duration,
    required this.isFavorited,
    this.album,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.isrc,
    this.artwork,
    this.isPlayable = true,
    this.isDownloadable = false,
    this.likedAt,
    this.likedAtSource,
    this.likedAtPrecision,
    this.artistRefs = const [],
  });

  final ProviderTrackRef ref;
  final String title;
  final List<String> artists;
  final Duration duration;
  final bool isFavorited;
  final String? album;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final String? isrc;
  final Uri? artwork;
  final bool isPlayable;
  final bool isDownloadable;

  /// UTC timestamp of when this track was liked (null for imported unknowns).
  final DateTime? likedAt;

  /// Origin of the liked-at value:
  ///   'app_action' | 'sync_detected' | 'qq_import' | 'kugou_import' |
  ///   'kugou_raw' | 'netease_raw' | 'unknown' | null
  final String? likedAtSource;

  /// Precision of the liked-at timestamp:
  ///   'exact' | 'approximate' | 'unknown' | null
  final String? likedAtPrecision;
  final List<ProviderArtistRef> artistRefs;

  SourceTrack copyWith({
    ProviderTrackRef? ref,
    String? title,
    List<String>? artists,
    Duration? duration,
    bool? isFavorited,
    String? album,
    int? year,
    int? trackNumber,
    int? discNumber,
    String? isrc,
    Uri? artwork,
    bool? isPlayable,
    bool? isDownloadable,
    DateTime? likedAt,
    String? likedAtSource,
    String? likedAtPrecision,
    bool clearLikedAt = false,
    List<ProviderArtistRef>? artistRefs,
  }) {
    return SourceTrack(
      ref: ref ?? this.ref,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      duration: duration ?? this.duration,
      isFavorited: isFavorited ?? this.isFavorited,
      album: album ?? this.album,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      isrc: isrc ?? this.isrc,
      artwork: artwork ?? this.artwork,
      isPlayable: isPlayable ?? this.isPlayable,
      isDownloadable: isDownloadable ?? this.isDownloadable,
      likedAt: clearLikedAt ? null : likedAt ?? this.likedAt,
      likedAtSource: clearLikedAt ? null : likedAtSource ?? this.likedAtSource,
      likedAtPrecision:
          clearLikedAt ? null : likedAtPrecision ?? this.likedAtPrecision,
      artistRefs: artistRefs ?? this.artistRefs,
    );
  }
}

final class ArtistMatchTrack {
  const ArtistMatchTrack(
      {required this.title, required this.duration, this.album});
  final String title;
  final String? album;
  final Duration duration;
}

final class ProviderArtistCandidate {
  const ProviderArtistCandidate({
    required this.artist,
    this.aliases = const [],
    this.avatar,
    this.background,
    this.description,
    this.providerScore = 0,
  });
  final ProviderArtistRef artist;
  final List<String> aliases;
  final Uri? avatar;
  final Uri? background;
  final String? description;
  final double providerScore;
}

final class ProviderArtistMetadata {
  const ProviderArtistMetadata({
    required this.artist,
    this.aliases = const [],
    this.avatar,
    this.background,
    this.description,
  });
  final ProviderArtistRef artist;
  final List<String> aliases;
  final Uri? avatar;
  final Uri? background;
  final String? description;
}

abstract interface class ArtistMetadataProvider {
  Future<List<ProviderArtistCandidate>> searchArtistMetadata({
    required String artistName,
    required List<ArtistMatchTrack> samples,
    int limit = 5,
  });

  Future<ProviderArtistMetadata?> getArtistMetadata(String artistId);
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

final class ProviderPlaylist {
  ProviderPlaylist({
    required this.providerId,
    required this.playlistId,
    required this.name,
    this.description,
    this.creatorName,
    this.cover,
    this.trackCount = 0,
    this.playCount,
  });

  final ProviderId providerId;
  final String playlistId;
  final String name;
  final String? description;
  final String? creatorName;
  final Uri? cover;
  final int trackCount;
  final int? playCount;
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
