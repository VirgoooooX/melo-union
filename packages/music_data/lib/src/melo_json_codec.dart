import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import 'melo_data_snapshot.dart';

final class MeloJsonCodec {
  const MeloJsonCodec();

  static const int schemaVersion = 4;

  Map<String, Object?> encodeSnapshot(MeloDataSnapshot snapshot) {
    return {
      'schemaVersion': schemaVersion,
      'playlists': [
        for (final playlist in snapshot.playlists) _encodePlaylist(playlist),
      ],
      'downloadTasks': [
        for (final task in snapshot.downloadTasks) _encodeDownloadTask(task),
      ],
      'localMediaItems': [
        for (final item in snapshot.localMediaItems)
          _encodeLocalMediaItem(item),
      ],
      'localLibraryRoots': [
        for (final root in snapshot.localLibraryRoots) _encodeLocalRoot(root),
      ],
      'localLibraryTracks': [
        for (final track in snapshot.localLibraryTracks)
          _encodeLocalTrack(track),
      ],
      'favoriteProviderSnapshots': [
        for (final snapshot in snapshot.favoriteProviderSnapshots)
          _encodeFavoriteSnapshot(snapshot),
      ],
      'favoriteLikedAtLedger': [
        for (final entry in snapshot.favoriteLikedAtLedger.entries)
          _encodeLikedAtLedgerEntry(entry),
      ],
      'unifiedFavoritesCache': snapshot.unifiedFavoritesCache == null
          ? null
          : _encodeUnifiedFavoritesCache(snapshot.unifiedFavoritesCache!),
      'favoriteProviderStates': [
        for (final state in snapshot.favoriteProviderStates)
          _encodeFavoriteProviderState(state),
      ],
      'playbackQuality': snapshot.playbackQuality.name,
      'downloadQuality': snapshot.downloadQuality.name,
      'volume': snapshot.volume,
      'playbackPreferences': _encodePlaybackPreferences(
        snapshot.playbackPreferences,
      ),
      'playbackQueue': snapshot.playbackQueue == null
          ? null
          : _encodePlaybackQueue(snapshot.playbackQueue!),
      'downloadDirectory': snapshot.downloadDirectory,
      'favoritesOverrides': _encodeFavoritesOverrides(
        snapshot.favoritesOverrides,
      ),
    };
  }

  MeloDataSnapshot decodeSnapshot(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version is! int || version < 1 || version > schemaVersion) {
      throw FormatException('Unsupported Melo data schema: $version');
    }

    final overrides = FavoritesOverrideRegistry();
    final overridesJson =
        _stringKeyedMap(json['favoritesOverrides'] as Map<Object?, Object?>?);
    for (final pair in _refPairs(overridesJson['mergeOverrides'])) {
      overrides.addMergeOverride(pair.$1, pair.$2);
    }
    for (final pair in _refPairs(overridesJson['splitOverrides'])) {
      overrides.addSplitOverride(pair.$1, pair.$2);
    }
    for (final refJson in _listOfMaps(overridesJson['hiddenTracks'])) {
      overrides.hideTrack(_decodeTrackRef(refJson));
    }
    final legacyLikedAtTracking = _listOfMaps(overridesJson['likedAtTracking']);
    final likedAtLedger = LikedAtLedger(
      entries: [
        for (final item in _listOfMaps(json['favoriteLikedAtLedger']))
          _decodeLikedAtLedgerEntry(item),
      ],
    );
    if (likedAtLedger.isEmpty) {
      for (final entry in legacyLikedAtTracking) {
        likedAtLedger.record(
          _decodeTrackRef(_requiredMap(entry, 'ref')),
          _decodeLikedAtMetadata(
            _stringKeyedMap(entry['metadata'] as Map<Object?, Object?>?),
          ),
        );
      }
    }

    return MeloDataSnapshot(
      playlists: [
        for (final item in _listOfMaps(json['playlists']))
          _decodePlaylist(item),
      ],
      downloadTasks: [
        for (final item in _listOfMaps(json['downloadTasks']))
          _decodeDownloadTask(item),
      ],
      localMediaItems: [
        for (final item in _listOfMaps(json['localMediaItems']))
          _decodeLocalMediaItem(item),
      ],
      localLibraryRoots: [
        for (final item in _listOfMaps(json['localLibraryRoots']))
          _decodeLocalRoot(item),
      ],
      localLibraryTracks: [
        for (final item in _listOfMaps(json['localLibraryTracks']))
          _decodeLocalTrack(item),
      ],
      favoriteProviderSnapshots: [
        for (final item in _listOfMaps(json['favoriteProviderSnapshots']))
          _decodeFavoriteSnapshot(item),
      ],
      favoriteLikedAtLedger: likedAtLedger,
      unifiedFavoritesCache:
          _decodeOptionalUnifiedFavoritesCache(json['unifiedFavoritesCache']),
      favoriteProviderStates: [
        for (final item in _listOfMaps(json['favoriteProviderStates']))
          _decodeFavoriteProviderState(item),
      ],
      playbackQuality: AudioQuality.values.byName(
        json['playbackQuality'] as String? ?? AudioQuality.standard.name,
      ),
      downloadQuality: AudioQuality.values.byName(
        json['downloadQuality'] as String? ?? AudioQuality.standard.name,
      ),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      playbackPreferences: _decodePlaybackPreferences(
        json['playbackPreferences'],
      ),
      playbackQueue: _decodeOptionalPlaybackQueue(json['playbackQueue']),
      downloadDirectory: json['downloadDirectory'] as String?,
      favoritesOverrides: overrides,
    );
  }

  Map<String, Object?> _encodePlaylist(LocalPlaylist playlist) {
    return {
      'id': playlist.id,
      'name': playlist.name,
      'items': [
        for (final item in playlist.items) _encodePlaylistItem(item),
      ],
    };
  }

  Map<String, Object?> _encodeLocalRoot(LocalLibraryRoot root) => {
        'id': root.id,
        'path': root.path,
        'displayName': root.displayName,
        'scanState': root.scanState.name,
        'lastScannedAt': root.lastScannedAt?.toUtc().toIso8601String(),
        'lastError': root.lastError,
      };

  LocalLibraryRoot _decodeLocalRoot(Map<String, Object?> json) =>
      LocalLibraryRoot(
        id: _requiredString(json, 'id'),
        path: _requiredString(json, 'path'),
        displayName: _requiredString(json, 'displayName'),
        scanState: LocalLibraryScanState.values.firstWhere(
          (state) => state.name == json['scanState'],
          orElse: () => LocalLibraryScanState.idle,
        ),
        lastScannedAt: _optionalDateTime(json['lastScannedAt']?.toString()),
        lastError: json['lastError'] as String?,
      );

  Map<String, Object?> _encodeLocalTrack(LocalLibraryTrack track) => {
        'id': track.id,
        'rootId': track.rootId,
        'filePath': track.filePath,
        'relativePath': track.relativePath,
        'fileSize': track.fileSize,
        'modifiedAt': track.modifiedAt.toUtc().toIso8601String(),
        'fingerprint': track.fingerprint,
        'title': track.title,
        'artists': track.artists,
        'durationMs': track.duration.inMilliseconds,
        'format': track.format,
        'album': track.album,
        'genre': track.genre,
        'year': track.year,
        'trackNumber': track.trackNumber,
        'discNumber': track.discNumber,
        'lyrics': track.lyrics,
        'artworkPath': track.artworkPath,
        'isAvailable': track.isAvailable,
        'isFavorited': track.isFavorited,
        'likedAt': track.likedAt?.toUtc().toIso8601String(),
      };

  LocalLibraryTrack _decodeLocalTrack(Map<String, Object?> json) =>
      LocalLibraryTrack(
        id: _requiredString(json, 'id'),
        rootId: _requiredString(json, 'rootId'),
        filePath: _requiredString(json, 'filePath'),
        relativePath: _requiredString(json, 'relativePath'),
        fileSize: (json['fileSize'] as num).toInt(),
        modifiedAt: DateTime.parse(_requiredString(json, 'modifiedAt')),
        fingerprint: _requiredString(json, 'fingerprint'),
        title: _requiredString(json, 'title'),
        artists: (json['artists'] as List? ?? const [])
            .map((artist) => artist.toString())
            .toList(growable: false),
        duration: Duration(milliseconds: (json['durationMs'] as num).toInt()),
        format: _requiredString(json, 'format'),
        album: json['album'] as String?,
        genre: json['genre'] as String?,
        year: (json['year'] as num?)?.toInt(),
        trackNumber: (json['trackNumber'] as num?)?.toInt(),
        discNumber: (json['discNumber'] as num?)?.toInt(),
        lyrics: json['lyrics'] as String?,
        artworkPath: json['artworkPath'] as String?,
        isAvailable: json['isAvailable'] as bool? ?? true,
        isFavorited: json['isFavorited'] as bool? ?? false,
        likedAt: _optionalDateTime(json['likedAt']?.toString()),
      );

  LocalPlaylist _decodePlaylist(Map<String, Object?> json) {
    return LocalPlaylist(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      items: [
        for (final item in _listOfMaps(json['items']))
          _decodePlaylistItem(item),
      ],
    );
  }

  Map<String, Object?> _encodePlaylistItem(LocalPlaylistItem item) {
    return {
      'trackRef': _encodeTrackRef(item.trackRef),
      'cachedTitle': item.cachedTitle,
      'cachedArtists': item.cachedArtists,
      'cachedProviderName': item.cachedProviderName,
      'addedAt': item.addedAt.toUtc().toIso8601String(),
    };
  }

  LocalPlaylistItem _decodePlaylistItem(Map<String, Object?> json) {
    return LocalPlaylistItem(
      trackRef: _decodeTrackRef(_requiredMap(json, 'trackRef')),
      cachedTitle: _requiredString(json, 'cachedTitle'),
      cachedArtists: _stringList(json['cachedArtists']),
      cachedProviderName: _requiredString(json, 'cachedProviderName'),
      addedAt: DateTime.parse(_requiredString(json, 'addedAt')).toUtc(),
    );
  }

  Map<String, Object?> _encodeDownloadTask(DownloadTask task) {
    return {
      'track': _encodeSourceTrack(task.track),
      'quality': task.quality.name,
      'status': task.status.name,
      'progress': task.progress,
      'error': task.error,
      'savedFilePath': task.savedFilePath,
      'createdAt': task.createdAt.toUtc().toIso8601String(),
    };
  }

  DownloadTask _decodeDownloadTask(Map<String, Object?> json) {
    return DownloadTask(
      track: _decodeSourceTrack(_requiredMap(json, 'track')),
      quality: AudioQuality.values.byName(_requiredString(json, 'quality')),
      status: DownloadStatus.values.byName(_requiredString(json, 'status')),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      error: json['error'] as String?,
      savedFilePath: json['savedFilePath'] as String?,
      createdAt: DateTime.parse(_requiredString(json, 'createdAt')).toUtc(),
    );
  }

  Map<String, Object?> _encodeLocalMediaItem(LocalMediaItem item) {
    return {
      'sourceRef': _encodeTrackRef(item.sourceRef),
      'title': item.title,
      'artists': item.artists,
      'durationMs': item.duration.inMilliseconds,
      'filePath': item.filePath,
      'fileSize': item.fileSize,
      'downloadedAt': item.downloadedAt.toUtc().toIso8601String(),
      'quality': item.quality.name,
    };
  }

  Map<String, Object?> _encodeFavoriteSnapshot(FavoriteSnapshot snapshot) {
    return {
      'providerId': snapshot.providerId.value,
      'fetchedAt': snapshot.fetchedAt.toUtc().toIso8601String(),
      'partialFailureReason': snapshot.partialFailureReason,
      'tracks': [
        for (final track in snapshot.tracks) _encodeSourceTrack(track),
      ],
    };
  }

  FavoriteSnapshot _decodeFavoriteSnapshot(Map<String, Object?> json) {
    return FavoriteSnapshot(
      providerId: ProviderId(_requiredString(json, 'providerId')),
      tracks: [
        for (final item in _listOfMaps(json['tracks']))
          _decodeSourceTrack(item),
      ],
      fetchedAt: DateTime.parse(_requiredString(json, 'fetchedAt')).toUtc(),
      partialFailureReason: json['partialFailureReason'] as String?,
    );
  }

  Map<String, Object?> _encodeLikedAtLedgerEntry(LikedAtLedgerEntry entry) {
    return {
      'ref': _encodeTrackRef(entry.ref),
      'metadata': _encodeLikedAtMetadata(entry.metadata),
      'updatedAt': entry.updatedAt?.toUtc().toIso8601String(),
    };
  }

  LikedAtLedgerEntry _decodeLikedAtLedgerEntry(Map<String, Object?> json) {
    return LikedAtLedgerEntry(
      ref: _decodeTrackRef(_requiredMap(json, 'ref')),
      metadata: _decodeLikedAtMetadata(_requiredMap(json, 'metadata')),
      updatedAt: _optionalDateTime(json['updatedAt']?.toString()),
    );
  }

  Map<String, Object?> _encodeUnifiedFavoritesCache(
    CachedUnifiedFavorites cache,
  ) {
    return {
      'builtAt': cache.builtAt.toUtc().toIso8601String(),
      'tracks': [
        for (final track in cache.tracks) _encodeUnifiedFavoriteTrack(track),
      ],
    };
  }

  CachedUnifiedFavorites? _decodeOptionalUnifiedFavoritesCache(Object? raw) {
    if (raw == null) return null;
    final json = _stringKeyedMap(raw as Map<Object?, Object?>);
    return CachedUnifiedFavorites(
      builtAt: DateTime.parse(_requiredString(json, 'builtAt')).toUtc(),
      tracks: [
        for (final item in _listOfMaps(json['tracks']))
          _decodeUnifiedFavoriteTrack(item),
      ],
    );
  }

  Map<String, Object?> _encodeUnifiedFavoriteTrack(
    UnifiedFavoriteTrack track,
  ) {
    return {
      'unifiedId': track.unifiedId,
      'title': track.title,
      'artists': track.artists,
      'durationMs': track.duration.inMilliseconds,
      'variants': [
        for (final variant in track.variants) _encodeSourceTrack(variant),
      ],
    };
  }

  UnifiedFavoriteTrack _decodeUnifiedFavoriteTrack(Map<String, Object?> json) {
    return UnifiedFavoriteTrack(
      unifiedId: _requiredString(json, 'unifiedId'),
      title: _requiredString(json, 'title'),
      artists: _stringList(json['artists']),
      duration: Duration(milliseconds: json['durationMs'] as int),
      variants: [
        for (final item in _listOfMaps(json['variants']))
          _decodeSourceTrack(item),
      ],
    );
  }

  Map<String, Object?> _encodeFavoriteProviderState(
    FavoriteProviderStateSnapshot state,
  ) {
    return {
      'providerId': state.providerId.value,
      'lastSuccessAt': state.lastSuccessAt?.toUtc().toIso8601String(),
      'lastFailureAt': state.lastFailureAt?.toUtc().toIso8601String(),
      'lastFailureMessage': state.lastFailureMessage,
    };
  }

  FavoriteProviderStateSnapshot _decodeFavoriteProviderState(
    Map<String, Object?> json,
  ) {
    return FavoriteProviderStateSnapshot(
      providerId: ProviderId(_requiredString(json, 'providerId')),
      lastSuccessAt: _optionalDateTime(json['lastSuccessAt']?.toString()),
      lastFailureAt: _optionalDateTime(json['lastFailureAt']?.toString()),
      lastFailureMessage: json['lastFailureMessage'] as String?,
    );
  }

  Map<String, Object?> _encodePlaybackPreferences(
    PlaybackPreferencesSnapshot preferences,
  ) {
    return {
      'rememberQueue': preferences.rememberQueue,
      'restorePlaybackState': preferences.restorePlaybackState,
    };
  }

  PlaybackPreferencesSnapshot _decodePlaybackPreferences(Object? raw) {
    final json = _stringKeyedMap(raw as Map<Object?, Object?>?);
    return PlaybackPreferencesSnapshot(
      rememberQueue: json['rememberQueue'] as bool? ?? false,
      restorePlaybackState: json['restorePlaybackState'] as bool? ?? false,
    );
  }

  Map<String, Object?> _encodePlaybackQueue(PlaybackQueueSnapshot queue) {
    return {
      'entries': [
        for (final entry in queue.entries) _encodePlaybackQueueEntry(entry),
      ],
      'currentIndex': queue.currentIndex,
      'positionMs': queue.position.inMilliseconds,
      'shuffleEnabled': queue.shuffleEnabled,
      'repeatMode': queue.repeatMode,
      'updatedAt': queue.updatedAt.toUtc().toIso8601String(),
    };
  }

  PlaybackQueueSnapshot? _decodeOptionalPlaybackQueue(Object? raw) {
    if (raw == null) return null;
    final json = _stringKeyedMap(raw as Map<Object?, Object?>);
    return PlaybackQueueSnapshot(
      entries: [
        for (final item in _listOfMaps(json['entries']))
          _decodePlaybackQueueEntry(item),
      ],
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? -1,
      position: Duration(
        milliseconds: (json['positionMs'] as num?)?.toInt() ?? 0,
      ),
      shuffleEnabled: json['shuffleEnabled'] as bool? ?? false,
      repeatMode: json['repeatMode']?.toString() ?? 'off',
      updatedAt: _optionalDateTime(json['updatedAt']?.toString()),
    );
  }

  Map<String, Object?> _encodePlaybackQueueEntry(
    PlaybackQueueEntrySnapshot entry,
  ) {
    return {
      'entryId': entry.entryId,
      'track': _encodeSourceTrack(entry.track),
      'queuedAt': entry.queuedAt.toUtc().toIso8601String(),
    };
  }

  PlaybackQueueEntrySnapshot _decodePlaybackQueueEntry(
    Map<String, Object?> json,
  ) {
    return PlaybackQueueEntrySnapshot(
      entryId: json['entryId'] as String? ?? createPlaybackQueueEntryId(),
      track: _decodeSourceTrack(_requiredMap(json, 'track')),
      queuedAt: DateTime.parse(_requiredString(json, 'queuedAt')).toUtc(),
    );
  }

  LocalMediaItem _decodeLocalMediaItem(Map<String, Object?> json) {
    return LocalMediaItem(
      sourceRef: _decodeTrackRef(_requiredMap(json, 'sourceRef')),
      title: _requiredString(json, 'title'),
      artists: _stringList(json['artists']),
      duration: Duration(milliseconds: json['durationMs'] as int),
      filePath: _requiredString(json, 'filePath'),
      fileSize: json['fileSize'] as int,
      downloadedAt:
          DateTime.parse(_requiredString(json, 'downloadedAt')).toUtc(),
      quality: AudioQuality.values.byName(
        json['quality'] as String? ?? AudioQuality.low.name,
      ),
    );
  }

  Map<String, Object?> _encodeSourceTrack(SourceTrack track) {
    return {
      'ref': _encodeTrackRef(track.ref),
      'title': track.title,
      'artists': track.artists,
      'album': track.album,
      'year': track.year,
      'trackNumber': track.trackNumber,
      'discNumber': track.discNumber,
      'isrc': track.isrc,
      'artwork': track.artwork?.toString(),
      'durationMs': track.duration.inMilliseconds,
      'isFavorited': track.isFavorited,
      'isPlayable': track.isPlayable,
      'isDownloadable': track.isDownloadable,
      if (track.likedAt != null)
        'likedAt': track.likedAt!.toUtc().toIso8601String(),
      if (track.likedAtSource != null) 'likedAtSource': track.likedAtSource,
      if (track.likedAtPrecision != null)
        'likedAtPrecision': track.likedAtPrecision,
    };
  }

  SourceTrack _decodeSourceTrack(Map<String, Object?> json) {
    final artwork = json['artwork'] as String?;
    final likedAtStr = json['likedAt'] as String?;
    return SourceTrack(
      ref: _decodeTrackRef(_requiredMap(json, 'ref')),
      title: _requiredString(json, 'title'),
      artists: _stringList(json['artists']),
      album: json['album'] as String?,
      year: (json['year'] as num?)?.toInt(),
      trackNumber: (json['trackNumber'] as num?)?.toInt(),
      discNumber: (json['discNumber'] as num?)?.toInt(),
      isrc: json['isrc'] as String?,
      artwork: artwork == null ? null : Uri.parse(artwork),
      duration: Duration(milliseconds: json['durationMs'] as int),
      isFavorited: json['isFavorited'] as bool? ?? false,
      isPlayable: json['isPlayable'] as bool? ?? true,
      isDownloadable: json['isDownloadable'] as bool? ?? false,
      likedAt: likedAtStr == null ? null : DateTime.parse(likedAtStr).toUtc(),
      likedAtSource: json['likedAtSource'] as String?,
      likedAtPrecision: json['likedAtPrecision'] as String?,
    );
  }

  Map<String, Object?> _encodeFavoritesOverrides(
    FavoritesOverrideRegistry registry,
  ) {
    return {
      'mergeOverrides': [
        for (final refs in registry.mergeOverrides) _encodeRefSet(refs),
      ],
      'splitOverrides': [
        for (final refs in registry.splitOverrides) _encodeRefSet(refs),
      ],
      'hiddenTracks': [
        for (final ref in registry.hiddenTracks) _encodeTrackRef(ref),
      ],
    };
  }

  Map<String, Object?> _encodeLikedAtMetadata(LikedAtMetadata metadata) {
    return {
      if (metadata.likedAt != null)
        'likedAt': metadata.likedAt!.toUtc().toIso8601String(),
      'source': metadata.source,
      'precision': metadata.precision,
    };
  }

  LikedAtMetadata _decodeLikedAtMetadata(Map<String, Object?> json) {
    return LikedAtMetadata(
      likedAt: _optionalDateTime(json['likedAt']?.toString()),
      source: json['source']?.toString() ?? LikedAtMetadata.sourceUnknown,
      precision:
          json['precision']?.toString() ?? LikedAtMetadata.precisionUnknown,
    );
  }

  List<Map<String, Object?>> _encodeRefSet(Set<ProviderTrackRef> refs) {
    final ordered = refs.toList(growable: false)
      ..sort((left, right) => _refSortKey(left).compareTo(_refSortKey(right)));
    return [
      for (final ref in ordered) _encodeTrackRef(ref),
    ];
  }

  Iterable<(ProviderTrackRef, ProviderTrackRef)> _refPairs(Object? raw) sync* {
    for (final refs in _listOfLists(raw)) {
      final decoded = [
        for (final ref in refs) _decodeTrackRef(_stringKeyedMap(ref as Map)),
      ];
      if (decoded.length < 2) continue;
      for (var i = 1; i < decoded.length; i++) {
        yield (decoded.first, decoded[i]);
      }
    }
  }

  Map<String, Object?> _encodeTrackRef(ProviderTrackRef ref) {
    return {
      'providerId': ref.providerId.value,
      'trackId': ref.trackId,
      'extraIds': ref.extraIds,
    };
  }

  ProviderTrackRef _decodeTrackRef(Map<String, Object?> json) {
    return ProviderTrackRef(
      providerId: ProviderId(_requiredString(json, 'providerId')),
      trackId: _requiredString(json, 'trackId'),
      extraIds: {
        for (final entry in _requiredMap(json, 'extraIds').entries)
          entry.key: entry.value as String,
      },
    );
  }

  String _refSortKey(ProviderTrackRef ref) {
    return '${ref.providerId.value}:${ref.trackId}';
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Expected string field "$key".');
    }
    return value;
  }

  Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
    return _stringKeyedMap(json[key] as Map<Object?, Object?>?);
  }

  List<String> _stringList(Object? raw) {
    return [
      for (final item in (raw as List<Object?>? ?? const [])) item as String,
    ];
  }

  List<Map<String, Object?>> _listOfMaps(Object? raw) {
    return [
      for (final item in (raw as List<Object?>? ?? const []))
        _stringKeyedMap(item as Map<Object?, Object?>),
    ];
  }

  List<List<Object?>> _listOfLists(Object? raw) {
    return [
      for (final item in (raw as List<Object?>? ?? const []))
        item as List<Object?>,
    ];
  }

  Map<String, Object?> _stringKeyedMap(Map<Object?, Object?>? raw) {
    if (raw == null) {
      return const {};
    }
    return {
      for (final entry in raw.entries) entry.key as String: entry.value,
    };
  }

  DateTime? _optionalDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}
