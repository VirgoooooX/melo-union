import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import 'melo_data_snapshot.dart';

final class MeloJsonCodec {
  const MeloJsonCodec();

  static const int schemaVersion = 1;

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
      'playbackQuality': snapshot.playbackQuality.name,
      'volume': snapshot.volume,
      'favoritesOverrides': _encodeFavoritesOverrides(
        snapshot.favoritesOverrides,
      ),
    };
  }

  MeloDataSnapshot decodeSnapshot(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version != schemaVersion) {
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
    for (final entry in _listOfMaps(overridesJson['likedAtTracking'])) {
      final ref = _decodeTrackRef(_requiredMap(entry, 'ref'));
      final meta = _stringKeyedMap(entry['metadata'] as Map<Object?, Object?>?);
      overrides.recordLikedAt(
        ref,
        LikedAtMetadata(
          likedAt: _optionalDateTime(meta['likedAt']?.toString()),
          source: meta['source']?.toString() ?? LikedAtMetadata.sourceUnknown,
          precision: meta['precision']?.toString() ??
              LikedAtMetadata.precisionUnknown,
        ),
      );
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
      playbackQuality: AudioQuality.values.byName(
        json['playbackQuality'] as String? ?? AudioQuality.standard.name,
      ),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
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
    };
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
    );
  }

  Map<String, Object?> _encodeSourceTrack(SourceTrack track) {
    return {
      'ref': _encodeTrackRef(track.ref),
      'title': track.title,
      'artists': track.artists,
      'album': track.album,
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
      isrc: json['isrc'] as String?,
      artwork: artwork == null ? null : Uri.parse(artwork),
      duration: Duration(milliseconds: json['durationMs'] as int),
      isFavorited: json['isFavorited'] as bool? ?? false,
      isPlayable: json['isPlayable'] as bool? ?? true,
      isDownloadable: json['isDownloadable'] as bool? ?? false,
      likedAt:
          likedAtStr == null ? null : DateTime.parse(likedAtStr).toUtc(),
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
      'likedAtTracking': [
        for (final entry in registry.likedAtTracking.entries)
          {
            'ref': _encodeTrackRef(entry.key),
            'metadata': {
              if (entry.value.likedAt != null)
                'likedAt': entry.value.likedAt!.toUtc().toIso8601String(),
              'source': entry.value.source,
              'precision': entry.value.precision,
            },
          },
      ],
    };
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
