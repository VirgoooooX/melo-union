import 'package:provider_contract/provider_contract.dart';

const localMusicProviderIdValue = 'local';

ProviderId get localMusicProviderId => ProviderId(localMusicProviderIdValue);

String normalizeLocalMetadata(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[\s\p{P}\p{S}]+', unicode: true), '')
    .trim();

String localArtistKey(String value) => value
    .toLowerCase()
    .replaceAll('\u3000', ' ')
    .replaceAll('／', '/')
    .replaceAll('\\', '/')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String localAlbumKey(String artist, String album, [String? editionKey]) =>
    '${localArtistKey(artist)}|${normalizeLocalMetadata(album)}|'
    '${editionKey?.trim().toLowerCase() ?? ''}';

enum LocalLibraryScanState { idle, scanning, completed, failed }

enum LocalLibrarySortOrder { album, title, artist }

enum LocalArtistSortOrder { name, albumCount, trackCount, recentlyAdded }

enum LocalAlbumSortOrder { artist, title, year, recentlyAdded, trackCount }

enum ArtistMetadataStatus { pending, matched, noMatch, failed, forcedCollage }

enum LocalAlbumArtistSource {
  unresolved,
  embeddedTag,
  directoryConsensus,
  albumConsensus,
  trackArtistFallback,
  variousArtists,
  userOverride,
}

final class LocalLibraryRoot {
  const LocalLibraryRoot({
    required this.id,
    required this.path,
    required this.displayName,
    this.scanState = LocalLibraryScanState.idle,
    this.lastScannedAt,
    this.lastError,
  });

  final String id;
  final String path;
  final String displayName;
  final LocalLibraryScanState scanState;
  final DateTime? lastScannedAt;
  final String? lastError;

  LocalLibraryRoot copyWith({
    String? path,
    String? displayName,
    LocalLibraryScanState? scanState,
    DateTime? lastScannedAt,
    String? lastError,
    bool clearError = false,
  }) =>
      LocalLibraryRoot(
        id: id,
        path: path ?? this.path,
        displayName: displayName ?? this.displayName,
        scanState: scanState ?? this.scanState,
        lastScannedAt: lastScannedAt ?? this.lastScannedAt,
        lastError: clearError ? null : lastError ?? this.lastError,
      );
}

final class LocalLibraryTrack {
  const LocalLibraryTrack({
    required this.id,
    required this.rootId,
    required this.filePath,
    required this.relativePath,
    required this.fileSize,
    required this.modifiedAt,
    required this.fingerprint,
    required this.title,
    required this.artists,
    required this.duration,
    required this.format,
    this.album,
    this.genre,
    this.genres = const [],
    this.embeddedAlbumArtist,
    this.albumArtist,
    this.albumArtistSource = LocalAlbumArtistSource.unresolved,
    this.albumEditionKey,
    this.isrc,
    DateTime? addedAt,
    this.bitRate,
    this.sampleRate,
    this.bitDepth,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.lyrics,
    this.artworkPath,
    this.isAvailable = true,
    this.isFavorited = false,
    this.likedAt,
  }) : addedAt = addedAt ?? modifiedAt;

  final String id;
  final String rootId;
  final String filePath;
  final String relativePath;
  final int fileSize;
  final DateTime modifiedAt;
  final String fingerprint;
  final String title;
  final List<String> artists;
  final Duration duration;
  final String format;
  final String? album;
  final String? genre;
  final List<String> genres;
  final String? embeddedAlbumArtist;
  final String? albumArtist;
  final LocalAlbumArtistSource albumArtistSource;
  final String? albumEditionKey;
  final String? isrc;
  final DateTime addedAt;
  final int? bitRate;
  final int? sampleRate;
  final int? bitDepth;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final String? lyrics;
  final String? artworkPath;
  final bool isAvailable;
  final bool isFavorited;
  final DateTime? likedAt;

  List<String> get trackArtists => artists;

  ProviderTrackRef get ref => ProviderTrackRef(
        providerId: localMusicProviderId,
        trackId: id,
        extraIds: {'format': format.toLowerCase()},
      );

  SourceTrack toSourceTrack() => SourceTrack(
        ref: ref,
        title: title,
        artists: artists,
        duration: duration,
        isFavorited: isFavorited,
        album: album,
        year: year,
        trackNumber: trackNumber,
        discNumber: discNumber,
        isrc: isrc,
        artwork: artworkPath == null ? null : Uri.file(artworkPath!),
        // 本地曲一旦被索引即视为可点击播放；磁盘可用性在 ticket 解析阶段
        // （LocalMusicProvider.createPlaybackTicket）复核，不在此处叠加闸门——
        // 否则文件被改名/移动后 isAvailable 失真，点播会被静默丢弃而无任何 UI 提示。
        isPlayable: true,
        likedAt: likedAt,
        likedAtSource: likedAt == null ? null : 'app_action',
        likedAtPrecision: likedAt == null ? null : 'exact',
      );

  LocalLibraryTrack copyWith({
    String? rootId,
    String? filePath,
    String? relativePath,
    int? fileSize,
    DateTime? modifiedAt,
    String? fingerprint,
    String? title,
    List<String>? artists,
    Duration? duration,
    String? format,
    String? album,
    String? genre,
    List<String>? genres,
    String? embeddedAlbumArtist,
    String? albumArtist,
    LocalAlbumArtistSource? albumArtistSource,
    String? albumEditionKey,
    String? isrc,
    DateTime? addedAt,
    int? bitRate,
    int? sampleRate,
    int? bitDepth,
    int? year,
    int? trackNumber,
    int? discNumber,
    String? lyrics,
    String? artworkPath,
    bool? isAvailable,
    bool? isFavorited,
    DateTime? likedAt,
    bool clearLikedAt = false,
  }) =>
      LocalLibraryTrack(
        id: id,
        rootId: rootId ?? this.rootId,
        filePath: filePath ?? this.filePath,
        relativePath: relativePath ?? this.relativePath,
        fileSize: fileSize ?? this.fileSize,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        fingerprint: fingerprint ?? this.fingerprint,
        title: title ?? this.title,
        artists: artists ?? this.artists,
        duration: duration ?? this.duration,
        format: format ?? this.format,
        album: album ?? this.album,
        genre: genre ?? this.genre,
        genres: genres ?? this.genres,
        embeddedAlbumArtist: embeddedAlbumArtist ?? this.embeddedAlbumArtist,
        albumArtist: albumArtist ?? this.albumArtist,
        albumArtistSource: albumArtistSource ?? this.albumArtistSource,
        albumEditionKey: albumEditionKey ?? this.albumEditionKey,
        isrc: isrc ?? this.isrc,
        addedAt: addedAt ?? this.addedAt,
        bitRate: bitRate ?? this.bitRate,
        sampleRate: sampleRate ?? this.sampleRate,
        bitDepth: bitDepth ?? this.bitDepth,
        year: year ?? this.year,
        trackNumber: trackNumber ?? this.trackNumber,
        discNumber: discNumber ?? this.discNumber,
        lyrics: lyrics ?? this.lyrics,
        artworkPath: artworkPath ?? this.artworkPath,
        isAvailable: isAvailable ?? this.isAvailable,
        isFavorited: isFavorited ?? this.isFavorited,
        likedAt: clearLikedAt ? null : likedAt ?? this.likedAt,
      );
}

final class LocalLibraryStats {
  const LocalLibraryStats(
      {required this.trackCount,
      required this.albumCount,
      required this.artistCount});
  final int trackCount;
  final int albumCount;
  final int artistCount;
}

final class LocalLibraryArtist {
  const LocalLibraryArtist(
      {required this.artistKey,
      required this.displayName,
      required this.trackCount,
      required this.albumCount,
      this.sampleArtworkPaths = const [],
      this.metadata});
  final String artistKey;
  final String displayName;
  final int trackCount;
  final int albumCount;
  final List<String> sampleArtworkPaths;
  final LocalArtistMetadata? metadata;
}

final class LocalLibraryAlbum {
  const LocalLibraryAlbum({
    required this.albumKey,
    required this.title,
    required this.albumArtist,
    required this.trackCount,
    required this.duration,
    int? year,
    int? canonicalYear,
    this.observedYears = const [],
    this.hasYearConflict = false,
    this.albumArtistSource = LocalAlbumArtistSource.unresolved,
    this.artworkPath,
  }) : canonicalYear = canonicalYear ?? year;
  final String albumKey;
  final String title;
  final String albumArtist;
  final int? canonicalYear;
  final List<int> observedYears;
  final bool hasYearConflict;
  final LocalAlbumArtistSource albumArtistSource;
  final int trackCount;
  final Duration duration;
  final String? artworkPath;

  int? get year => canonicalYear;
}

final class LocalArtistMetadata {
  const LocalArtistMetadata(
      {required this.artistKey,
      required this.displayName,
      required this.status,
      this.sourceProviderId,
      this.remoteArtistId,
      this.remoteName,
      this.avatarUrl,
      this.avatarCachePath,
      this.backgroundUrl,
      this.backgroundCachePath,
      this.description,
      this.confidence,
      this.userConfirmed = false,
      this.fetchedAt,
      this.retryAfter});
  final String artistKey;
  final String displayName;
  final ArtistMetadataStatus status;
  final ProviderId? sourceProviderId;
  final String? remoteArtistId;
  final String? remoteName;
  final String? avatarUrl;
  final String? avatarCachePath;
  final String? backgroundUrl;
  final String? backgroundCachePath;
  final String? description;
  final double? confidence;
  final bool userConfirmed;
  final DateTime? fetchedAt;
  final DateTime? retryAfter;
}

final class LocalTrackMatch {
  const LocalTrackMatch(
      {required this.remote,
      required this.localTrackId,
      required this.method,
      required this.confidence,
      required this.updatedAt});
  final ProviderTrackRef remote;
  final String localTrackId;
  final String method;
  final double confidence;
  final DateTime updatedAt;
}

abstract interface class LocalLibraryRepository {
  Future<List<LocalLibraryRoot>> listRoots();
  Future<List<LocalLibraryTrack>> listTracks({
    String query = '',
    LocalLibrarySortOrder sort = LocalLibrarySortOrder.album,
    int limit = 200,
    int offset = 0,
  });
  Future<LocalLibraryTrack?> getTrack(String id);
  Future<LocalLibraryTrack?> findByPath(String filePath);
  Future<List<LocalLibraryTrack>> findByFingerprint(String fingerprint);
  Future<void> upsertRoot(LocalLibraryRoot root);
  Future<void> removeRoot(String rootId);
  Future<void> upsertTracks(List<LocalLibraryTrack> tracks);
  Future<void> replaceAll(
    List<LocalLibraryRoot> roots,
    List<LocalLibraryTrack> tracks,
  );
  Future<void> markUnavailableExcept(String rootId, Set<String> availablePaths);
  Future<void> setFavorite(String trackId, bool liked, {DateTime? likedAt});
  Future<LocalLibraryStats> getStats();
  Future<List<LocalLibraryArtist>> listArtists(
      {String query = '',
      LocalArtistSortOrder sort = LocalArtistSortOrder.name,
      int limit = 100,
      int offset = 0});
  Future<LocalLibraryArtist?> getArtist(String artistKey);
  Future<List<LocalLibraryTrack>> listArtistTracks(String artistKey);
  Future<List<LocalLibraryAlbum>> listArtistAlbums(String artistKey);
  Future<List<LocalLibraryAlbum>> listAlbums(
      {String query = '',
      LocalAlbumSortOrder sort = LocalAlbumSortOrder.artist,
      int limit = 100,
      int offset = 0});
  Future<LocalLibraryAlbum?> getAlbum(String albumKey);
  Future<List<LocalLibraryTrack>> listAlbumTracks(String albumKey);
  Future<LocalArtistMetadata?> getArtistMetadata(String artistKey);
  Future<void> upsertArtistMetadata(LocalArtistMetadata metadata);
  Future<LocalTrackMatch?> findLocalMatch(ProviderTrackRef remote);
  Future<void> upsertLocalTrackMatch(LocalTrackMatch match);
  Future<void> removeLocalTrackMatch(ProviderTrackRef remote);
}
