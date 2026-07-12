import 'package:provider_contract/provider_contract.dart';

const localMusicProviderIdValue = 'local';

ProviderId get localMusicProviderId => ProviderId(localMusicProviderIdValue);

enum LocalLibraryScanState { idle, scanning, completed, failed }

enum LocalLibrarySortOrder { album, title, artist }

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
    this.year,
    this.trackNumber,
    this.discNumber,
    this.lyrics,
    this.artworkPath,
    this.isAvailable = true,
    this.isFavorited = false,
    this.likedAt,
  });

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
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final String? lyrics;
  final String? artworkPath;
  final bool isAvailable;
  final bool isFavorited;
  final DateTime? likedAt;

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
}
