import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:provider_contract/provider_contract.dart';

final neteaseProviderId = ProviderId('netease_cloud_music');

final class NeteaseCredentials {
  const NeteaseCredentials({
    required this.cookie,
    this.userId,
  });

  final String cookie;
  final String? userId;

  bool get hasCookie => cookie.trim().isNotEmpty;
}

enum NeteaseQrLoginStatus { waiting, scanned, authorized, expired }

final class NeteaseQrLoginSession {
  const NeteaseQrLoginSession({
    required this.key,
    required this.loginUri,
    required this.expiresAt,
  });

  final String key;
  final Uri loginUri;
  final DateTime expiresAt;
}

final class NeteaseQrLoginResult {
  const NeteaseQrLoginResult({
    required this.status,
    this.credentials,
    this.message,
  });

  final NeteaseQrLoginStatus status;
  final NeteaseCredentials? credentials;
  final String? message;
}

final class NeteaseMusicProvider implements MusicProvider {
  NeteaseMusicProvider({
    NeteaseCredentials? credentials,
    http.Client? client,
    Uri? baseUri,
    Uri? qrBaseUri,
    DateTime Function()? now,
  })  : _credentials = credentials,
        _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse('https://music.163.com'),
        _qrBaseUri = qrBaseUri ?? Uri.parse('https://interface.music.163.com'),
        _now = now ?? DateTime.now {
    descriptor = ProviderDescriptor(
      id: neteaseProviderId,
      displayName: '网易云音乐',
      capabilities: {
        ProviderCapability.search,
        ProviderCapability.artwork,
        ProviderCapability.resolvePlayback,
        ProviderCapability.resolveDownload,
        ProviderCapability.lyrics,
        ProviderCapability.readCharts,
        if (credentials?.hasCookie ?? false) ...{
          ProviderCapability.authenticate,
          ProviderCapability.readFavorites,
          ProviderCapability.writeFavorites,
          ProviderCapability.readUserPlaylists,
          ProviderCapability.readDailyRecommendations,
        },
      },
      status: ProviderStatus.experimental,
      shortDescription:
          'Experimental real NetEase adapter; account reads require a local session cookie.',
    );
  }

  final NeteaseCredentials? _credentials;
  final http.Client _client;
  final Uri _baseUri;
  final Uri _qrBaseUri;
  final DateTime Function() _now;

  @override
  late final ProviderDescriptor descriptor;

  @override
  bool get isAuthenticated => _credentials?.hasCookie ?? false;

  Future<NeteaseQrLoginSession> createQrLoginSession() async {
    final keyPayload = await _postQrJson(
      _qrBaseUri.replace(path: '/api/login/qrcode/unikey'),
      {'type': '3'},
    );
    final key = keyPayload['unikey']?.toString();
    if (key == null || key.isEmpty) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase QR login key was not returned.',
      );
    }
    return NeteaseQrLoginSession(
      key: key,
      loginUri: _baseUri.replace(
        path: '/login',
        queryParameters: {'codekey': key},
      ),
      expiresAt: _now().add(const Duration(minutes: 5)),
    );
  }

  Future<NeteaseQrLoginResult> checkQrLoginSession(
    NeteaseQrLoginSession session,
  ) async {
    final response = await _client.post(
      _qrBaseUri.replace(path: '/api/login/qrcode/client/login'),
      headers: _qrHeaders(),
      body: {
        'key': session.key,
        'type': '3',
      },
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase QR check failed with HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, Object?>) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase QR check response was not a JSON object.',
      );
    }
    final code = (decoded['code'] as num?)?.toInt();
    final message = decoded['message']?.toString();
    return switch (code) {
      800 => NeteaseQrLoginResult(
          status: NeteaseQrLoginStatus.expired,
          message: message,
        ),
      801 => NeteaseQrLoginResult(
          status: NeteaseQrLoginStatus.waiting,
          message: message,
        ),
      802 => NeteaseQrLoginResult(
          status: NeteaseQrLoginStatus.scanned,
          message: message,
        ),
      803 => NeteaseQrLoginResult(
          status: NeteaseQrLoginStatus.authorized,
          credentials: NeteaseCredentials(
            cookie: decoded['cookie']?.toString().trim().isNotEmpty == true
                ? decoded['cookie'].toString().trim()
                : _cookieFromResponse(response),
            userId: _userIdFromCookies(response.headers['set-cookie']),
          ),
          message: message,
        ),
      _ => throw ProviderException(
          providerId: descriptor.id,
          message: 'Unexpected NetEase QR login code: $code.',
        ),
    };
  }

  @override
  Future<ProviderAccountProfile?> getProfile() async {
    _requireCapability(ProviderCapability.authenticate);
    final payload = await _getJson(
      '/api/nuser/account/get',
      authenticated: true,
    );
    final profile = _jsonMap(payload['profile']);
    final userId = profile['userId']?.toString();
    if (userId == null || userId.isEmpty) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: 'NetEase account profile was not returned.',
      );
    }
    return ProviderAccountProfile(
      accountId: userId,
      displayName: profile['nickname']?.toString() ?? 'NetEase User',
      avatarUrl: _optionalUri(profile['avatarUrl']),
    );
  }

  @override
  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false}) async {
    _requireCapability(ProviderCapability.readFavorites);
    final userId = _credentials?.userId ?? (await getProfile())?.accountId;
    if (userId == null || userId.isEmpty) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: 'NetEase user id is required to read liked songs.',
      );
    }

    // 1. Fetch user's playlists to locate the "Liked Music" playlist ID (always the first one)
    final playlistsPayload = await _getJson(
      '/api/user/playlist',
      query: {
        'uid': userId,
        'limit': '1',
      },
      authenticated: true,
    );
    final playlists =
        playlistsPayload['playlist'] as List<Object?>? ?? const [];
    if (playlists.isEmpty) {
      throw Exception('Failed to locate NetEase user liked music playlist.');
    }
    final firstPlaylist = playlists.first as Map<Object?, Object?>;
    final playlistId = firstPlaylist['id'];

    // 2. Fetch the playlist details to retrieve complete track IDs and "at" timestamps
    final detailPayload = await _getJson(
      '/api/v6/playlist/detail',
      query: {
        'id': playlistId.toString(),
        'n':
            '0', // Minimal chunk tracks returned, we use trackIds for full listing
      },
      authenticated: true,
    );
    final playlistObj = detailPayload['playlist'] as Map<Object?, Object?>?;
    if (playlistObj == null) {
      throw Exception('Failed to load NetEase liked music playlist details.');
    }
    final trackIdsObj = playlistObj['trackIds'] as List<Object?>? ?? const [];

    final idToAt = <String, int>{};
    final ids = <String>[];
    for (final item in trackIdsObj) {
      if (item is Map<Object?, Object?>) {
        final idStr = item['id'].toString();
        final atVal = item['at'] as int? ?? 0;
        ids.add(idStr);
        idToAt[idStr] = atVal;
      }
    }

    // 3. Fetch song details in chunks of 200, attach liked timestamps
    final tracks = <SourceTrack>[];
    for (final chunk in _chunks(ids, 200)) {
      tracks.addAll(
        (await _songDetails(chunk, favoritedIds: ids.toSet())).map((track) {
          final at = idToAt[track.ref.trackId];
          if (at != null && at > 0) {
            // at is in milliseconds (≥1e12) or seconds (<1e12); auto-detect.
            final likedAt = at > 1000000000000
                ? DateTime.fromMillisecondsSinceEpoch(at, isUtc: true)
                : DateTime.fromMillisecondsSinceEpoch(at * 1000, isUtc: true);
            return track.copyWith(
              likedAt: likedAt,
              likedAtSource: 'netease_raw',
              likedAtPrecision: 'exact',
            );
          }
          return track;
        }),
      );
    }

    // 4. Sort descending by the liked timestamp "at" (newest first)
    tracks.sort((a, b) {
      final atA = idToAt[a.ref.trackId] ?? 0;
      final atB = idToAt[b.ref.trackId] ?? 0;
      return atB.compareTo(atA);
    });

    return FavoriteSnapshot(providerId: descriptor.id, tracks: tracks);
  }

  @override
  Future<List<SourceTrack>> search(String query) async {
    _requireCapability(ProviderCapability.search);
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final payload = await _getJson(
      '/api/search/get/web',
      query: {
        's': normalized,
        'type': '1',
        'limit': '30',
        'offset': '0',
      },
    );
    final result = _jsonMap(payload['result']);
    final songs = result['songs'] as List<Object?>? ?? const [];
    final initialTracks = songs
        .whereType<Map<Object?, Object?>>()
        .map((song) => _trackFromSong(_stringMap(song)))
        .toList(growable: false);
    final ids = [
      for (final track in initialTracks)
        if (track.ref.trackId.isNotEmpty) track.ref.trackId,
    ];
    if (ids.isEmpty) {
      return initialTracks;
    }
    try {
      final detailed = <SourceTrack>[];
      for (final chunk in _chunks(ids, 200)) {
        detailed.addAll(await _songDetails(chunk, favoritedIds: const {}));
      }
      return detailed.isEmpty ? initialTracks : detailed;
    } catch (_) {
      return initialTracks;
    }
  }

  @override
  Future<void> setFavorite({
    required ProviderTrackRef track,
    required bool liked,
  }) async {
    _requireCapability(ProviderCapability.writeFavorites);
    await _getJson(
      '/api/song/like',
      query: {
        'trackId': track.trackId,
        'like': liked.toString(),
        'time': '30000',
      },
      authenticated: true,
    );
  }

  @override
  Future<List<SourceTrack>> getDailyRecommendations() async {
    _requireCapability(ProviderCapability.readDailyRecommendations);
    final payload = await _getJson(
      '/api/v1/discovery/recommend/songs',
      authenticated: true,
    );
    final data = _jsonMap(payload['data']);
    final dailySongs = data['dailySongs'] as List<Object?>? ?? const [];
    return dailySongs
        .whereType<Map<Object?, Object?>>()
        .map((song) => _trackFromSong(_stringMap(song)))
        .toList(growable: false);
  }

  @override
  Future<List<ProviderPlaylist>> getRecommendedPlaylists({
    int limit = 12,
  }) async {
    _requireCapability(ProviderCapability.readDailyRecommendations);
    final boundedLimit = limit.clamp(1, 50).toInt();
    try {
      final payload = await _getJson(
        '/api/v1/discovery/recommend/resource',
        authenticated: true,
      );
      final recommended = payload['recommend'] as List<Object?>? ?? const [];
      final playlists = recommended
          .whereType<Map<Object?, Object?>>()
          .map((item) => _playlistFromPayload(_stringMap(item)))
          .where((playlist) => playlist.playlistId.isNotEmpty)
          .take(boundedLimit)
          .toList(growable: false);
      if (playlists.isNotEmpty) {
        return playlists;
      }
    } on ProviderException {
      // Fall back to the public personalized endpoint below.
    }

    final payload = await _getJson(
      '/api/personalized/playlist',
      query: {'limit': boundedLimit.toString()},
    );
    final result = payload['result'] as List<Object?>? ?? const [];
    return result
        .whereType<Map<Object?, Object?>>()
        .map((item) => _playlistFromPayload(_stringMap(item)))
        .where((playlist) => playlist.playlistId.isNotEmpty)
        .take(boundedLimit)
        .toList(growable: false);
  }

  @override
  Future<List<ProviderPlaylist>> getChartPlaylists({
    int limit = 20,
  }) async {
    _requireCapability(ProviderCapability.readCharts);
    final boundedLimit = limit.clamp(1, 50).toInt();
    final payload = await _getJson('/api/toplist/detail');
    final charts = payload['list'] as List<Object?>? ?? const [];
    return charts
        .whereType<Map<Object?, Object?>>()
        .map((item) => _chartFromPayload(_stringMap(item)))
        .where((playlist) => playlist.playlistId != 'chart:')
        .take(boundedLimit)
        .toList(growable: false);
  }

  @override
  Future<List<ProviderPlaylist>> getUserPlaylists() async {
    _requireCapability(ProviderCapability.readUserPlaylists);
    final userId = _credentials?.userId ?? (await getProfile())?.accountId;
    if (userId == null || userId.isEmpty) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: 'NetEase user id is required to read playlists.',
      );
    }
    final payload = await _getJson(
      '/api/user/playlist',
      query: {
        'uid': userId,
        'limit': '1000',
        'offset': '0',
      },
      authenticated: true,
    );
    final playlists = payload['playlist'] as List<Object?>? ?? const [];
    return playlists
        .whereType<Map<Object?, Object?>>()
        .map((item) => _playlistFromPayload(_stringMap(item)))
        .toList(growable: false);
  }

  @override
  Future<List<SourceTrack>> getPlaylistTracks(String playlistId) async {
    final normalizedId = playlistId.trim();
    final isChart = normalizedId.startsWith('chart:');
    _requireCapability(
      isChart
          ? ProviderCapability.readCharts
          : ProviderCapability.readUserPlaylists,
    );
    final detailPayload = await _getJson(
      '/api/v6/playlist/detail',
      query: {
        'id': isChart ? normalizedId.substring('chart:'.length) : normalizedId,
        'n': '0',
      },
      authenticated: !isChart,
    );
    final playlistObj = detailPayload['playlist'] as Map<Object?, Object?>?;
    if (playlistObj == null) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'Failed to load NetEase playlist details.',
      );
    }
    final trackIdsObj = playlistObj['trackIds'] as List<Object?>? ?? const [];
    final ids = <String>[
      for (final item in trackIdsObj)
        if (item is Map<Object?, Object?>) item['id'].toString(),
    ];
    final tracks = <SourceTrack>[];
    for (final chunk in _chunks(ids, 200)) {
      tracks.addAll(await _songDetails(chunk, favoritedIds: const {}));
    }
    return tracks;
  }

  @override
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _requireCapability(ProviderCapability.resolvePlayback);
    final resolved = await _resolvePlayerUrl(track.trackId, quality);
    final playUri = resolved?.url != null
        ? Uri.parse(resolved!.url).replace(scheme: 'https')
        : Uri.parse(
            'https://music.163.com/song/media/outer/url?id=${track.trackId}.mp3');
    return PlaybackTicket(
      mediaUri: playUri,
      headers: _headers(authenticated: isAuthenticated),
      expiresAt: _now().add(const Duration(hours: 2)),
      trackRef: track,
      quality: quality,
    );
  }

  @override
  Future<DownloadTicket> createDownloadTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _requireCapability(ProviderCapability.resolveDownload);
    final resolved = await _resolvePlayerUrl(track.trackId, quality);
    final downloadUri = resolved?.url != null
        ? Uri.parse(resolved!.url).replace(scheme: 'https')
        : Uri.parse(
            'https://music.163.com/song/media/outer/url?id=${track.trackId}.mp3');
    return DownloadTicket(
      mediaUri: downloadUri,
      headers: _headers(authenticated: isAuthenticated),
      expiresAt: _now().add(const Duration(hours: 12)),
      trackRef: track,
      quality: quality,
      fileExtension: resolved?.fileExtension ?? 'mp3',
      bytes: resolved?.bytes,
    );
  }

  Future<_ResolvedMedia?> _resolvePlayerUrl(
    String songId,
    AudioQuality quality,
  ) async {
    try {
      final level = _qualityLevel(quality);
      final payload = await _getJson(
        '/api/song/enhance/player/url/v1',
        query: {
          'ids': '[$songId]',
          'level': level,
          'encodeType': level == 'lossless' ? 'flac' : 'mp3',
        },
        authenticated: isAuthenticated,
      );
      final data = payload['data'] as List<Object?>? ?? const [];
      if (data.isNotEmpty) {
        final item = data.first as Map<Object?, Object?>?;
        if (item != null) {
          final url = item['url'] as String?;
          if (url != null && url.isNotEmpty) {
            return _ResolvedMedia(
              url: url,
              fileExtension:
                  _fileExtensionFor(item['type'] ?? item['encodeType']),
              bytes: (item['size'] as num?)?.toInt(),
            );
          }
        }
      }
    } catch (_) {}

    try {
      final payload = await _getJson(
        '/api/song/enhance/player/url',
        query: {
          'id': songId,
          'ids': '[$songId]',
          'br': _legacyBitrate(quality).toString(),
        },
        authenticated: isAuthenticated,
      );
      final data = payload['data'] as List<Object?>? ?? const [];
      if (data.isNotEmpty) {
        final item = data.first as Map<Object?, Object?>?;
        if (item != null) {
          final url = item['url'] as String?;
          if (url != null && url.isNotEmpty) {
            return _ResolvedMedia(
              url: url,
              fileExtension: _fileExtensionFor(item['type']),
              bytes: (item['size'] as num?)?.toInt(),
            );
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<String?> getLyrics(ProviderTrackRef track) async {
    _requireCapability(ProviderCapability.lyrics);
    final payload = await _getJson(
      '/api/song/lyric',
      query: {
        'id': track.trackId,
        'lv': '-1',
        'tv': '-1',
        'kv': '-1',
      },
      authenticated: false,
    );
    final lrc = _jsonMap(payload['lrc']);
    return lrc['lyric']?.toString();
  }

  Future<List<SourceTrack>> _songDetails(
    List<String> ids, {
    required Set<String> favoritedIds,
  }) async {
    if (ids.isEmpty) {
      return const [];
    }
    final payload = await _getJson(
      '/api/song/detail/',
      query: {
        'id': ids.first,
        'ids': '[${ids.join(',')}]',
      },
      authenticated: isAuthenticated,
    );
    final songs = payload['songs'] as List<Object?>? ?? const [];
    return songs
        .whereType<Map<Object?, Object?>>()
        .map((song) => _trackFromSong(_stringMap(song), favoritedIds))
        .toList(growable: false);
  }

  SourceTrack _trackFromSong(
    Map<String, Object?> song, [
    Set<String> favoritedIds = const {},
  ]) {
    final id = song['id']?.toString() ?? '';
    final album = _jsonMap(song['album'] ?? song['al']);
    final artists =
        (song['artists'] ?? song['ar']) as List<Object?>? ?? const [];
    final fee = song['fee'] as num?;
    final status = song['status'] as num?;

    return SourceTrack(
      ref: ProviderTrackRef(
        providerId: descriptor.id,
        trackId: id,
        extraIds: {
          if (album['id'] != null) 'album_id': album['id'].toString(),
        },
      ),
      title: song['name']?.toString() ?? 'Untitled',
      artists: artists
          .whereType<Map<Object?, Object?>>()
          .map((artist) => artist['name']?.toString() ?? '')
          .where((artist) => artist.isNotEmpty)
          .toList(growable: false),
      album: album['name']?.toString(),
      duration: Duration(
          milliseconds:
              (song['duration'] as num? ?? song['dt'] as num?)?.toInt() ?? 0),
      isFavorited: favoritedIds.contains(id) || song['starred'] == true,
      artwork: _optionalUri(album['picUrl'] ?? album['blurPicUrl']),
      isPlayable: status == null || status == 0,
      isDownloadable: true,
      isrc: song['isrc']?.toString(),
    ).copyWith(
      isPlayable: (status == null || status == 0) && fee != 4,
    );
  }

  ProviderPlaylist _playlistFromPayload(Map<String, Object?> item) {
    final creator = _jsonMap(item['creator']);
    return ProviderPlaylist(
      providerId: descriptor.id,
      playlistId: item['id']?.toString() ?? '',
      name: item['name']?.toString() ?? 'NetEase Playlist',
      description:
          item['description']?.toString() ?? item['copywriter']?.toString(),
      creatorName: creator['nickname']?.toString(),
      cover: _optionalUri(item['coverImgUrl'] ?? item['picUrl']),
      trackCount: (item['trackCount'] as num?)?.toInt() ?? 0,
      playCount:
          (item['playCount'] as num? ?? item['playcount'] as num?)?.toInt(),
    );
  }

  ProviderPlaylist _chartFromPayload(Map<String, Object?> item) {
    final id = item['id']?.toString() ?? '';
    return ProviderPlaylist(
      providerId: descriptor.id,
      playlistId: 'chart:$id',
      name: item['name']?.toString() ?? 'NetEase Chart',
      description: item['updateFrequency']?.toString(),
      creatorName: '网易云音乐',
      cover: _optionalUri(item['coverImgUrl'] ?? item['picUrl']),
      trackCount: (item['trackCount'] as num?)?.toInt() ?? 0,
      playCount: (item['playCount'] as num?)?.toInt(),
    );
  }

  int _legacyBitrate(AudioQuality quality) => switch (quality) {
        AudioQuality.low => 128000,
        AudioQuality.standard => 192000,
        AudioQuality.high => 320000,
        AudioQuality.lossless => 999000,
      };

  String _qualityLevel(AudioQuality quality) => switch (quality) {
        AudioQuality.low => 'standard',
        AudioQuality.standard => 'higher',
        AudioQuality.high => 'exhigh',
        AudioQuality.lossless => 'lossless',
      };

  String? _fileExtensionFor(Object? value) {
    final text = value?.toString().toLowerCase();
    if (text == null || text.isEmpty) return null;
    if (text.contains('flac')) return 'flac';
    if (text.contains('mp4') || text.contains('m4a')) return 'm4a';
    return 'mp3';
  }

  Future<Map<String, Object?>> _getJson(
    String path, {
    Map<String, String> query = const {},
    bool authenticated = false,
  }) async {
    final uri = _baseUri.replace(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    );
    final response = await _client
        .get(
          uri,
          headers: _headers(authenticated: authenticated),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: 'NetEase session is not authorized.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase request failed with HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase response was not a JSON object.',
      );
    }
    final code = decoded['code'];
    if (code is num && code != 200) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase response code ${code.toInt()}.',
      );
    }
    return decoded;
  }

  Future<Map<String, Object?>> _postQrJson(
    Uri uri,
    Map<String, String> form,
  ) async {
    final response = await _client
        .post(uri, headers: _qrHeaders(), body: form)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase QR request failed with HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<Object?, Object?>) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase QR response was not a JSON object.',
      );
    }
    final payload = _stringMap(decoded);
    final code = payload['code'];
    if (code is num && code != 200) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase QR response code ${code.toInt()}.',
      );
    }
    return payload;
  }

  Map<String, String> _headers({required bool authenticated}) {
    final headers = {
      'Accept': 'application/json, text/plain, */*',
      'Referer': _baseUri.toString(),
      'User-Agent':
          'Mozilla/5.0 MeloUnion/${_now().toUtc().year} Provider Spike',
    };
    if (authenticated) {
      final cookie = _credentials?.cookie.trim();
      if (cookie == null || cookie.isEmpty) {
        throw AuthenticationRequiredException(
          providerId: descriptor.id,
          message: 'NetEase session cookie is required.',
        );
      }
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  Map<String, String> _qrHeaders() {
    return const {
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Referer': 'https://music.163.com/',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Safari/537.36 Chrome/91.0.4472.164 NeteaseMusicDesktop/3.0.18.203152',
    };
  }

  String _cookieFromResponse(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.trim().isEmpty) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'NetEase QR login succeeded but no cookie was returned.',
      );
    }
    final parts = setCookie
        .split(',')
        .map((part) => part.split(';').first.trim())
        .where((part) => part.contains('='))
        .toList(growable: false);
    return parts.join('; ');
  }

  String? _userIdFromCookies(String? setCookie) {
    if (setCookie == null) return null;
    final match = RegExp(r'MUSIC_U=([^;,]+)').firstMatch(setCookie);
    return match?.group(1);
  }

  void _requireCapability(ProviderCapability capability) {
    if (!descriptor.supports(capability)) {
      _unsupported(capability);
    }
  }

  Never _unsupported(ProviderCapability capability) {
    throw CapabilityUnavailableException(
      providerId: descriptor.id,
      capability: capability,
      message:
          'NetEase ${capability.name} is not declared until the real flow is verified.',
    );
  }

  Map<String, Object?> _jsonMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return _stringMap(value);
    }
    return const {};
  }

  Map<String, Object?> _stringMap(Map<Object?, Object?> value) {
    return {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
  }

  Uri? _optionalUri(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    return Uri.tryParse(text);
  }

  Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
    for (var index = 0; index < values.length; index += size) {
      yield values.sublist(
        index,
        index + size > values.length ? values.length : index + size,
      );
    }
  }
}

final class _ResolvedMedia {
  const _ResolvedMedia({
    required this.url,
    this.fileExtension,
    this.bytes,
  });

  final String url;
  final String? fileExtension;
  final int? bytes;
}
