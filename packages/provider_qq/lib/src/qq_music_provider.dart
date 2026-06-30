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
    _unsupported(ProviderCapability.authenticate);
  }

  @override
  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false}) async {
    _unsupported(ProviderCapability.readFavorites);
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
    _unsupported(ProviderCapability.writeFavorites);
  }

  @override
  Future<List<SourceTrack>> getDailyRecommendations() async {
    _unsupported(ProviderCapability.readDailyRecommendations);
  }

  @override
  Future<List<ProviderPlaylist>> getRecommendedPlaylists({
    int limit = 12,
  }) async {
    _unsupported(ProviderCapability.readDailyRecommendations);
  }

  @override
  Future<List<ProviderPlaylist>> getUserPlaylists() async {
    _unsupported(ProviderCapability.readUserPlaylists);
  }

  @override
  Future<List<SourceTrack>> getPlaylistTracks(String playlistId) async {
    _unsupported(ProviderCapability.readUserPlaylists);
  }

  @override
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _requireCapability(ProviderCapability.resolvePlayback);
    final resolved = await _resolveMedia(track, quality);
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
    final albumMid = item['albummid']?.toString() ?? '';
    final artists = item['singer'] as List<Object?>? ?? const [];
    return SourceTrack(
      ref: ProviderTrackRef(
        providerId: descriptor.id,
        trackId: songMid,
        extraIds: {
          if (songMid.isNotEmpty) 'song_mid': songMid,
          if (item['media_mid'] != null)
            'media_mid': item['media_mid'].toString(),
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
    final songMid = track.extraIds['media_mid'] ??
        track.extraIds['song_mid'] ??
        track.trackId;
    final body = jsonEncode({
      'req_0': {
        'module': 'vkey.GetVkeyServer',
        'method': 'CgiGetVkey',
        'param': {
          'guid': '10000',
          'songmid': [songMid],
          'songtype': [0],
          'uin': '0',
          'loginflag': 1,
          'platform': '20',
          'filename': [_filenameFor(track, quality)],
        },
      },
      'comm': {
        'uin': 0,
        'format': 'json',
        'ct': 24,
        'cv': 0,
      },
    });
    final response = await _client
        .post(_musicuUri, headers: _headers(), body: body)
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
    final midUrlInfo = data['midurlinfo'] as List<Object?>? ?? const [];
    final info = midUrlInfo.whereType<Map<Object?, Object?>>().isEmpty
        ? const <String, Object?>{}
        : _stringMap(midUrlInfo.whereType<Map<Object?, Object?>>().first);
    final purl = info['purl']?.toString() ?? '';
    final sip = data['sip'] as List<Object?>? ?? const [];
    final host = sip.map((item) => item?.toString() ?? '').firstWhere(
          (item) => item.isNotEmpty,
          orElse: () => 'https://dl.stream.qqmusic.qq.com/',
        );
    if (purl.isEmpty) {
      throw ProviderTrackNotFoundException(
        providerId: descriptor.id,
        track: track,
        message: 'QQ Music did not return a playable URL for this track.',
      );
    }
    return _ResolvedQqMedia(
      uri: Uri.parse(host).resolve(purl).replace(scheme: 'https'),
      fileExtension: purl.contains('.flac') ? 'flac' : 'm4a',
    );
  }

  String _filenameFor(ProviderTrackRef track, AudioQuality quality) {
    final mediaMid = track.extraIds['media_mid'] ??
        track.extraIds['song_mid'] ??
        track.trackId;
    final prefix = switch (quality) {
      AudioQuality.low => 'C200',
      AudioQuality.standard => 'C400',
      AudioQuality.high => 'M800',
      AudioQuality.lossless => 'F000',
    };
    final extension = quality == AudioQuality.lossless ? 'flac' : 'm4a';
    return '$prefix$mediaMid.$extension';
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
