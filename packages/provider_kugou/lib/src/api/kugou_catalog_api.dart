import 'dart:convert';

import '../model/kugou_remote_playlist.dart';
import '../model/kugou_remote_track.dart';
import 'kugou_api_client.dart';

final class KugouCatalogApi {
  KugouCatalogApi({required KugouApiClient client}) : _client = client;

  final KugouApiClient _client;

  Future<List<KugouRemoteTrack>> search(
    String query, {
    int page = 1,
    int pageSize = 30,
  }) async {
    if (query.trim().isEmpty) return const [];

    try {
      Future<List<KugouRemoteTrack>> fetch({required bool withCookie}) async {
        final response = await _client.get(
          Uri.parse('http://songsearch.kugou.com/song_search_v2').replace(
            queryParameters: {
              'keyword': query,
              'platform': 'WebFilter',
              'format': 'json',
              'page': page.toString(),
              'pagesize': pageSize.toString(),
              'userid': '-1',
              'clientver': '',
              'tag': 'em',
              'filter': '2',
              'iscorrection': '1',
              'privilege_filter': '0',
              '_': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          ),
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.162 Mobile Safari/537.36',
          },
          attachSessionCookie: withCookie,
        );
        final data = _jsonMap(response['data']);
        final list = data['lists'] as List<dynamic>? ?? const [];
        return list
            .whereType<Map<Object?, Object?>>()
            .map((item) => _trackFromMap(_stringMap(item)))
            .where((track) => track.hash.isNotEmpty)
            .toList(growable: false);
      }

      final withCookie = await fetch(withCookie: true);
      if (withCookie.isNotEmpty) return withCookie;
      return fetch(withCookie: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<KugouRemoteTrack>> getDailyRecommendations() async {
    try {
      final response = await _client.get(
        Uri.parse('https://m.kugou.com/').replace(
          queryParameters: {'json': 'true'},
        ),
      );
      final list = response['data'] as List<dynamic>? ?? const [];
      return list
          .whereType<Map<Object?, Object?>>()
          .map((item) => _trackFromMap(_stringMap(item)))
          .where((track) => track.hash.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<KugouRemotePlaylist>> getRecommendedPlaylists({
    int limit = 12,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('https://m.kugou.com/plist/index&json=true'),
      );
      final plist = _jsonMap(response['plist']);
      final list = _jsonMap(plist['list']);
      final info = list['info'] as List<dynamic>? ?? const [];
      return info
          .whereType<Map<Object?, Object?>>()
          .map((item) {
            final map = _stringMap(item);
            final id = map['specialid']?.toString() ?? '';
            return KugouRemotePlaylist(
              playlistId: 'plist:$id',
              name: map['specialname']?.toString() ?? '酷狗精选歌单',
              creatorName: map['username']?.toString(),
              cover: _imageUri(
                map['img']?.toString() ??
                    map['suid_pic']?.toString() ??
                    map['imgurl']?.toString(),
              ),
              trackCount: _intValue(map['songcount']) ?? 0,
              playCount: _intValue(map['playcount']),
            );
          })
          .where((playlist) => playlist.playlistId != 'plist:')
          .take(limit)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<KugouRemotePlaylist>> getChartPlaylists({int limit = 20}) async {
    try {
      final response = await _client.get(
        Uri.parse('https://m.kugou.com/rank/list&json=true'),
      );
      final rank = _jsonMap(response['rank']);
      final list = rank['list'] as List<dynamic>? ?? const [];
      return list
          .whereType<Map<Object?, Object?>>()
          .map((item) {
            final map = _stringMap(item);
            final id = map['rankid']?.toString() ?? '';
            return KugouRemotePlaylist(
              playlistId: 'rank:$id',
              name: map['rankname']?.toString() ?? '酷狗榜单',
              cover: _imageUri(
                map['img_9']?.toString() ??
                    map['album_img_9']?.toString() ??
                    map['banner_9']?.toString(),
              ),
              playCount: _intValue(map['play_times']),
            );
          })
          .where((playlist) => playlist.playlistId != 'rank:')
          .take(limit)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<KugouRemoteTrack>> getChartTracks(String rankId) async {
    if (rankId.trim().isEmpty) return const [];

    try {
      final response = await _client.get(
        Uri.parse('https://m.kugou.com/rank/info/').replace(
          queryParameters: {
            'rankid': rankId,
            'page': '1',
            'json': 'true',
          },
        ),
      );
      final songs = _jsonMap(response['songs']);
      final list = songs['list'] as List<dynamic>? ?? const [];
      return list
          .whereType<Map<Object?, Object?>>()
          .map((item) => _trackFromMap(_stringMap(item)))
          .where((track) => track.hash.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<KugouRemoteTrack>> getRecommendedPlaylistTracks(
    String specialId,
  ) async {
    if (specialId.trim().isEmpty) return const [];

    try {
      final html = await _client.getText(
        Uri.parse('https://m.kugou.com/plist/list/$specialId&json=true'),
      );
      final dataJson = _extractJavaScriptArray(html, 'var data=');
      if (dataJson == null) return const [];
      final decoded = jsonDecode(dataJson);
      if (decoded is! List<dynamic>) return const [];

      return decoded
          .whereType<Map<Object?, Object?>>()
          .map((item) => _trackFromMap(_stringMap(item)))
          .where((track) => track.hash.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  KugouRemoteTrack _trackFromMap(Map<String, Object?> map) {
    final transParam = _jsonMap(map['trans_param']);
    final relateGoods = _listValue(map['relate_goods']);
    final hash = _bestPlayableHash(map, transParam, relateGoods);
    final rawHash = _stringValue(map['Hash'] ?? map['hash'] ?? map['HASH']);
    final title = _stringValue(
      map['SongName'] ??
          map['songname'] ??
          map['audio_name'] ??
          map['song_name'] ??
          map['filename'],
    );
    final rawArtists = _stringValue(
      map['SingerName'] ??
          map['singername'] ??
          map['author_name'] ??
          map['singer_name'] ??
          map['filename'],
    );
    final albumId = _stringValue(map['AlbumID'] ?? map['album_id']);
    final albumAudioId = _stringValue(
      map['AlbumAudioID'] ?? map['album_audio_id'] ?? map['audio_id'],
    );
    final fileHash = _firstValidHash([
      _stringValue(map['FileHash'] ?? map['file_hash']),
      _relateGoodsHash(relateGoods, (bitrate) => bitrate > 0 && bitrate < 320),
      _stringValue(map['origin_hash'] ?? map['hash_128'] ?? map['hash']),
    ]);
    final sqHash = _firstValidHash([
      _stringValue(map['SQFileHash'] ?? map['sqhash'] ?? map['sq_hash']),
      _relateGoodsHash(relateGoods, (bitrate) => bitrate >= 700),
    ]);
    final hqHash = _firstValidHash([
      _stringValue(map['HQFileHash'] ?? map['320hash'] ?? map['hq_hash']),
      _relateGoodsHash(
          relateGoods, (bitrate) => bitrate >= 320 && bitrate < 700),
    ]);
    final resHash = _stringValue(
      map['ResFileHash'] ?? map['res_hash'],
    );
    final ogg320Hash = _stringValue(
      transParam['ogg_320_hash'] ?? map['ogg_320_hash'],
    );
    final ogg128Hash = _stringValue(
      transParam['ogg_128_hash'] ?? map['ogg_128_hash'],
    );
    final privilege = _intValue(map['Privilege'] ?? map['privilege']);

    return KugouRemoteTrack(
      hash: hash,
      title: _titleFromFilename(title),
      artists: _artistsFromText(rawArtists),
      duration: _durationValue(
        map['Duration'] ??
            map['FileDuration'] ??
            map['duration'] ??
            map['timelength'],
      ),
      rawHash: _emptyToNull(rawHash),
      album: _stringValue(map['AlbumName'] ?? map['album_name']),
      albumId: albumId.isEmpty ? null : albumId,
      albumAudioId: albumAudioId.isEmpty ? null : albumAudioId,
      mixSongId: _emptyToNull(_stringValue(map['MixSongID'])),
      fileHash: _emptyToNull(fileHash),
      sqHash: _emptyToNull(sqHash),
      hqHash: _emptyToNull(hqHash),
      resHash: _emptyToNull(resHash),
      ogg320Hash: _emptyToNull(ogg320Hash),
      ogg128Hash: _emptyToNull(ogg128Hash),
      explicitlyBlocked: privilege == 0,
      artwork: _imageUri(
        _stringValue(
          map['AlbumCover'] ??
              map['imgUrl'] ??
              map['image'] ??
              _jsonMap(map['trans_param'])['union_cover'],
        ),
      ),
    );
  }

  Map<String, Object?> _jsonMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map<Object?, Object?>) return _stringMap(value);
    return const {};
  }

  Map<String, Object?> _stringMap(Map<Object?, Object?> value) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  String _bestPlayableHash(
    Map<String, Object?> map,
    Map<String, Object?> transParam,
    List<Object?> relateGoods,
  ) {
    final standardCandidates = <String>[
      _stringValue(map['FileHash'] ?? map['file_hash']),
      _relateGoodsHash(relateGoods, (bitrate) => bitrate > 0 && bitrate < 320),
      _stringValue(transParam['ogg_128_hash'] ?? map['ogg_128_hash']),
      _stringValue(map['hash_128']),
      _stringValue(map['Hash'] ?? map['hash'] ?? map['HASH']),
    ];
    for (final hash in standardCandidates) {
      if (_isValidHash(hash)) return hash;
    }

    final highTierCandidates = <String>[
      _stringValue(map['SQFileHash'] ?? map['sqhash'] ?? map['sq_hash']),
      _stringValue(map['HQFileHash'] ?? map['320hash'] ?? map['hq_hash']),
      _stringValue(map['ResFileHash'] ?? map['res_hash']),
      _stringValue(transParam['ogg_320_hash'] ?? map['ogg_320_hash']),
    ];
    for (final hash in highTierCandidates) {
      if (_isValidHash(hash)) return hash;
    }
    for (final item in relateGoods.whereType<Map<Object?, Object?>>()) {
      final relate = _stringMap(item);
      final hash = _stringValue(relate['hash']);
      if (_isValidHash(hash)) return hash;
    }
    return _stringValue(map['Hash'] ?? map['hash'] ?? map['HASH']);
  }

  bool _isValidHash(String value) {
    return RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(value) &&
        value != '00000000000000000000000000000000';
  }

  String _stringValue(Object? value) => value?.toString() ?? '';

  List<Object?> _listValue(Object? value) =>
      value is List ? value.cast<Object?>() : const [];

  String _firstValidHash(List<String> values) {
    for (final value in values) {
      if (_isValidHash(value)) return value;
    }
    return '';
  }

  String _relateGoodsHash(
    List<Object?> relateGoods,
    bool Function(int bitrate) matches,
  ) {
    for (final item in relateGoods.whereType<Map<Object?, Object?>>()) {
      final relate = _stringMap(item);
      final hash = _stringValue(relate['hash']);
      final bitrate = _intValue(relate['bitrate']) ?? 0;
      if (_isValidHash(hash) && matches(bitrate)) return hash;
    }
    return '';
  }

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

  Uri? _imageUri(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final normalized = text.replaceAll('{size}', '400');
    return Uri.tryParse(normalized);
  }

  String? _extractJavaScriptArray(String source, String marker) {
    final start = source.indexOf(marker);
    if (start < 0) return null;

    final arrayStart = source.indexOf('[', start + marker.length);
    if (arrayStart < 0) return null;

    var depth = 0;
    var inString = false;
    var escaping = false;
    for (var index = arrayStart; index < source.length; index++) {
      final char = source.codeUnitAt(index);
      if (inString) {
        if (escaping) {
          escaping = false;
        } else if (char == 0x5c) {
          escaping = true;
        } else if (char == 0x22) {
          inString = false;
        }
        continue;
      }

      if (char == 0x22) {
        inString = true;
      } else if (char == 0x5b) {
        depth++;
      } else if (char == 0x5d) {
        depth--;
        if (depth == 0) {
          return source.substring(arrayStart, index + 1);
        }
      }
    }
    return null;
  }
}
