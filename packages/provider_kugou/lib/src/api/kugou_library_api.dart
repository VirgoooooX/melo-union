import 'package:provider_contract/provider_contract.dart';

import '../model/kugou_remote_playlist.dart';
import '../model/kugou_remote_track.dart';
import 'kugou_api_client.dart';

final class KugouLibraryApi {
  KugouLibraryApi({
    required KugouApiClient client,
    required ProviderId providerId,
  })  : _client = client,
        _providerId = providerId;

  final KugouApiClient _client;
  final ProviderId _providerId;

  String? _favoriteCollectionId;

  Future<String> getOrResolveFavoriteCollectionId() async {
    final cached = _favoriteCollectionId;
    if (cached != null) return cached;

    final playlists = await getUserPlaylists();
    final fav = playlists.firstWhere(
      (p) => p.isFavoriteCollection,
      orElse: () => throw ProviderException(
        providerId: _providerId,
        message: 'Could not locate the default Kugou Favorite Collection.',
      ),
    );

    _favoriteCollectionId = fav.playlistId;
    return fav.playlistId;
  }

  void invalidateCollectionId() {
    _favoriteCollectionId = null;
  }

  void cacheFavoriteCollectionId(String id) {
    _favoriteCollectionId = id;
  }

  Future<List<KugouRemotePlaylist>> getUserPlaylists({
    int page = 1,
    int pageSize = 30,
  }) async {
    final response = await _client.androidGatewayPost(
      '/v7/get_all_list',
      authenticated: true,
      headers: const {'x-router': 'cloudlist.service.kugou.com'},
      bodyBuilder: (userId, token, data) => {
        'userid': userId,
        'token': token,
        ...data,
      },
      params: const {
        'plat': 1,
      },
      data: {
        'total_ver': 979,
        'type': 2,
        'page': page,
        'pagesize': pageSize,
      },
    );
    _throwIfKugouError(response, 'Kugou user playlist request failed.');

    final items = _firstList(
      response,
      const ['info', 'list', 'lists', 'data', 'rows', 'list_info'],
    );
    return items
        .whereType<Map<Object?, Object?>>()
        .map((item) => _playlistFromMap(_stringMap(item)))
        .where((playlist) =>
            playlist.playlistId.isNotEmpty && playlist.name.isNotEmpty)
        .toList(growable: false);
  }

  /// Fetches user playlists via the mobile-web API endpoint.
  ///
  /// This sends ONLY KuGooToken as cookie (no kg_mid/kg_dfid) so the server
  /// treats this as a plain web request and returns the web playlist page.
  /// Reference: music-lib's kugou/user_playlist.go → mobile-web fallback.
  Future<List<KugouRemotePlaylist>> getUserPlaylistsWeb(
    String userId,
    String token,
  ) async {
    final response = await _client.get(
      Uri.parse(
        'http://m.kugou.com/plist/index/$userId?json=true&page=1&pagesize=30',
      ),
      authenticated: false,
      headers: {
        'Cookie': 'KuGooToken=$token; userid=$userId',
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
        'Referer': 'http://m.kugou.com/',
      },
    );

    final items = _firstList(
      response,
      const ['info', 'list', 'lists', 'data', 'rows', 'list_info'],
    );
    return items
        .whereType<Map<Object?, Object?>>()
        .map((item) => _playlistFromMap(_stringMap(item)))
        .where((playlist) =>
            playlist.playlistId.isNotEmpty && playlist.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<KugouRemoteTrack>> getPlaylistTracks(
    String playlistId, {
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _client.androidGatewayPost(
      '/v4/get_list_all_file',
      authenticated: true,
      headers: const {'x-router': 'cloudlist.service.kugou.com'},
      bodyBuilder: (userId, token, data) => {
        'listid': data['listid'],
        'userid': userId,
        'area_code': data['area_code'],
        'show_relate_goods': data['show_relate_goods'],
        'pagesize': data['pagesize'],
        'allplatform': data['allplatform'],
        'show_cover': data['show_cover'],
        'type': data['type'],
        'token': token,
        'page': data['page'],
      },
      data: {
        'listid': playlistId,
        'area_code': 1,
        'show_relate_goods': 1,
        'pagesize': pageSize,
        'allplatform': 1,
        'show_cover': 1,
        'type': 0,
        'page': page,
      },
    );
    _throwIfKugouError(response, 'Kugou playlist tracks request failed.');

    final items = _firstList(
      response,
      const ['info', 'list', 'lists', 'songs', 'files', 'data'],
    );
    return items
        .whereType<Map<Object?, Object?>>()
        .map((item) => _trackFromMap(_stringMap(item)))
        .where((track) => track.hash.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> addTrackToPlaylist(
    String playlistId,
    String hash, {
    String? albumId,
    String? mixSongId,
    String? name,
  }) async {
    final clientTime =
        DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
    final response = await _client.androidGatewayPost(
      '/cloudlist.service/v6/add_song',
      authenticated: true,
      params: {
        'last_time': clientTime,
        'last_area': 'gztx',
      },
      bodyBuilder: (userId, token, data) => {
        'userid': userId,
        'token': token,
        ...data,
      },
      data: {
        'listid': playlistId,
        'list_ver': 0,
        'type': 0,
        'slow_upload': 1,
        'scene': 'false;null',
        'data': [
          {
            'number': 1,
            'name': name ?? '',
            'hash': hash.toUpperCase(),
            'size': 0,
            'sort': 0,
            'timelen': 0,
            'bitrate': 0,
            'album_id': _intValue(albumId) ?? 0,
            'mixsongid': _intValue(mixSongId) ?? 0,
          }
        ],
      },
    );
    _throwIfKugouError(response, 'Failed to add track to Kugou playlist.');
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String hash,
      {String? favoriteFileId}) async {
    if (favoriteFileId == null || favoriteFileId.trim().isEmpty) {
      throw ProviderException(
        providerId: _providerId,
        message: 'Cannot remove Kugou favorite without a favorite file id.',
      );
    }
    final response = await _client.androidGatewayPost(
      '/v4/delete_songs',
      authenticated: true,
      headers: const {'x-router': 'cloudlist.service.kugou.com'},
      bodyBuilder: (userId, token, data) => {
        'listid': data['listid'],
        'userid': userId,
        'data': data['data'],
        'type': data['type'],
        'token': token,
        'list_ver': data['list_ver'],
      },
      data: {
        'listid': playlistId,
        'list_ver': 0,
        'type': 0,
        'data': [
          {
            'fileid': _intValue(favoriteFileId) ?? favoriteFileId,
          }
        ],
      },
    );
    _throwIfKugouError(response, 'Failed to remove track from Kugou playlist.');
  }

  KugouRemotePlaylist _playlistFromMap(Map<String, Object?> map) {
    final id = _stringValue(
      map['listid'] ?? map['list_id'] ?? map['id'] ?? map['list_create_listid'],
    );
    final name = _stringValue(
      map['name'] ??
          map['listname'] ??
          map['list_name'] ??
          map['title'] ??
          map['specialname'],
    );
    final globalId = _stringValue(
      map['global_collection_id'] ?? map['global_id'] ?? map['list_create_gid'],
    );
    final isDef = _intValue(map['is_def']);
    final isFavorite = isDef == 2 ||
        name.contains('喜欢') ||
        name.toLowerCase().contains('favorite');

    return KugouRemotePlaylist(
      playlistId: id.isNotEmpty ? id : globalId,
      name: name,
      description: _emptyToNull(
        _stringValue(map['intro'] ?? map['description'] ?? map['desc']),
      ),
      creatorName: _emptyToNull(
        _stringValue(
          map['username'] ??
              map['nickname'] ??
              map['creator_name'] ??
              map['list_create_username'],
        ),
      ),
      cover: _uriValue(
        _stringValue(
          map['pic'] ??
              map['img'] ??
              map['image'] ??
              map['cover'] ??
              map['cover_url'] ??
              map['sizable_cover'],
        ),
      ),
      trackCount: _intValue(
            map['count'] ??
                map['songcount'] ??
                map['song_count'] ??
                map['total'] ??
                map['file_count'],
          ) ??
          0,
      playCount: _intValue(map['playcount'] ?? map['play_count']),
      isFavoriteCollection: isFavorite,
    );
  }

  KugouRemoteTrack _trackFromMap(Map<String, Object?> map) {
    final filename = _stringValue(map['filename'] ?? map['file_name']);
    final transParam = _jsonMap(map['trans_param']);
    final albumInfo = _jsonMap(map['albuminfo']);
    final singerInfo = _listValue(map['singerinfo']);
    final relateGoods = _listValue(map['relate_goods']);
    final hash = _bestPlayableHash(map, transParam, relateGoods);
    final title = _stringValue(
      map['songname'] ??
          map['song_name'] ??
          map['audio_name'] ??
          map['SongName'] ??
          map['name'] ??
          filename,
    );
    final artist = _artistText(map, singerInfo, filename);
    final albumId = _stringValue(
      map['album_id'] ?? map['AlbumID'] ?? albumInfo['id'],
    );
    final albumAudioId = _stringValue(
      map['album_audio_id'] ??
          map['AlbumAudioID'] ??
          map['MixSongID'] ??
          map['audio_id'] ??
          map['Audioid'] ??
          map['ID'] ??
          map['id'],
    );
    final fileHash = _stringValue(
      map['file_hash'] ?? map['origin_hash'] ?? map['FileHash'] ?? map['hash'],
    );
    final sqHash = _stringValue(
      map['sq_hash'] ?? map['sqhash'] ?? map['SQFileHash'],
    );
    final hqHash = _stringValue(
      map['hq_hash'] ?? map['320hash'] ?? map['HQFileHash'],
    );
    final resHash = _stringValue(
      map['res_hash'] ?? map['ResFileHash'],
    );
    final ogg320Hash = _stringValue(
      transParam['ogg_320_hash'] ?? map['ogg_320_hash'],
    );
    final ogg128Hash = _stringValue(
      transParam['ogg_128_hash'] ?? map['ogg_128_hash'],
    );

    return KugouRemoteTrack(
      hash: hash,
      title: _stripAudioExtension(_titleFromFilename(title)),
      artists: _artistsFromText(artist),
      duration: _durationValue(
        map['duration'] ??
            map['timelength'] ??
            map['timelen'] ??
            map['time_length'] ??
            map['FileDuration'],
      ),
      album: _emptyToNull(
        _stringValue(
          map['album_name'] ?? map['albumname'] ?? albumInfo['name'],
        ),
      ),
      albumId: _emptyToNull(albumId),
      albumAudioId: _emptyToNull(albumAudioId),
      mixSongId: _emptyToNull(
        _stringValue(
            map['mixsongid'] ?? map['mix_song_id'] ?? map['MixSongID']),
      ),
      fileHash: _emptyToNull(fileHash),
      sqHash: _emptyToNull(sqHash),
      hqHash: _emptyToNull(hqHash),
      resHash: _emptyToNull(resHash),
      ogg320Hash: _emptyToNull(ogg320Hash),
      ogg128Hash: _emptyToNull(ogg128Hash),
      favoriteFileId: _emptyToNull(
        _stringValue(
          map['fileid'] ??
              map['file_id'] ??
              map['favorite_file_id'] ??
              map['ID'] ??
              map['id'],
        ),
      ),
      explicitlyBlocked: _intValue(map['privilege']) == 0,
      favoriteTime: _dateValue(
        map['collecttime'] ??
            map['collect_time'] ??
            map['addtime'] ??
            map['add_time'] ??
            map['time'] ??
            map['ctime'],
      ),
      artwork: _uriValue(
        _stringValue(
          map['img'] ??
              map['image'] ??
              map['cover'] ??
              map['cover_url'] ??
              map['album_cover'] ??
              transParam['union_cover'],
        ),
      ),
    );
  }

  void _throwIfKugouError(Map<String, dynamic> response, String fallback) {
    final status = _intValue(response['status']);
    final errorCode = _intValue(response['error_code'] ?? response['err_code']);
    if (status == 0 || (errorCode != null && errorCode != 0)) {
      final message = _stringValue(
        response['error_msg'] ?? response['msg'] ?? response['message'],
      );
      throw ProviderException(
        providerId: _providerId,
        message: message.isEmpty
            ? '$fallback (code: $errorCode)'
            : '$message (code: $errorCode)',
      );
    }
  }

  List<dynamic> _firstList(
    Object? root,
    List<String> preferredKeys,
  ) {
    final direct = _listFromPreferredKeys(root, preferredKeys);
    if (direct.isNotEmpty) return direct;
    if (root is Map<Object?, Object?>) {
      for (final value in root.values) {
        final nested = _firstList(value, preferredKeys);
        if (nested.isNotEmpty) return nested;
      }
    }
    if (root is List<dynamic>) return root;
    return const [];
  }

  List<dynamic> _listFromPreferredKeys(
    Object? value,
    List<String> preferredKeys,
  ) {
    if (value is! Map<Object?, Object?>) return const [];
    for (final key in preferredKeys) {
      final candidate = value[key];
      if (candidate is List<dynamic>) return candidate;
      if (candidate is Map<Object?, Object?>) {
        final nested = _listFromPreferredKeys(candidate, preferredKeys);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  Map<String, Object?> _stringMap(Map<Object?, Object?> value) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  Map<String, Object?> _jsonMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map<Object?, Object?>) return _stringMap(value);
    return const {};
  }

  List<Object?> _listValue(Object? value) =>
      value is List ? value.cast<Object?>() : const [];

  String _bestPlayableHash(
    Map<String, Object?> map,
    Map<String, Object?> transParam,
    List<Object?> relateGoods,
  ) {
    // Kugou exposes one "song" as several *file variants* distinguished by
    // hash: FileHash/hash_128 (128k mp3), HQFileHash/ogg_320 (320k),
    // SQFileHash (flac), ResFileHash (hi-res). The hash identifies the exact
    // file; the /v5/url `quality` param is only a hint. Sending an SQ hash
    // with quality=128 asks the server to authorize a VIP-only lossless file
    // at a 128k tier — Kugou rejects that with error_code 20006.
    //
    // So prefer the universally-playable STANDARD hash first. Only fall back
    // to higher tiers when no standard hash exists. This matches the playback
    // coordinator's default (standard = 128k) and avoids silently picking a
    // VIP-only file for a free account.
    final standardCandidates = <String>[
      _stringValue(map['FileHash'] ?? map['file_hash']),
      _stringValue(transParam['ogg_128_hash']),
      _stringValue(map['hash_128']),
      _stringValue(map['Hash'] ?? map['hash'] ?? map['HASH']),
    ];
    for (final hash in standardCandidates) {
      if (_isValidHash(hash)) return hash;
    }

    final highTierCandidates = <String>[
      _stringValue(map['SQFileHash']),
      _stringValue(map['HQFileHash']),
      _stringValue(map['ResFileHash']),
      _stringValue(transParam['ogg_320_hash']),
    ];
    for (final hash in highTierCandidates) {
      if (_isValidHash(hash)) return hash;
    }

    for (final item in relateGoods.whereType<Map<Object?, Object?>>()) {
      final relate = _stringMap(item);
      final hash = _stringValue(relate['hash']);
      if (_isValidHash(hash)) return hash;
    }
    return '';
  }

  bool _isValidHash(String value) =>
      RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(value);

  String _artistText(
    Map<String, Object?> map,
    List<Object?> singerInfo,
    String filename,
  ) {
    final direct = _stringValue(
      map['singername'] ??
          map['singer_name'] ??
          map['SingerName'] ??
          map['author_name'] ??
          map['artist'],
    );
    if (direct.isNotEmpty) return direct;
    final names = singerInfo
        .whereType<Map<Object?, Object?>>()
        .map((item) => _stringValue(_stringMap(item)['name']))
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (names.isNotEmpty) return names.join('、');
    return filename;
  }

  String _stringValue(Object? value) => value?.toString().trim() ?? '';

  String? _emptyToNull(String value) => value.isEmpty ? null : value;

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Duration _durationValue(Object? value) {
    final duration = _intValue(value) ?? 0;
    if (duration > 10000) {
      return Duration(milliseconds: duration);
    }
    return Duration(seconds: duration);
  }

  DateTime? _dateValue(Object? value) {
    final number = _intValue(value);
    if (number != null && number > 0) {
      return DateTime.fromMillisecondsSinceEpoch(
        number > 1000000000000 ? number : number * 1000,
        isUtc: true,
      );
    }
    final text = _stringValue(value);
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  Uri? _uriValue(String value) {
    if (value.isEmpty) return null;
    return Uri.tryParse(value.replaceAll('{size}', '400'));
  }

  List<String> _artistsFromText(String text) {
    final normalized = text.contains(' - ') ? text.split(' - ').first : text;
    final artists = normalized
        .split(RegExp(r'[、,&/]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return artists.isEmpty ? const ['未知歌手'] : artists;
  }

  String _titleFromFilename(String text) {
    final trimmed = text.trim();
    if (trimmed.contains(' - ')) {
      return trimmed.split(' - ').skip(1).join(' - ').trim();
    }
    return trimmed.isEmpty ? '未知歌曲' : trimmed;
  }

  String _stripAudioExtension(String text) {
    return text.replaceFirst(
      RegExp(r'\.(mp3|flac|m4a|wav|ape|ogg)$', caseSensitive: false),
      '',
    );
  }
}
