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
      final response = await _client.get(
        Uri.parse('https://songsearch.kugou.com/song_search_v2').replace(
          queryParameters: {
            'keyword': query,
            'page': page.toString(),
            'pagesize': pageSize.toString(),
            'platform': 'WebFilter',
          },
        ),
      );
      final data = _jsonMap(response['data']);
      final list = data['lists'] as List<dynamic>? ?? const [];
      return list
          .whereType<Map<Object?, Object?>>()
          .map((item) => _trackFromMap(_stringMap(item)))
          .where((track) => track.hash.isNotEmpty)
          .toList(growable: false);
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
    final hash = _stringValue(
      map['FileHash'] ??
          map['HQFileHash'] ??
          map['hash'] ??
          map['HASH'] ??
          map['hash_128'],
    );
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
      album: _stringValue(map['AlbumName'] ?? map['album_name']),
      albumId: albumId.isEmpty ? null : albumId,
      albumAudioId: albumAudioId.isEmpty ? null : albumAudioId,
      mixSongId: _emptyToNull(_stringValue(map['MixSongID'])),
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

  String _stringValue(Object? value) => value?.toString() ?? '';

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
