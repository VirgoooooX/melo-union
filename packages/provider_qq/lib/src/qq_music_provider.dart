import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider_contract/provider_contract.dart';

final qqMusicProviderId = ProviderId('qq_music');

const _qqWechatAppId = 'wx48db31d50e334801';
const _qqWechatRedirectUri =
    'https://y.qq.com/portal/wx_redirect.html?login_type=2&surl=https://y.qq.com/';

enum QqMusicQrLoginMode { qq, wechat }

enum QqMusicQrLoginStatus { waiting, scanned, authorized, expired, failed }

final class QqMusicCredentials {
  const QqMusicCredentials({required this.cookie});

  final String cookie;

  bool get hasCookie => cookie.trim().isNotEmpty;
}

final class QqMusicQrLoginOption {
  const QqMusicQrLoginOption({
    required this.mode,
    required this.label,
  });

  final QqMusicQrLoginMode mode;
  final String label;
}

final class QqMusicQrLoginSession {
  const QqMusicQrLoginSession({
    required this.mode,
    required this.key,
    required this.expiresAt,
    this.loginUri,
    this.imageDataUri,
    this.imageUri,
  });

  final QqMusicQrLoginMode mode;
  final String key;
  final DateTime expiresAt;
  final Uri? loginUri;
  final String? imageDataUri;
  final Uri? imageUri;
}

final class QqMusicQrLoginResult {
  const QqMusicQrLoginResult({
    required this.status,
    this.credentials,
    this.message,
  });

  final QqMusicQrLoginStatus status;
  final QqMusicCredentials? credentials;
  final String? message;
}

final class QqMusicProvider implements MusicProvider {
  QqMusicProvider({
    QqMusicCredentials? credentials,
    http.Client? client,
    Uri? searchBaseUri,
    Uri? musicuUri,
    Uri? lyricBaseUri,
    Uri? qqQrShowUri,
    Uri? qqQrCheckUri,
    Uri? wxQrConnectUri,
    Uri? wxQrCheckUri,
    DateTime Function()? now,
  })  : _credentials = credentials,
        _client = client ?? http.Client(),
        _searchBaseUri = searchBaseUri ?? Uri.parse('https://c.y.qq.com'),
        _musicuUri =
            musicuUri ?? Uri.parse('https://u.y.qq.com/cgi-bin/musicu.fcg'),
        _lyricBaseUri = lyricBaseUri ?? Uri.parse('https://c.y.qq.com'),
        _qqQrShowUri =
            qqQrShowUri ?? Uri.parse('https://ssl.ptlogin2.qq.com/ptqrshow'),
        _qqQrCheckUri =
            qqQrCheckUri ?? Uri.parse('https://ssl.ptlogin2.qq.com/ptqrlogin'),
        _wxQrConnectUri = wxQrConnectUri ??
            Uri.parse('https://open.weixin.qq.com/connect/qrconnect'),
        _wxQrCheckUri = wxQrCheckUri ??
            Uri.parse('https://lp.open.weixin.qq.com/connect/l/qrconnect'),
        _now = now ?? DateTime.now {
    descriptor = ProviderDescriptor(
      id: qqMusicProviderId,
      displayName: 'QQ音乐',
      capabilities: const {
        ProviderCapability.search,
        ProviderCapability.artwork,
        ProviderCapability.resolvePlayback,
        ProviderCapability.resolveDownload,
        ProviderCapability.lyrics,
        ProviderCapability.authenticate,
        ProviderCapability.readFavorites,
        ProviderCapability.writeFavorites,
        ProviderCapability.readUserPlaylists,
        ProviderCapability.readDailyRecommendations,
      },
      status: ProviderStatus.experimental,
      shortDescription:
          'Experimental QQ Music adapter; account QR login is wired at app level and media URLs depend on public availability.',
    );
  }

  final QqMusicCredentials? _credentials;
  final http.Client _client;
  final Uri _searchBaseUri;
  final Uri _musicuUri;
  final Uri _lyricBaseUri;
  final Uri _qqQrShowUri;
  final Uri _qqQrCheckUri;
  final Uri _wxQrConnectUri;
  final Uri _wxQrCheckUri;
  final DateTime Function() _now;

  @override
  late final ProviderDescriptor descriptor;

  @override
  bool get isAuthenticated => _credentials?.hasCookie ?? false;

  List<QqMusicQrLoginOption> qrLoginOptions() => const [
        QqMusicQrLoginOption(mode: QqMusicQrLoginMode.qq, label: 'QQ 扫码'),
        QqMusicQrLoginOption(mode: QqMusicQrLoginMode.wechat, label: '微信扫码'),
      ];

  Future<QqMusicQrLoginSession> createQrLoginSession(
    QqMusicQrLoginMode mode,
  ) {
    return switch (mode) {
      QqMusicQrLoginMode.qq => _createQqQrLoginSession(),
      QqMusicQrLoginMode.wechat => _createWechatQrLoginSession(),
    };
  }

  Future<QqMusicQrLoginResult> checkQrLoginSession(
    QqMusicQrLoginSession session,
  ) {
    return switch (session.mode) {
      QqMusicQrLoginMode.qq => _checkQqQrLoginSession(session),
      QqMusicQrLoginMode.wechat => _checkWechatQrLoginSession(session),
    };
  }

  Future<QqMusicQrLoginSession> _createQqQrLoginSession() async {
    final uri = _qqQrShowUri.replace(queryParameters: {
      'appid': '716027609',
      'e': '2',
      'l': 'M',
      's': '3',
      'd': '72',
      'v': '4',
      't': (_now().microsecondsSinceEpoch / 1000000).toStringAsFixed(17),
      'daid': '383',
      'pt_3rd_aid': '100497308',
    });
    final response = await _client
        .get(uri, headers: _qrHeaders(referer: 'https://y.qq.com/'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ QR image request failed with HTTP ${response.statusCode}.',
      );
    }
    final cookies = Map<String, String>.from(_responseCookies(response));
    final qrsig = cookies['qrsig']?.trim();
    if (qrsig == null || qrsig.isEmpty) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ QR image response did not include qrsig.',
      );
    }
    final key = Uri(queryParameters: {'qrsig': qrsig}).query;
    return QqMusicQrLoginSession(
      mode: QqMusicQrLoginMode.qq,
      key: key,
      imageDataUri: 'data:image/png;base64,${base64Encode(response.bodyBytes)}',
      expiresAt: _now().add(const Duration(minutes: 2)),
    );
  }

  Future<QqMusicQrLoginResult> _checkQqQrLoginSession(
    QqMusicQrLoginSession session,
  ) async {
    final values = Uri.splitQueryString(session.key);
    final qrsig = values['qrsig']?.trim() ?? '';
    if (qrsig.isEmpty) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ QR login key is missing qrsig.',
      );
    }
    final uri = _qqQrCheckUri.replace(queryParameters: {
      'u1': 'https://graph.qq.com/oauth2.0/login_jump',
      'ptqrtoken': _hash33(qrsig).toString(),
      'ptredirect': '100',
      'h': '1',
      't': '1',
      'g': '1',
      'from_ui': '1',
      'ptlang': '2052',
      'action': '0-0-${_now().millisecondsSinceEpoch}',
      'js_ver': '21072115',
      'js_type': '1',
      'login_sig': '',
      'pt_uistyle': '40',
      'aid': '716027609',
      'daid': '383',
      'pt_3rd_aid': '100497308',
      'has_onekey': '1',
      'pttype': '1',
      'service': 'ptqrlogin',
      'nodirect': '0',
    });
    final response = await _client
        .get(
          uri,
          headers: _qrHeaders(
            referer: 'https://xui.ptlogin2.qq.com/',
            cookie: 'qrsig=$qrsig',
          ),
        )
        .timeout(const Duration(seconds: 15));
    final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
    final parsed = _parseQqQrCheck(raw);
    final status = _mapQqQrStatus(parsed.code);
    if (status != QqMusicQrLoginStatus.authorized) {
      return QqMusicQrLoginResult(
        status: status,
        message:
            parsed.message.isEmpty ? _qqStatusLabel(status) : parsed.message,
      );
    }
    final cookies = Map<String, String>.from(_responseCookies(response));
    if (parsed.redirectUri != null) {
      cookies
          .addAll(await _fetchQqRedirectCookies(parsed.redirectUri!, cookies));
    }
    final normalized = _normalizeQqMusicCookies(cookies);
    return QqMusicQrLoginResult(
      status: QqMusicQrLoginStatus.authorized,
      credentials: QqMusicCredentials(cookie: _joinCookies(normalized)),
      message: parsed.message,
    );
  }

  Future<QqMusicQrLoginSession> _createWechatQrLoginSession() async {
    final state = 'melounion-${_now().microsecondsSinceEpoch}';
    final loginUri = _wxQrConnectUri.replace(queryParameters: {
      'appid': _qqWechatAppId,
      'redirect_uri': _qqWechatRedirectUri,
      'response_type': 'code',
      'scope': 'snsapi_login',
      'state': state,
      'href':
          'https://y.qq.com/mediastyle/music_v17/src/css/popup_wechat.css#wechat_redirect',
    });
    final response = await _client
        .get(loginUri, headers: _qrHeaders(referer: 'https://y.qq.com/'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message:
            'QQ WeChat QR page request failed with HTTP ${response.statusCode}.',
      );
    }
    final html = utf8.decode(response.bodyBytes, allowMalformed: true);
    final uuid = _parseWechatQrUuid(html);
    if (uuid.isEmpty) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ WeChat QR page did not include uuid.',
      );
    }
    final key = Uri(queryParameters: {
      'type': 'wx',
      'uuid': uuid,
      'state': state,
    }).query;
    return QqMusicQrLoginSession(
      mode: QqMusicQrLoginMode.wechat,
      key: key,
      loginUri: loginUri,
      imageUri: Uri.parse(
        'https://open.weixin.qq.com/connect/qrcode/${Uri.encodeComponent(uuid)}',
      ),
      expiresAt: _now().add(const Duration(minutes: 5)),
    );
  }

  Future<QqMusicQrLoginResult> _checkWechatQrLoginSession(
    QqMusicQrLoginSession session,
  ) async {
    final values = Uri.splitQueryString(session.key);
    final uuid = values['uuid']?.trim() ?? '';
    if (uuid.isEmpty) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ WeChat QR login key is missing uuid.',
      );
    }
    final uri = _wxQrCheckUri.replace(queryParameters: {
      'uuid': uuid,
      '_': _now().millisecondsSinceEpoch.toString(),
    });
    final response = await _client
        .get(
          uri,
          headers: _qrHeaders(
              referer: 'https://open.weixin.qq.com/connect/qrconnect'),
        )
        .timeout(const Duration(seconds: 15));
    final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
    final parsed = _parseWechatQrCheck(raw);
    final status = _mapWechatQrStatus(parsed.code);
    if (status != QqMusicQrLoginStatus.authorized) {
      return QqMusicQrLoginResult(
        status: status,
        message: _wechatStatusLabel(status, raw),
      );
    }
    if (parsed.wxCode.isEmpty) {
      return const QqMusicQrLoginResult(
        status: QqMusicQrLoginStatus.failed,
        message: '微信授权成功但未返回登录 code。',
      );
    }
    final cookies = await _fetchWechatLoginCookies(parsed.wxCode);
    return QqMusicQrLoginResult(
      status: QqMusicQrLoginStatus.authorized,
      credentials: QqMusicCredentials(
        cookie: _joinCookies(_normalizeQqMusicCookies(cookies)),
      ),
      message: '登录成功',
    );
  }

  @override
  Future<ProviderAccountProfile?> getProfile() async {
    _requireCapability(ProviderCapability.authenticate);
    if (!isAuthenticated) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: 'QQ Music account is signed out.',
      );
    }
    final uin = _extractUin();
    return ProviderAccountProfile(
      accountId: uin ?? 'qq_music_user',
      displayName: uin ?? 'QQ音乐用户',
      avatarUrl: null,
    );
  }

  @override
  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false}) async {
    _requireCapability(ProviderCapability.readFavorites);
    final uin = _extractUin();
    if (uin == null || uin.isEmpty) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: 'QQ Music uin is required to read liked songs.',
      );
    }

    final params = _profileOrderAssetParams(uin, '1', 0, 300);
    final uri = Uri.parse(
      'https://c.y.qq.com/fav/fcgi-bin/fcg_get_profile_order_asset.fcg',
    ).replace(queryParameters: params);
    final payload = await _fcgRequest(uri);
    final data = _jsonMap(payload['data']);
    final songlist = data['songlist'] as List<Object?>? ?? const [];

    final tracks = <SourceTrack>[];
    // ignore: avoid_print
    if (songlist.isNotEmpty) {
      final firstMap = songlist.first;
      if (firstMap is Map) {
        // ignore: avoid_print
        print('First songlist item keys: ${firstMap.keys}');
        // ignore: avoid_print
        print('First songlist item details: $firstMap');
      }
    }
    // ignore: avoid_print
    print('--- QQ Music Favorites raw API parsing ---');
    for (final item in songlist) {
      if (item is! Map<Object?, Object?>) continue;
      final songData = _jsonMap(item['data']);
      final songmid = songData['songmid']?.toString() ?? '';
      if (songmid.isEmpty) continue;
      final timeVal = item['time'];
      DateTime? likedAt;
      if (timeVal is num && timeVal > 0) {
        likedAt = DateTime.fromMillisecondsSinceEpoch(timeVal.toInt() * 1000,
            isUtc: true);
      }
      final track = _trackFromProfileSong(songData, likedAt: likedAt);
      // ignore: avoid_print
      print('Parsed track: "${track.title}" - raw timeVal: $timeVal - likedAt: $likedAt');
      tracks.add(track);
    }
    // ignore: avoid_print
    print('Total parsed favorites: ${tracks.length}');
    // ignore: avoid_print
    print('-----------------------------------------');

    // likedAt assigned by the service layer during registry sync.
    return FavoriteSnapshot(providerId: descriptor.id, tracks: tracks);
  }

  @override
  Future<List<SourceTrack>> search(String query) async {
    _requireCapability(ProviderCapability.search);
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final uri = _searchBaseUri.replace(
      path: '/soso/fcgi-bin/client_search_cp',
      queryParameters: {
        'format': 'json',
        'p': '1',
        'n': '30',
        'w': normalized,
      },
    );
    final payload = await _getJson(uri);
    final data = _jsonMap(payload['data']);
    final song = _jsonMap(data['song']);
    final list = song['list'] as List<Object?>? ?? const [];
    return list
        .whereType<Map<Object?, Object?>>()
        .map((item) => _trackFromSearch(_stringMap(item)))
        .where((track) => track.ref.trackId.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> setFavorite({
    required ProviderTrackRef track,
    required bool liked,
  }) async {
    _requireCapability(ProviderCapability.writeFavorites);
    final uin = _extractUin();
    if (uin == null || uin.isEmpty) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: 'QQ Music uin is required to write favorites.',
      );
    }
    final songMid = track.extraIds['song_mid'] ?? track.trackId;
    if (songMid.isEmpty) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ Music song mid is required to write favorites.',
      );
    }

    final result = await _musicuRequest({
      'comm': {
        'uin': int.tryParse(uin) ?? 0,
        'format': 'json',
        'ct': 19,
        'cv': 0,
      },
      'fav': {
        'module': 'music.songFav.SongFavServer',
        'method': 'SetSongFav',
        'param': {
          'songmid': songMid,
          'fav': liked ? 1 : 0,
          'time': 3,
        },
      },
    });

    final favCode = _jsonMap(result['fav'])['code'];
    if (favCode is num && favCode != 0) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ Music favorite request failed with code $favCode.',
      );
    }
  }

  @override
  Future<List<SourceTrack>> getDailyRecommendations() async {
    _requireCapability(ProviderCapability.readDailyRecommendations);
    final uin = _extractUin() ?? '0';

    // Try SmartRadio via musicu.fcg
    try {
      final result = await _musicuRequest({
        'comm': {'ct': 24, 'cv': 0},
        'recommend': {
          'module': 'music.recommend.SmartRadio',
          'method': 'GetSmartRadio',
          'param': {'uin': uin},
        },
      });
      final recommend = _jsonMap(result['recommend']);
      if (recommend['code'] is num && (recommend['code'] as num) == 0) {
        final data = _jsonMap(recommend['data']);
        final songList = data['songList'] as List<Object?>? ??
            data['songs'] as List<Object?>? ??
            const [];
        if (songList.isNotEmpty) {
          return songList
              .whereType<Map<Object?, Object?>>()
              .map((s) => _trackFromPlaylistSong(_stringMap(s)))
              .where((t) => t.ref.trackId.isNotEmpty)
              .toList(growable: false);
        }
      }
    } catch (_) {
      // Fall through to fallback below.
    }

    // Fallback: return hot / trending tracks via search.
    try {
      final tracks = await search('热门');
      return tracks.take(20).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<ProviderPlaylist>> getRecommendedPlaylists({
    int limit = 12,
  }) async {
    _requireCapability(ProviderCapability.readDailyRecommendations);
    final boundedLimit = limit.clamp(1, 50).toInt();

    try {
      final result = await _musicuRequest({
        'comm': {'ct': 24},
        'recomPlaylist': {
          'module': 'playlist.HotRecommendServer',
          'method': 'get_hot_recommend',
          'param': {'async': 1, 'cmd': 2},
        },
      });
      final recomPlaylist = _jsonMap(result['recomPlaylist']);
      if (recomPlaylist['code'] is num && (recomPlaylist['code'] as num) == 0) {
        final data = _jsonMap(recomPlaylist['data']);
        final vHot = data['v_hot'] as List<Object?>? ?? const [];
        if (vHot.isNotEmpty) {
          return vHot
              .whereType<Map<Object?, Object?>>()
              .map((item) {
                final map = _stringMap(item);
                return ProviderPlaylist(
                  providerId: descriptor.id,
                  playlistId: map['content_id']?.toString() ?? '',
                  name: map['title']?.toString() ?? '推荐歌单',
                  cover: _parseQqCover(map['cover']?.toString()),
                  trackCount: (map['song_cnt'] as num?)?.toInt() ??
                      (map['song_count'] as num?)?.toInt() ??
                      0,
                  playCount: (map['listen_num'] as num?)?.toInt(),
                  creatorName: map['username']?.toString(),
                );
              })
              .where((p) => p.playlistId.isNotEmpty)
              .take(boundedLimit)
              .toList(growable: false);
        }
      }
    } catch (_) {
      // Fall through to fallback below.
    }

    return const [];
  }

  @override
  Future<List<ProviderPlaylist>> getUserPlaylists() async {
    _requireCapability(ProviderCapability.readUserPlaylists);
    final uin = _extractUin();
    if (uin == null || uin.isEmpty) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: 'QQ Music uin is required to read playlists.',
      );
    }

    final playlists = <ProviderPlaylist>[];
    final seen = <String>{};

    // 1. Virtual "我喜欢的歌曲" playlist.
    try {
      final favParams = _profileOrderAssetParams(uin, '1', 0, 1);
      final favUri = Uri.parse(
        'https://c.y.qq.com/fav/fcgi-bin/fcg_get_profile_order_asset.fcg',
      ).replace(queryParameters: favParams);
      final favPayload = await _fcgRequest(favUri);
      final favData = _jsonMap(favPayload['data']);
      final totalSong = (favData['totalsong'] as num?)?.toInt() ?? 0;
      if (totalSong > 0) {
        playlists.add(ProviderPlaylist(
          providerId: descriptor.id,
          playlistId: 'profile:favorites',
          name: '我喜欢的歌曲',
          trackCount: totalSong,
          creatorName: uin,
        ));
        seen.add('profile:favorites');
      }
    } catch (_) {}

    // 2. Created & collected playlists via fcg_user_created_diss.
    try {
      final createdUri = Uri.parse(
        'https://c.y.qq.com/rsc/fcgi-bin/fcg_user_created_diss',
      ).replace(queryParameters: {
        'hostuin': uin,
        'sin': '0',
        'size': '100',
        'format': 'json',
        'inCharset': 'utf8',
        'outCharset': 'utf-8',
      });
      final createdPayload = await _fcgRequest(createdUri);
      final data = _jsonMap(createdPayload['data']);

      for (final listKey in [
        'disslist',
        'list',
        'DissList',
        'List',
        'cdlist',
        'CDList'
      ]) {
        final items = data[listKey] as List<Object?>? ?? const [];
        for (final item in items) {
          if (item is! Map<Object?, Object?>) continue;
          final map = _stringMap(item);
          final dissId = map['dissid']?.toString() ??
              map['tid']?.toString() ??
              map['DirID']?.toString() ??
              '';
          if (dissId.isEmpty || seen.contains(dissId)) continue;
          seen.add(dissId);
          playlists.add(_playlistFromDiss(map));
        }
      }
    } catch (_) {}

    // 3. Profile-ordered playlists (collected).
    try {
      final orderParams = _profileOrderAssetParams(uin, '3', 0, 100);
      final orderUri = Uri.parse(
        'https://c.y.qq.com/fav/fcgi-bin/fcg_get_profile_order_asset.fcg',
      ).replace(queryParameters: orderParams);
      final orderPayload = await _fcgRequest(orderUri);
      final orderData = _jsonMap(orderPayload['data']);
      final cdlist = orderData['cdlist'] as List<Object?>? ?? const [];
      for (final item in cdlist) {
        if (item is! Map<Object?, Object?>) continue;
        final map = _stringMap(item);
        final dissId = map['dissid']?.toString() ?? '';
        final name = map['dissname']?.toString() ?? '';
        if (dissId.isEmpty || name.isEmpty || seen.contains(dissId)) continue;
        seen.add(dissId);
        playlists.add(_playlistFromDiss(map));
      }
    } catch (_) {}

    return playlists;
  }

  @override
  Future<List<SourceTrack>> getPlaylistTracks(String playlistId) async {
    _requireCapability(ProviderCapability.readUserPlaylists);
    final normalizedId = playlistId.trim();
    if (normalizedId.isEmpty) return const [];

    // Virtual "我喜欢的歌曲" → profile-order songs.
    if (normalizedId == 'profile:favorites') {
      final uin = _extractUin();
      if (uin == null || uin.isEmpty) {
        throw AuthenticationRequiredException(
          providerId: descriptor.id,
          message: 'QQ Music uin is required to read favorites.',
        );
      }
      final params = _profileOrderAssetParams(uin, '1', 0, 300);
      final uri = Uri.parse(
        'https://c.y.qq.com/fav/fcgi-bin/fcg_get_profile_order_asset.fcg',
      ).replace(queryParameters: params);
      final payload = await _fcgRequest(uri);
      final data = _jsonMap(payload['data']);
      final songlist = data['songlist'] as List<Object?>? ?? const [];
      return songlist.whereType<Map<Object?, Object?>>().map((item) {
        final songData = _jsonMap(item['data']);
        final timeVal = item['time'];
        DateTime? likedAt;
        if (timeVal is num && timeVal > 0) {
          likedAt = DateTime.fromMillisecondsSinceEpoch(timeVal.toInt() * 1000,
              isUtc: true);
        }
        return _trackFromProfileSong(songData, likedAt: likedAt);
      }).where((t) => t.ref.trackId.isNotEmpty).toList(growable: false);
    }

    // Dir-type playlists → fcg_musiclist_getinfo.fcg
    if (normalizedId.startsWith('profile:dir:')) {
      final dirId = normalizedId.substring('profile:dir:'.length);
      if (dirId.isEmpty) return const [];
      try {
        final uin = _extractUin() ?? '0';
        final dirUri = Uri.parse(
          'http://s.plcloud.music.qq.com/fcgi-bin/fcg_musiclist_getinfo.fcg',
        ).replace(queryParameters: {
          'uin': uin,
          'dirid': dirId,
          'from': '0',
          'to': '500',
          'format': 'json',
          'g_tk': '5381',
        });
        final payload = await _fcgRequest(dirUri);
        final songList = payload['SongList'] as List<Object?>? ?? const [];
        return songList
            .whereType<Map<Object?, Object?>>()
            .map((item) => _trackFromDirSong(_stringMap(item)))
            .where((t) => t.ref.trackId.isNotEmpty)
            .toList(growable: false);
      } catch (_) {
        return const [];
      }
    }

    // Regular playlist → fcg_ucc_getcdinfo_byids_cp.fcg
    try {
      final detailUri = Uri.parse(
        'https://i.y.qq.com/qzone-music/fcg-bin/fcg_ucc_getcdinfo_byids_cp.fcg',
      ).replace(queryParameters: {
        'disstid': normalizedId,
        'type': '1',
        'json': '1',
        'utf8': '1',
        'onlysong': '0',
        'format': 'json',
        'g_tk': '5381',
        'loginUin': '0',
        'hostUin': '0',
        'inCharset': 'utf8',
        'outCharset': 'utf-8',
        'notice': '0',
        'platform': 'yqq',
        'needNewCode': '0',
      });
      final payload = await _fcgRequest(detailUri);
      final cdlist = payload['cdlist'] as List<Object?>? ?? const [];
      if (cdlist.isEmpty) return const [];
      final first = cdlist.first;
      if (first is! Map<Object?, Object?>) return const [];
      final cd = _stringMap(first);
      final songlist = cd['songlist'] as List<Object?>? ?? const [];
      return songlist
          .whereType<Map<Object?, Object?>>()
          .map((s) => _trackFromPlaylistSong(_stringMap(s)))
          .where((t) => t.ref.trackId.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _requireCapability(ProviderCapability.resolvePlayback);
    final resolved = await _resolveMedia(track, quality);
    // ignore: avoid_print
    print('QQ Music resolved playback URI: ${resolved.uri}');
    return PlaybackTicket(
      mediaUri: resolved.uri,
      headers: _headers(),
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
    final resolved = await _resolveMedia(track, quality);
    return DownloadTicket(
      mediaUri: resolved.uri,
      headers: _headers(),
      expiresAt: _now().add(const Duration(hours: 12)),
      trackRef: track,
      quality: quality,
      fileExtension: resolved.fileExtension,
    );
  }

  @override
  Future<String?> getLyrics(ProviderTrackRef track) async {
    _requireCapability(ProviderCapability.lyrics);
    final songMid = track.extraIds['song_mid'] ?? track.trackId;
    final uri = _lyricBaseUri.replace(
      path: '/lyric/fcgi-bin/fcg_query_lyric_new.fcg',
      queryParameters: {
        'format': 'json',
        'nobase64': '1',
        'songmid': songMid,
      },
    );
    final payload = await _getJson(uri);
    return payload['lyric']?.toString();
  }

  SourceTrack _trackFromSearch(Map<String, Object?> item) {
    final songMid =
        item['songmid']?.toString() ?? item['mid']?.toString() ?? '';
    final mediaMid = _mediaMidFromSong(item, songMid);
    final albumMid = item['albummid']?.toString() ?? '';
    final artists = item['singer'] as List<Object?>? ?? const [];
    return SourceTrack(
      ref: ProviderTrackRef(
        providerId: descriptor.id,
        trackId: songMid,
        extraIds: {
          if (songMid.isNotEmpty) 'song_mid': songMid,
          if (mediaMid.isNotEmpty) 'media_mid': mediaMid,
          if (albumMid.isNotEmpty) 'album_mid': albumMid,
        },
      ),
      title: _stripHtml(item['songname']?.toString() ??
          item['name']?.toString() ??
          'Untitled'),
      artists: artists
          .whereType<Map<Object?, Object?>>()
          .map((artist) => artist['name']?.toString() ?? '')
          .where((artist) => artist.isNotEmpty)
          .toList(growable: false),
      album: _stripHtml(item['albumname']?.toString()),
      duration: Duration(seconds: (item['interval'] as num?)?.toInt() ?? 0),
      artwork: albumMid.isEmpty
          ? null
          : Uri.parse(
              'https://y.qq.com/music/photo_new/T002R300x300M000$albumMid.jpg'),
      isFavorited: false,
      isPlayable: true,
      isDownloadable: true,
    );
  }

  Future<_ResolvedQqMedia> _resolveMedia(
    ProviderTrackRef track,
    AudioQuality quality,
  ) async {
    for (final filename in _filenameCandidatesFor(track, quality)) {
      final resolved = await _resolveMediaWithFilename(
        track: track,
        filename: filename,
      );
      if (resolved != null) {
        return resolved;
      }
    }

    throw ProviderTrackNotFoundException(
      providerId: descriptor.id,
      track: track,
      message: 'QQ Music did not return a playable URL for this track.',
    );
  }

  Future<_ResolvedQqMedia?> _resolveMediaWithFilename({
    required ProviderTrackRef track,
    required String filename,
  }) async {
    final songMid = track.extraIds['song_mid'] ?? track.trackId;
    final uin = _extractUin() ?? '0';
    final body = jsonEncode({
      'req_0': {
        'module': 'vkey.GetVkeyServer',
        'method': 'CgiGetVkey',
        'param': {
          'guid': '10000',
          'songmid': [songMid],
          'songtype': [0],
          'uin': uin,
          'loginflag': 1,
          'platform': '20',
          'filename': [filename],
        },
      },
      'comm': {
        'uin': int.tryParse(uin) ?? 0,
        'format': 'json',
        'ct': 24,
        'cv': 0,
      },
    });
    final response = await _client
        .post(
          _musicuUri,
          headers: {
            ..._headers(),
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message:
            'QQ Music media request failed with HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final root = decoded is Map<Object?, Object?> ? _stringMap(decoded) : null;
    final req = _jsonMap(root?['req_0']);
    final data = _jsonMap(req['data']);
    final info = _firstPlayableMidUrlInfo(
      data['midurlinfo'] as List<Object?>? ?? const [],
    );
    final purl = info['purl']?.toString() ?? '';
    // ignore: avoid_print
    print('QQ Music resolved purl for filename $filename: $purl');
    final sip = data['sip'] as List<Object?>? ?? const [];
    final host = sip.map((item) => item?.toString() ?? '').firstWhere(
          (item) => item.isNotEmpty,
          orElse: () => 'https://dl.stream.qqmusic.qq.com/',
        );
    if (purl.isEmpty) {
      return null;
    }
    return _ResolvedQqMedia(
      uri: Uri.parse(host).resolve(purl).replace(scheme: 'https'),
      fileExtension: _extensionForPurl(purl),
    );
  }

  Map<String, Object?> _firstPlayableMidUrlInfo(List<Object?> midUrlInfo) {
    for (final item in midUrlInfo.whereType<Map<Object?, Object?>>()) {
      final info = _stringMap(item);
      final purl = info['purl']?.toString() ?? '';
      if (purl.isNotEmpty) {
        return info;
      }
    }
    return const {};
  }

  List<String> _filenameCandidatesFor(
    ProviderTrackRef track,
    AudioQuality quality,
  ) {
    final mediaMid = track.extraIds['media_mid'] ??
        track.extraIds['song_mid'] ??
        track.trackId;
    final filenames = <String>[];

    void add(String filename) {
      if (!filenames.contains(filename)) {
        filenames.add(filename);
      }
    }

    void addQuality(AudioQuality item) {
      switch (item) {
        case AudioQuality.low:
          add('C200$mediaMid.m4a');
          add('M500$mediaMid.mp3');
        case AudioQuality.standard:
          add('C400$mediaMid.m4a');
          add('M500$mediaMid.mp3');
        case AudioQuality.high:
          add('M800$mediaMid.mp3');
        case AudioQuality.lossless:
          add('F000$mediaMid.flac');
      }
    }

    addQuality(quality);
    for (final fallback in switch (quality) {
      AudioQuality.low => const [
          AudioQuality.standard,
          AudioQuality.high,
          AudioQuality.lossless,
        ],
      AudioQuality.standard => const [
          AudioQuality.low,
          AudioQuality.high,
          AudioQuality.lossless,
        ],
      AudioQuality.high => const [
          AudioQuality.standard,
          AudioQuality.low,
          AudioQuality.lossless,
        ],
      AudioQuality.lossless => const [
          AudioQuality.high,
          AudioQuality.standard,
          AudioQuality.low,
        ],
    }) {
      addQuality(fallback);
    }
    return filenames;
  }

  String _extensionForPurl(String purl) {
    final path = Uri.tryParse(purl)?.path.toLowerCase() ?? purl.toLowerCase();
    if (path.endsWith('.flac')) return 'flac';
    if (path.endsWith('.mp3')) return 'mp3';
    if (path.endsWith('.m4a')) return 'm4a';
    return 'm4a';
  }

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    final response = await _client
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ Music request failed with HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<Object?, Object?>) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ Music response was not a JSON object.',
      );
    }
    final payload = _stringMap(decoded);
    final code = payload['code'];
    if (code is num && code != 0) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ Music response code ${code.toInt()}.',
      );
    }
    return payload;
  }

  Map<String, String> _headers() {
    final headers = {
      'Accept': 'application/json, text/plain, */*',
      'Referer': 'https://y.qq.com/',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    final cookie = _credentials?.cookie.trim();
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  Map<String, String> _qrHeaders({required String referer, String? cookie}) {
    return {
      'Accept': '*/*',
      'Referer': referer,
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
    };
  }

  Future<Map<String, String>> _fetchQqRedirectCookies(
    Uri redirectUri,
    Map<String, String> seedCookies,
  ) async {
    final collected = Map<String, String>.from(seedCookies);
    var currentUri = redirectUri;
    var referer = 'https://y.qq.com/';
    for (var index = 0; index < 8; index++) {
      final request = http.Request('GET', currentUri)
        ..followRedirects = false
        ..headers.addAll(_qrHeaders(
          referer: referer,
          cookie: _joinCookies(collected),
        ));
      final streamed = await _client.send(request).timeout(
            const Duration(seconds: 15),
          );
      collected.addAll(_responseCookies(streamed));
      final location = streamed.headers['location']?.trim();
      await streamed.stream.drain<void>();
      if (location == null ||
          location.isEmpty ||
          streamed.statusCode < 300 ||
          streamed.statusCode >= 400) {
        break;
      }
      referer = currentUri.toString();
      currentUri = currentUri.resolve(location);
    }
    return collected;
  }

  Future<Map<String, String>> _fetchWechatLoginCookies(String wxCode) async {
    final body = jsonEncode({
      'comm': {
        'tmeAppID': 'qqmusic',
        'tmeLoginType': '1',
        'g_tk': 5381,
        'platform': 'yqq',
        'ct': 24,
        'cv': 0,
      },
      'req': {
        'module': 'music.login.LoginServer',
        'method': 'Login',
        'param': {
          'strAppid': _qqWechatAppId,
          'code': wxCode,
        },
      },
    });
    final response = await _client
        .post(
          _musicuUri,
          headers: {
            ..._qrHeaders(referer: _qqWechatRedirectUri),
            'Origin': 'https://y.qq.com',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cookie': 'login_type=2',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message:
            'QQ WeChat login request failed with HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final root = decoded is Map<Object?, Object?> ? _stringMap(decoded) : null;
    final req = _jsonMap(root?['req']);
    final code = root?['code'];
    final reqCode = req['code'];
    if (code is num && code != 0 || reqCode is num && reqCode != 0) {
      final message = req['message'] ?? req['msg'] ?? root?['message'];
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ WeChat login failed: $message.',
      );
    }
    return {
      ..._responseCookies(response),
      ..._wechatLoginDataCookies(_jsonMap(req['data'])),
    };
  }

  _ParsedQqQrCheck _parseQqQrCheck(String raw) {
    final matches = RegExp("'([^']*)'").allMatches(raw).toList();
    if (matches.length >= 5) {
      return _ParsedQqQrCheck(
        code: matches[0].group(1) ?? '',
        redirectUri: Uri.tryParse(matches[2].group(1) ?? ''),
        message: matches[4].group(1) ?? '',
      );
    }
    return _ParsedQqQrCheck(code: '', message: raw);
  }

  _ParsedWechatQrCheck _parseWechatQrCheck(String raw) {
    final codeMatch = RegExp(r"wx_errcode\s*=\s*'?([0-9]+)'?").firstMatch(raw);
    final wxCodeMatch =
        RegExp(r'''wx_code\s*=\s*["']([^"']*)["']''').firstMatch(raw);
    return _ParsedWechatQrCheck(
      code: codeMatch?.group(1)?.trim() ?? '',
      wxCode: wxCodeMatch?.group(1)?.trim() ?? '',
    );
  }

  String _parseWechatQrUuid(String raw) {
    final patterns = [
      RegExp(r'connect/l/qrconnect\?uuid=([A-Za-z0-9_-]+)'),
      RegExp(r'window\.QRLogin\.uuid\s*=\s*"([^"]+)"'),
      RegExp(r'/connect/qrcode/([A-Za-z0-9_-]+)'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(raw);
      final uuid = match?.group(1)?.trim();
      if (uuid != null && uuid.isNotEmpty) {
        return uuid;
      }
    }
    return '';
  }

  QqMusicQrLoginStatus _mapQqQrStatus(String code) {
    return switch (code) {
      '0' => QqMusicQrLoginStatus.authorized,
      '65' => QqMusicQrLoginStatus.expired,
      '66' => QqMusicQrLoginStatus.waiting,
      '67' => QqMusicQrLoginStatus.scanned,
      _ => QqMusicQrLoginStatus.failed,
    };
  }

  QqMusicQrLoginStatus _mapWechatQrStatus(String code) {
    return switch (code) {
      '405' => QqMusicQrLoginStatus.authorized,
      '402' => QqMusicQrLoginStatus.expired,
      '404' => QqMusicQrLoginStatus.scanned,
      '408' => QqMusicQrLoginStatus.waiting,
      _ => QqMusicQrLoginStatus.failed,
    };
  }

  String _qqStatusLabel(QqMusicQrLoginStatus status) => switch (status) {
        QqMusicQrLoginStatus.waiting => '等待扫码',
        QqMusicQrLoginStatus.scanned => '已扫码，请在手机上确认',
        QqMusicQrLoginStatus.authorized => '登录成功',
        QqMusicQrLoginStatus.expired => '二维码已过期',
        QqMusicQrLoginStatus.failed => '扫码登录失败',
      };

  String _wechatStatusLabel(QqMusicQrLoginStatus status, String raw) {
    return switch (status) {
      QqMusicQrLoginStatus.waiting => '等待扫码',
      QqMusicQrLoginStatus.scanned => '已扫码，请在微信中确认',
      QqMusicQrLoginStatus.authorized => '登录成功',
      QqMusicQrLoginStatus.expired => '二维码已过期',
      QqMusicQrLoginStatus.failed => raw.trim().isEmpty ? '扫码登录失败' : raw,
    };
  }

  int _hash33(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash += (hash << 5) + codeUnit;
    }
    return hash & 0x7fffffff;
  }

  Map<String, String> _responseCookies(http.BaseResponse response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.trim().isEmpty) {
      return const {};
    }
    final cookies = <String, String>{};
    for (final part in raw.split(RegExp(r',\s*(?=[^;,]+=)'))) {
      final first = part.split(';').first.trim();
      final equals = first.indexOf('=');
      if (equals <= 0) continue;
      cookies[first.substring(0, equals)] = first.substring(equals + 1);
    }
    return cookies;
  }

  Map<String, String> _normalizeQqMusicCookies(Map<String, String> cookies) {
    final result = Map<String, String>.from(cookies);
    result['uin'] = _firstNonEmpty([
      result['uin'],
      result['ptui_loginuin'],
      result['luin'],
      result['pt2gguin'],
      result['superuin'],
      result['p_uin'],
      result['musicid'],
      result['userid'],
      result['wxuin'],
    ]);
    final key = _firstNonEmpty([
      result['qqmusic_key'],
      result['qm_keyst'],
      result['p_skey'],
      result['skey'],
      result['musickey'],
    ]);
    if (key.isNotEmpty) {
      result['qqmusic_key'] = key;
      result['qm_keyst'] = key;
    }
    return result
      ..removeWhere((key, value) => key.trim().isEmpty || value.trim().isEmpty);
  }

  Map<String, String> _wechatLoginDataCookies(Map<String, Object?> data) {
    String value(List<String> keys) {
      for (final key in keys) {
        final item = data[key];
        if (item is String && item.trim().isNotEmpty) return item.trim();
        if (item is num && item > 0) return item.toInt().toString();
      }
      return '';
    }

    final result = <String, String>{};
    final musicId = value(['musicid', 'musicId', 'userid', 'user_id', 'uin']);
    if (musicId.isNotEmpty) result['musicid'] = musicId;
    final musicKey = value([
      'musickey',
      'music_key',
      'qqmusic_key',
      'qm_keyst',
      'strMusicKey',
    ]);
    if (musicKey.isNotEmpty) {
      result['musickey'] = musicKey;
      result['qqmusic_key'] = musicKey;
      result['qm_keyst'] = musicKey;
    }
    final refreshKey = value(['refresh_key', 'refreshKey']);
    if (refreshKey.isNotEmpty) result['refresh_key'] = refreshKey;
    final refreshToken = value(['refresh_token', 'refreshToken']);
    if (refreshToken.isNotEmpty) result['refresh_token'] = refreshToken;
    final openId = value(['openid', 'openId', 'wxopenid', 'strOpenid']);
    if (openId.isNotEmpty) {
      result['openid'] = openId;
      result['wxopenid'] = openId;
    }
    final unionId = value(['unionid', 'unionId', 'wxunionid', 'strUnionid']);
    if (unionId.isNotEmpty) {
      result['unionid'] = unionId;
      result['wxunionid'] = unionId;
    }
    final accessToken =
        value(['access_token', 'accessToken', 'wxaccess_token']);
    if (accessToken.isNotEmpty) result['wxaccess_token'] = accessToken;
    return result;
  }

  String _joinCookies(Map<String, String> cookies) {
    final keys = cookies.keys.where((key) => key.trim().isNotEmpty).toList()
      ..sort();
    return [
      for (final key in keys)
        if ((cookies[key] ?? '').trim().isNotEmpty) '$key=${cookies[key]}',
    ].join('; ');
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
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
      message: 'QQ Music ${capability.name} is not available yet.',
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

  String _stripHtml(String? value) {
    return (value ?? '').replaceAll(RegExp(r'<[^>]+>'), '');
  }

  /// Extracts the QQ Music user identifier (uin) from login cookies.
  /// Returns a numeric uin string, or null if unavailable.
  /// QQ often stores uin as encrypted "o0723255953" — we strip the leading "o"
  /// to get the numeric ID that the API requires.
  String? _extractUin() {
    final cookie = _credentials?.cookie ?? '';
    if (cookie.isEmpty) return null;
    for (final key in [
      'uin',
      'musicid',
      'wxuin',
      'p_uin',
      'userid',
      'superuin',
      'pt2gguin'
    ]) {
      final pattern = RegExp('(?:^|;)\\s*$key\\s*=\\s*([^;]+)');
      final match = pattern.firstMatch(cookie);
      if (match != null) {
        final raw = match.group(1)?.trim() ?? '';
        final digits = raw.startsWith('o') ? raw.substring(1) : raw;
        if (digits.isNotEmpty && digits != '0') return digits;
      }
    }
    return null;
  }

  /// Strips a JSONP wrapper like `callback({...})` or `({...})`.
  String _stripJsonp(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    final idx = trimmed.indexOf('(');
    if (idx >= 0 && trimmed.endsWith(')')) {
      return trimmed.substring(idx + 1, trimmed.length - 1);
    }
    return trimmed;
  }

  /// GET request for QQ FCGI endpoints that may return JSONP.
  /// Throws on HTTP error or non-zero [code].
  Future<Map<String, Object?>> _fcgRequest(Uri uri) async {
    final response = await _client
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ FCG request failed with HTTP ${response.statusCode}.',
      );
    }
    final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
    final stripped = _stripJsonp(raw);
    final decoded = jsonDecode(stripped);
    if (decoded is! Map<Object?, Object?>) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ FCG response was not a JSON object.',
      );
    }
    final payload = _stringMap(decoded);
    final code = payload['code'];
    if (code is num && code != 0) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ FCG response code ${code.toInt()}.',
      );
    }
    return payload;
  }

  /// POST request to the musicu.fcg unified gateway.
  Future<Map<String, Object?>> _musicuRequest(
    Map<String, Object?> body,
  ) async {
    final response = await _client
        .post(
          _musicuUri,
          headers: {
            ..._headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ Musicu request failed with HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<Object?, Object?>) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'QQ Musicu response was not a JSON object.',
      );
    }
    return _stringMap(decoded);
  }

  /// Builds query parameters for fcg_get_profile_order_asset.fcg.
  Map<String, String> _profileOrderAssetParams(
    String uin,
    String reqtype,
    int offset,
    int limit,
  ) {
    final ein = offset + limit - 1;
    return {
      'format': 'json',
      'inCharset': 'utf8',
      'outCharset': 'utf-8',
      'platform': 'yqq.json',
      'needNewCode': '0',
      'loginUin': uin,
      'hostUin': '0',
      'notice': '0',
      'g_tk': '5381',
      'ct': '20',
      'cid': '205360956',
      'userid': uin,
      'reqtype': reqtype,
      'sin': offset.toString(),
      'ein': ein.toString(),
    };
  }

  /// Converts a QQ profile-order song map to [SourceTrack].
  /// likedAt and source are assigned later by the service layer.
  SourceTrack _trackFromProfileSong(
    Map<String, Object?> songData, {
    DateTime? likedAt,
  }) {
    final songmid = songData['songmid']?.toString() ?? '';
    final mediaMid = _mediaMidFromSong(songData, songmid);
    final albumMid = songData['albummid']?.toString() ?? '';
    final artists = songData['singer'] as List<Object?>? ?? const [];
    return _buildQqTrack(
      songmid: songmid,
      title: songData['songname']?.toString() ?? 'Untitled',
      artists: artists
          .whereType<Map<Object?, Object?>>()
          .map((s) => s['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList(growable: false),
      album: songData['albumname']?.toString(),
      intervalSeconds: (songData['interval'] as num?)?.toInt() ?? 0,
      isFavorited: true,
      mediaMid: mediaMid,
      albumMid: albumMid,
      likedAt: likedAt,
      likedAtSource: 'qq_import',
      likedAtPrecision: likedAt != null ? 'exact' : 'unknown',
    );
  }

  /// Converts a QQ playlist song entry (from cdlist.songlist) to [SourceTrack].
  /// Handles multiple field naming conventions:
  ///   - songmid / mid (primary id)
  ///   - songname / name (title)
  ///   - albumname / album.name (album name)
  ///   - albummid / album.mid (album mid)
  SourceTrack _trackFromPlaylistSong(Map<String, Object?> song) {
    final songmid =
        song['songmid']?.toString() ?? song['mid']?.toString() ?? '';
    final mediaMid = _mediaMidFromSong(song, songmid);
    final albumMid =
        song['albummid']?.toString() ?? _nestedString(song['album'], 'mid');
    final artists = song['singer'] as List<Object?>? ?? const [];
    final albumName =
        song['albumname']?.toString() ?? _nestedString(song['album'], 'name');
    return _buildQqTrack(
      songmid: songmid,
      title: song['songname']?.toString() ??
          song['name']?.toString() ??
          'Untitled',
      artists: artists
          .whereType<Map<Object?, Object?>>()
          .map((s) => s['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList(growable: false),
      album: albumName,
      intervalSeconds: (song['interval'] as num?)?.toInt() ?? 0,
      isFavorited: false,
      mediaMid: mediaMid,
      albumMid: albumMid,
    );
  }

  /// Extracts a nested string field (e.g. album → mid).
  /// Handles both map and list-of-maps (singer list) shapes.
  String _nestedString(Object? value, String key) {
    if (value is Map<Object?, Object?>) {
      return _stringMap(value)[key]?.toString() ?? '';
    }
    return '';
  }

  String _mediaMidFromSong(Map<String, Object?> song, String songmid) {
    return _firstNonEmpty([
      song['media_mid']?.toString(),
      song['mediaMid']?.toString(),
      song['strMediaMid']?.toString(),
      song['filemedia_mid']?.toString(),
      _nestedString(song['file'], 'media_mid'),
      _nestedString(song['file'], 'mediaMid'),
      _nestedString(song['file'], 'strMediaMid'),
      songmid,
    ]);
  }

  /// Shared SourceTrack builder for QQ Music songs.
  SourceTrack _buildQqTrack({
    required String songmid,
    required String title,
    required List<String> artists,
    String? album,
    required int intervalSeconds,
    required bool isFavorited,
    String? mediaMid,
    String? albumMid,
    DateTime? likedAt,
    String? likedAtSource,
    String? likedAtPrecision,
  }) {
    return SourceTrack(
      ref: ProviderTrackRef(
        providerId: descriptor.id,
        trackId: songmid,
        extraIds: {
          if (songmid.isNotEmpty) 'song_mid': songmid,
          if (mediaMid != null && mediaMid.isNotEmpty) 'media_mid': mediaMid,
          if (albumMid != null && albumMid.isNotEmpty) 'album_mid': albumMid,
        },
      ),
      title: title,
      artists: artists,
      album: album,
      duration: Duration(seconds: intervalSeconds),
      isFavorited: isFavorited,
      artwork: albumMid == null || albumMid.isEmpty
          ? null
          : Uri.parse(
              'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg'),
      isPlayable: true,
      isDownloadable: true,
      likedAt: likedAt,
      likedAtSource: likedAtSource,
      likedAtPrecision: likedAtPrecision,
    );
  }

  /// Converts a QQ disslist/playlist map to [ProviderPlaylist].
  /// Handles both fcg_user_created_diss (disslist) and
  /// fcg_get_profile_order_asset (cdlist) response formats.
  ProviderPlaylist _playlistFromDiss(Map<String, Object?> item) {
    final dissId = item['dissid']?.toString() ?? item['tid']?.toString() ?? '';
    return ProviderPlaylist(
      providerId: descriptor.id,
      playlistId: dissId,
      name: item['diss_name']?.toString() ??
          item['title']?.toString() ??
          item['dissname']?.toString() ??
          'QQ Playlist',
      description:
          item['diss_desc']?.toString() ?? item['introduction']?.toString(),
      creatorName: item['nickname']?.toString() ?? item['creator']?.toString(),
      cover: _parseQqCover(
        item['diss_cover']?.toString() ??
            item['cover']?.toString() ??
            item['imgurl']?.toString() ??
            item['logo']?.toString(),
      ),
      trackCount: (item['song_cnt'] as num?)?.toInt() ??
          (item['song_num'] as num?)?.toInt() ??
          (item['songnum'] as num?)?.toInt() ??
          (item['song_count'] as num?)?.toInt() ??
          0,
      playCount: (item['listen_num'] as num?)?.toInt() ??
          (item['visitnum'] as num?)?.toInt() ??
          (item['listennum'] as num?)?.toInt(),
    );
  }

  /// Converts a QQ dir-type playlist song entry to [SourceTrack].
  /// Dir songs may use pipe-delimited [data] or field-based maps.
  SourceTrack _trackFromDirSong(Map<String, Object?> item) {
    final dataStr = item['data']?.toString() ?? '';
    final songType = (item['type'] as num?)?.toInt() ?? 0;
    // Pipe-delimited format: songmid|name|...|artist|albummid|albumname|...|interval|...
    if (dataStr.isNotEmpty && songType % 10 >= 2 && songType % 10 <= 4) {
      final parts = dataStr.split('|');
      String value(int index) =>
          index < parts.length ? parts[index].trim() : '';
      return _buildQqTrack(
        songmid: value(0),
        title: value(1).isNotEmpty ? value(1) : 'Untitled',
        artists: value(3).isNotEmpty ? [value(3)] : [],
        album: value(5).isNotEmpty ? value(5) : null,
        intervalSeconds: int.tryParse(value(7)) ?? 0,
        isFavorited: false,
        mediaMid: value(0).isNotEmpty ? value(0) : null,
        albumMid: value(4).isNotEmpty ? value(4) : null,
      );
    }
    // Fallback to field-based parsing.
    return _trackFromPlaylistSong(item);
  }

  /// Normalizes a QQ Music cover URL (http → https).
  Uri? _parseQqCover(String? url) {
    if (url == null || url.isEmpty) return null;
    final https = url.replaceFirst(RegExp(r'^http:'), 'https:');
    return Uri.tryParse(https);
  }
}

final class _ResolvedQqMedia {
  const _ResolvedQqMedia({
    required this.uri,
    required this.fileExtension,
  });

  final Uri uri;
  final String fileExtension;
}

final class _ParsedQqQrCheck {
  const _ParsedQqQrCheck({
    required this.code,
    required this.message,
    this.redirectUri,
  });

  final String code;
  final String message;
  final Uri? redirectUri;
}

final class _ParsedWechatQrCheck {
  const _ParsedWechatQrCheck({
    required this.code,
    required this.wxCode,
  });

  final String code;
  final String wxCode;
}
