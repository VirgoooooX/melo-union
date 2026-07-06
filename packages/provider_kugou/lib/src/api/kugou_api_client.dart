import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:provider_contract/provider_contract.dart';
import '../auth/kugou_session.dart';
import '../auth/kugou_session_manager.dart';
import '../support/kugou_crypto.dart';
import '../support/kugou_redacted_logger.dart';
import '../support/kugou_request_gate.dart';

class KugouApiClient {
  KugouApiClient({
    http.Client? client,
    required KugouSessionManager sessionManager,
    KugouRedactedLogger? logger,
    KugouRequestGate? gate,
  })  : _client = client ?? http.Client(),
        _sessionManager = sessionManager,
        _logger = logger ?? const KugouRedactedLogger(),
        _gate = gate ?? KugouRequestGate();

  final http.Client _client;
  final KugouSessionManager _sessionManager;
  final KugouRedactedLogger _logger;
  final KugouRequestGate _gate;

  static const int _androidAppId = 3116;
  static const int _androidClientVersion = 11440;
  static const String _androidSignatureSalt =
      'LnT6xpN3khm36zse0QzvmgTZ3waWdRSA';

  static const int _webAppId = 3116;
  static const int _webClientVersion = 11440;
  static const String _webSignatureSalt = 'NVPh5oo715z5DIWAeQlhMDsWXXQV4hwt';

  /// Registers the current device with the Kugou risk service (Android-style).
  ///
  /// POST https://userservice.kugou.com/risk/v2/r_register_dev with Android
  /// signing (encryptType: 'android'). The server returns a dfid that is
  /// stored back into the session manager.
  ///
  /// Must be called before /v2/qrcode or the API returns error_code 20010.
  Future<void> registerWebDevice() async {
    await _gate.run(() async {
      final details = await _sessionManager.getOrCreateDeviceDetails();
      final clientTime = DateTime.now().millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;
      final session = await _sessionManager.getSession();
      final dfid = _normalizedDeviceValue(details.fingerprint);
      final token = _normalizedKugouToken(session?.token ?? '');
      final userId = session?.userId ?? '';

      final hardwareInfo = {
        'availableRamSize': 4983533568,
        'availableRomSize': 48114719,
        'availableSDSize': 48114717,
        'basebandVer': '',
        'batteryLevel': 100,
        'batteryStatus': 3,
        'brand': 'Redmi',
        'buildSerial': 'unknown',
        'device': 'marble',
        'imei': details.installGuid,
        'imsi': '',
        'manufacturer': 'Xiaomi',
        'uuid': details.installGuid,
        'accelerometer': false,
        'accelerometerValue': '',
        'gravity': false,
        'gravityValue': '',
        'gyroscope': false,
        'gyroscopeValue': '',
        'light': false,
        'lightValue': '',
        'magnetic': false,
        'magneticValue': '',
        'orientation': false,
        'orientationValue': '',
        'pressure': false,
        'pressureValue': '',
        'step_counter': false,
        'step_counterValue': '',
        'temperature': false,
        'temperatureValue': '',
      };
      final encrypted = kugouEncryptRegisterPayload(hardwareInfo);
      final p = kugouRsaPkcs1Hex({
        'aes': encrypted.aesSeed,
        'uid': userId,
        'token': token,
      });

      final params = <String, Object?>{
        'dfid': dfid,
        'mid': details.mid,
        'uuid': '-',
        'appid': _androidAppId,
        'clientver': _androidClientVersion,
        'clienttime': clientTime,
        if (token.isNotEmpty) 'token': token,
        if (userId.isNotEmpty) 'userid': userId,
        'part': 1,
        'platid': 1,
        'p': p,
      };
      params['signature'] =
          _signatureAndroidParams(params, encrypted.base64Body);

      final uri =
          Uri.parse('https://userservice.kugou.com/risk/v2/r_register_dev')
              .replace(queryParameters: {
        for (final entry in params.entries) entry.key: entry.value.toString(),
      });
      _logger.logRequest('POST', uri, null);

      final response = await _client.post(
        uri,
        headers: {
          'User-Agent': 'Android15-1070-11083-46-0-DiscoveryDRADProtocol-wifi',
          'Content-Type': 'text/plain',
          'dfid': dfid,
          'clienttime': clientTime.toString(),
          'mid': details.mid,
          'kg-rc': '1',
          'kg-thash': '5d816a0',
          'kg-rec': '1',
          'kg-rf': 'B9EDA08A64250DEFFBCADDEE00F8F25F',
          ..._randomChinaIpHeaders(),
          'Cookie': session == null
              ? _buildKugouDeviceCookie(
                  guid: details.installGuid,
                  mid: details.mid,
                  mac: details.installMac,
                  dev: details.installDev,
                  dfid: dfid,
                )
              : _buildKugouGatewayCookie(
                  session,
                  dfid: dfid,
                  mid: details.mid,
                ),
        },
        body: encrypted.base64Body,
      );
      _logger.logResponse(response.statusCode, response.body);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthenticationRequiredException(
          providerId: ProviderId('kugou'),
          message: 'Kugou device registration is unauthorized.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProviderException(
          providerId: ProviderId('kugou'),
          message:
              'Kugou device registration returned HTTP ${response.statusCode}.',
        );
      }

      final decoded = kugouDecryptRegisterResponse(
        response.bodyBytes,
        encrypted.key,
        encrypted.iv,
      );
      if (decoded['status'] == 1) {
        final data = decoded['data'] is Map
            ? decoded['data'] as Map<String, dynamic>
            : null;
        final serverDfid = data?['dfid']?.toString() ?? '';
        if (serverDfid.isNotEmpty) {
          await _sessionManager.updateDeviceFingerprint(serverDfid);
        }
      } else {
        throw ProviderException(
          providerId: ProviderId('kugou'),
          message:
              'Kugou device registration failed (code: ${decoded['error_code'] ?? decoded['err_code'] ?? 'unknown'}).',
        );
      }
    });
  }

  /// Sends a GET request with web-style params signing (encryptType: 'web').
  ///
  /// Builds default device params (including token/userid even if empty),
  /// merges [extraParams], computes a signature using the web salt, and
  /// appends it as the `signature` query parameter.
  /// Used by QR login endpoints ([/v2/qrcode], [/v2/get_userinfo_qrcode]).
  Future<Map<String, dynamic>> webGet(
    Uri baseUri, {
    Map<String, Object?> extraParams = const {},
  }) async {
    return _gate.run(() async {
      final details = await _sessionManager.getOrCreateDeviceDetails();
      final clientTime = DateTime.now().millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;
      // Music-lib reference: uses Lite appid/ver, uuid="-", dfid="-", mid from
      // device identity (decimal MD5 of GUID).  We match those defaults here
      // for the anonymous QR context.
      final params = <String, Object?>{
        'dfid': '-',
        'mid': details.mid,
        'uuid': '-',
        'appid': _webAppId,
        'clientver': _webClientVersion,
        'clienttime': clientTime,
        ...extraParams,
      };

      final signature = _signatureWebParams(params);
      params['signature'] = signature;

      final uri = baseUri.replace(queryParameters: {
        for (final entry in params.entries) entry.key: entry.value.toString(),
      });
      final headers = {
        'User-Agent': 'Android15-1070-11083-46-0-DiscoveryDRADProtocol-wifi',
        'Accept': 'application/json, text/plain, */*',
        'dfid': params['dfid'].toString(),
        'clienttime': clientTime.toString(),
        'mid': params['mid'].toString(),
        'kg-rc': '1',
        'kg-thash': '5d816a0',
        'kg-rec': '1',
        'kg-rf': 'B9EDA08A64250DEFFBCADDEE00F8F25F',
        'Cookie': _buildKugouDeviceCookie(
          guid: details.installGuid,
          mid: details.mid,
          mac: details.installMac,
          dev: details.installDev,
          dfid: details.fingerprint,
        ),
        ..._randomChinaIpHeaders(),
      };
      _logger.logRequest('GET', uri, headers);

      final response = await _client.get(uri, headers: headers);
      _logger.logResponse(response.statusCode, response.body);

      return _handleResponse(response);
    });
  }

  String _signatureWebParams(Map<String, Object?> params) {
    final keys = params.keys.toList(growable: false)..sort();
    final joined = keys.map((key) => '$key=${params[key]}').join();
    final bytes = utf8.encode('$_webSignatureSalt$joined$_webSignatureSalt');
    return crypto.md5.convert(bytes).toString();
  }

  Future<Map<String, dynamic>> get(
    Uri uri, {
    Map<String, String>? headers,
    bool authenticated = false,
    bool attachSessionCookie = false,
  }) async {
    return _gate.run(() async {
      final requestHeaders = await _buildHeaders(
        headers,
        authenticated,
        attachSessionCookie: attachSessionCookie,
      );
      _logger.logRequest('GET', uri, requestHeaders);

      final response = await _client.get(uri, headers: requestHeaders);
      _logger.logResponse(response.statusCode, response.body);

      return _handleResponse(response);
    });
  }

  Future<String> getText(
    Uri uri, {
    Map<String, String>? headers,
    bool authenticated = false,
  }) async {
    return _gate.run(() async {
      final requestHeaders = await _buildHeaders(headers, authenticated);
      _logger.logRequest('GET', uri, requestHeaders);

      final response = await _client.get(uri, headers: requestHeaders);
      _logger.logResponse(response.statusCode, response.body);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthenticationRequiredException(
          providerId: ProviderId('kugou'),
          message: 'Kugou session is unauthorized.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProviderException(
          providerId: ProviderId('kugou'),
          message: 'Kugou API returned HTTP ${response.statusCode}.',
        );
      }
      return response.body;
    });
  }

  Future<Map<String, dynamic>> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool authenticated = false,
  }) async {
    return _gate.run(() async {
      final requestHeaders = await _buildHeaders(headers, authenticated);
      _logger.logRequest('POST', uri, requestHeaders);

      final response =
          await _client.post(uri, headers: requestHeaders, body: body);
      _logger.logResponse(response.statusCode, response.body);

      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> songinfoV2Get({
    String? hash,
    String? encodeAlbumAudioId,
  }) async {
    return _gate.run(() async {
      final session = await _sessionManager.getOrRefreshSession();
      if (session == null) {
        throw AuthenticationRequiredException(
          providerId: ProviderId('kugou'),
          message: 'Kugou session has expired or is invalid.',
        );
      }

      final cookies = _buildSonginfoCookieMap(session);
      final webToken = cookies['t']?.trim() ?? '';
      final webUserId = cookies['KugooID']?.trim() ?? '';
      if (webToken.isEmpty || webUserId.isEmpty) {
        throw ProviderException(
          providerId: ProviderId('kugou'),
          message:
              'MediaUnavailable: Kugou songinfo v2 requires cookie t and KugooID.',
        );
      }

      final normalizedHash = hash?.trim().toLowerCase() ?? '';
      final normalizedEncodeAlbumAudioId = encodeAlbumAudioId?.trim() ?? '';
      if (normalizedHash.isEmpty && normalizedEncodeAlbumAudioId.isEmpty) {
        throw ProviderException(
          providerId: ProviderId('kugou'),
          message: 'MediaUnavailable: Kugou songinfo v2 requires a song id.',
        );
      }

      final params = <String, Object?>{
        'srcappid': '2919',
        'clientver': '20000',
        'clienttime': DateTime.now().millisecondsSinceEpoch,
        'mid': _firstNonEmpty([
          cookies['mid'],
          cookies['kg_mid'],
          session.mid,
        ]),
        'uuid': _firstNonEmpty([
          cookies['uuid'],
          cookies['mid'],
          cookies['kg_mid'],
          session.mid,
        ]),
        'dfid': _firstNonEmpty([
          cookies['dfid'],
          cookies['kg_dfid'],
          session.deviceFingerprint,
        ]),
        'appid': '1014',
        'platid': '4',
        'token': webToken,
        'userid': webUserId,
        if (normalizedHash.isNotEmpty) 'hash': normalizedHash,
        if (normalizedEncodeAlbumAudioId.isNotEmpty)
          'encode_album_audio_id': normalizedEncodeAlbumAudioId,
      };
      params['signature'] = _signatureWebParams(params);
      final uri = Uri.parse('https://wwwapi.kugou.com/play/songinfo').replace(
        queryParameters: {
          for (final entry in params.entries) entry.key: entry.value.toString(),
        },
      );
      final requestHeaders = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
        'Referer': 'https://www.kugou.com/',
        'Accept': 'application/json, text/plain, */*',
        'Cookie': _joinCookieMap(cookies),
        ..._randomChinaIpHeaders(),
      };
      _logger.logRequest('GET', uri, requestHeaders);

      final response = await _client.get(uri, headers: requestHeaders);
      _logger.logResponse(response.statusCode, response.body);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> androidGatewayPost(
    String path, {
    required Map<String, Object?> data,
    Map<String, Object?> params = const {},
    Map<String, String>? headers,
    bool authenticated = false,
    bool includeAuthInBody = false,
    Uri? endpoint,
    Map<String, Object?> Function(
            String userId, String token, Map<String, Object?> data)?
        bodyBuilder,
    Map<String, Object?> Function(
      String userId,
      String token,
      String mid,
      String vipToken,
      String vipType,
      Map<String, Object?> data,
    )? deviceBodyBuilder,
  }) async {
    return _gate.run(() async {
      final session = authenticated
          ? await _sessionManager.getOrRefreshSession()
          : await _sessionManager.getSession();
      if (authenticated && session == null) {
        throw AuthenticationRequiredException(
          providerId: ProviderId('kugou'),
          message: 'Kugou session has expired or is invalid.',
        );
      }

      final clientTime = DateTime.now().millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;
      final dfid = _gatewayDfidForPath(path, session?.deviceFingerprint);
      final token = _normalizedKugouToken(session?.token ?? '');
      final userId = session?.userId ?? '0';
      final vipToken = session?.vipToken?.trim() ?? '';
      final vipType = session?.vipType?.trim() ?? '';

      Future<Map<String, dynamic>> sendWithDevice({
        required String mid,
        required String uuid,
      }) async {
        final requestData = deviceBodyBuilder != null
            ? deviceBodyBuilder(
                userId,
                token,
                mid,
                vipToken,
                vipType,
                data,
              )
            : bodyBuilder != null
                ? bodyBuilder(userId, token, data)
                : <String, Object?>{
                    ...data,
                    if (includeAuthInBody && userId != '0') 'userid': userId,
                    if (includeAuthInBody && token.isNotEmpty) 'token': token,
                  };
        final body = jsonEncode(requestData);
        final requestParams = <String, Object?>{...params};
        if (userId != '0') {
          requestParams.putIfAbsent('userid', () => userId);
        }
        if (token.isNotEmpty) {
          requestParams.putIfAbsent('token', () => token);
        }
        requestParams.putIfAbsent('appid', () => _androidAppId);
        requestParams.putIfAbsent('clientver', () => _androidClientVersion);
        requestParams.putIfAbsent('dfid', () => dfid);
        requestParams.putIfAbsent('mid', () => mid);
        requestParams.putIfAbsent('uuid', () => uuid);
        requestParams.putIfAbsent('clienttime', () => clientTime);
        requestParams['signature'] = _signatureAndroidParams(
          requestParams,
          body,
        );

        final uri =
            (endpoint ?? Uri.parse('https://gateway.kugou.com$path')).replace(
          queryParameters: {
            for (final entry in requestParams.entries)
              entry.key: entry.value.toString(),
          },
        );
        final requestHeaders = await _buildHeaders(headers, false);
        requestHeaders.addAll({
          'User-Agent': 'Android15-1070-11083-46-0-DiscoveryDRADProtocol-wifi',
          'Accept': 'application/json, text/plain, */*',
          'Content-Type': 'application/json',
          'dfid': dfid,
          'clienttime': clientTime.toString(),
          'mid': mid,
          'kg-rc': '1',
          'kg-thash': '5d816a0',
          'kg-rec': '1',
          'kg-rf': 'B9EDA08A64250DEFFBCADDEE00F8F25F',
          ..._randomChinaIpHeaders(),
          if (session != null)
            'Cookie': _buildKugouGatewayCookie(
              session,
              dfid: dfid,
              mid: mid,
            ),
        });
        _logger.logRequest('POST', uri, requestHeaders);

        final response = await _client.post(
          uri,
          headers: requestHeaders,
          body: body,
        );
        _logger.logResponse(response.statusCode, response.body);

        return _handleResponse(response);
      }

      final musicLibMid = _resolveGatewayMid(session, dfid);
      return sendWithDevice(
        mid: musicLibMid,
        uuid: '-',
      );
    });
  }

  Future<Map<String, dynamic>> androidGatewayGet(
    String path, {
    required Map<String, Object?> params,
    Map<String, Object?> Function(String userId, String token, String mid)?
        sessionParams,
    Map<String, String>? headers,
    bool authenticated = false,
  }) async {
    return _gate.run(() async {
      final session = authenticated
          ? await _sessionManager.getOrRefreshSession()
          : await _sessionManager.getSession();
      if (authenticated && session == null) {
        throw AuthenticationRequiredException(
          providerId: ProviderId('kugou'),
          message: 'Kugou session has expired or is invalid.',
        );
      }

      final clientTime = DateTime.now().millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;
      final dfid = _gatewayDfidForPath(path, session?.deviceFingerprint);
      final token = _normalizedKugouToken(session?.token ?? '');
      final userId = session?.userId ?? '0';

      Future<Map<String, dynamic>> sendWithDevice({
        required String mid,
        required String uuid,
      }) async {
        final requestParams = <String, Object?>{...params};
        if (sessionParams != null) {
          requestParams.addAll(sessionParams(userId, token, mid));
        }
        requestParams.putIfAbsent('dfid', () => dfid);
        requestParams.putIfAbsent('mid', () => mid);
        requestParams.putIfAbsent('uuid', () => uuid);
        requestParams.putIfAbsent('appid', () => _androidAppId);
        requestParams.putIfAbsent('clientver', () => _androidClientVersion);
        requestParams.putIfAbsent('clienttime', () => clientTime);
        if (userId != '0') {
          requestParams.putIfAbsent('userid', () => userId);
        }
        if (token.isNotEmpty) {
          requestParams.putIfAbsent('token', () => token);
        }
        requestParams['signature'] = _signatureAndroidParams(requestParams, '');

        final uri = Uri.parse('https://gateway.kugou.com$path').replace(
          queryParameters: {
            for (final entry in requestParams.entries)
              entry.key: entry.value.toString(),
          },
        );
        final requestHeaders = await _buildHeaders(headers, false);
        requestHeaders.addAll({
          'User-Agent': 'Android15-1070-11083-46-0-DiscoveryDRADProtocol-wifi',
          'Accept': 'application/json, text/plain, */*',
          'dfid': dfid,
          'clienttime': clientTime.toString(),
          'mid': mid,
          'kg-rc': '1',
          'kg-thash': '5d816a0',
          'kg-rec': '1',
          'kg-rf': 'B9EDA08A64250DEFFBCADDEE00F8F25F',
          ..._randomChinaIpHeaders(),
          if (session != null)
            'Cookie': _buildKugouGatewayCookie(
              session,
              dfid: dfid,
              mid: mid,
            ),
        });
        _logger.logRequest('GET', uri, requestHeaders);

        final response = await _client.get(uri, headers: requestHeaders);
        _logger.logResponse(response.statusCode, response.body);
        return _handleResponse(response);
      }

      final musicLibMid = _resolveGatewayMid(session, dfid);
      return sendWithDevice(
        mid: musicLibMid,
        uuid: '-',
      );
    });
  }

  String _normalizedDeviceValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _gatewayDfidForPath(String path, String? sessionDfid) {
    final normalized = _normalizedDeviceValue(sessionDfid);
    if (normalized != '-') return normalized;
    if (path.contains('/v5/url') || path.contains('/v6/priv_url')) {
      return _randomKugouDfid();
    }
    return normalized;
  }

  String _randomKugouDfid() {
    final random = Random.secure();
    final seed = '${DateTime.now().microsecondsSinceEpoch}'
        '-${random.nextInt(1 << 32)}-${random.nextInt(1 << 32)}';
    final digest = crypto.md5.convert(utf8.encode(seed)).toString();
    return digest.substring(0, 24).toUpperCase();
  }

  String _resolveGatewayMid(KugouSession? session, String dfid) {
    final mid = session?.mid.trim() ?? '';
    final installGuid = session?.installGuid?.trim() ?? '';
    if (mid.isNotEmpty) {
      if (dfid != '-' &&
          installGuid.isNotEmpty &&
          mid == KugouSessionManager.calculateKugouMid(dfid)) {
        return KugouSessionManager.calculateKugouMid(installGuid);
      }
      return mid;
    }
    if (installGuid.isNotEmpty) {
      return KugouSessionManager.calculateKugouMid(installGuid);
    }
    return KugouSessionManager.calculateKugouMid('-');
  }

  String _buildKugouGatewayCookie(
    KugouSession session, {
    String? dfid,
    String? mid,
  }) {
    final token = _normalizedKugouToken(session.token);
    final cookies = <String, String>{
      ..._parseCookieMap(session.refreshMetadata?['cookie']),
      if (session.installDev?.trim().isNotEmpty == true)
        'KUGOU_API_DEV': session.installDev!.trim(),
      if (session.installGuid?.trim().isNotEmpty == true)
        'KUGOU_API_GUID': session.installGuid!.trim(),
      if (session.installMac?.trim().isNotEmpty == true)
        'KUGOU_API_MAC': session.installMac!.trim(),
      'KUGOU_API_MID':
          mid?.trim().isNotEmpty == true ? mid!.trim() : session.mid,
      'dfid': _normalizedDeviceValue(dfid ?? session.deviceFingerprint),
      'userid': session.userId,
      'token': token,
      if (session.vipToken?.isNotEmpty == true) 'vip_token': session.vipToken!,
      if (session.vipType?.isNotEmpty == true) 'vip_type': session.vipType!,
    };
    final keys = cookies.keys.toList()
      ..removeWhere((key) => key.trim().isEmpty)
      ..sort();
    return keys.map((key) => '$key=${cookies[key] ?? ''}').join('; ');
  }

  String _buildKugouDeviceCookie({
    required String guid,
    required String mid,
    required String mac,
    required String dev,
    required String dfid,
  }) {
    final cookies = <String, String>{
      'KUGOU_API_GUID': guid,
      'KUGOU_API_MID': mid,
      'KUGOU_API_MAC': mac,
      'KUGOU_API_DEV': dev,
      'dfid': _normalizedDeviceValue(dfid),
    };
    return cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  Map<String, String> _parseCookieMap(String? cookie) {
    final result = <String, String>{};
    for (final pair in (cookie ?? '').split(';')) {
      final trimmed = pair.trim();
      if (trimmed.isEmpty) continue;
      final separator = trimmed.indexOf('=');
      if (separator <= 0) continue;
      result[trimmed.substring(0, separator).trim()] =
          trimmed.substring(separator + 1).trim();
    }
    return result;
  }

  Map<String, String> _buildSonginfoCookieMap(KugouSession session) {
    return <String, String>{
      ..._parseCookieMap(session.refreshMetadata?['cookie']),
      if (session.installDev?.trim().isNotEmpty == true)
        'KUGOU_API_DEV': session.installDev!.trim(),
      if (session.installGuid?.trim().isNotEmpty == true)
        'KUGOU_API_GUID': session.installGuid!.trim(),
      if (session.installMac?.trim().isNotEmpty == true)
        'KUGOU_API_MAC': session.installMac!.trim(),
      if (session.mid.trim().isNotEmpty) 'KUGOU_API_MID': session.mid.trim(),
      if (session.deviceFingerprint.trim().isNotEmpty)
        'dfid': session.deviceFingerprint.trim(),
      'userid': session.userId,
      'token': _normalizedKugouToken(session.token),
      if (session.vipToken?.trim().isNotEmpty == true)
        'vip_token': session.vipToken!.trim(),
      if (session.vipType?.trim().isNotEmpty == true)
        'vip_type': session.vipType!.trim(),
    };
  }

  String _joinCookieMap(Map<String, String> cookies) {
    final keys = cookies.keys.toList()
      ..removeWhere((key) => key.trim().isEmpty)
      ..sort();
    return keys.map((key) => '$key=${cookies[key] ?? ''}').join('; ');
  }

  String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  Map<String, String> _randomChinaIpHeaders() {
    final ip = _randomChinaIp();
    return {
      'X-Forwarded-For': ip,
      'X-Real-IP': ip,
    };
  }

  String _randomChinaIp() {
    const prefixes = [
      [116, 255],
      [116, 228],
      [218, 192],
      [124, 0],
      [14, 132],
      [183, 14],
      [58, 14],
      [113, 116],
      [120, 230],
    ];
    final random = Random.secure();
    final prefix = prefixes[random.nextInt(prefixes.length)];
    return '${prefix[0]}.${prefix[1]}.${random.nextInt(254) + 1}.${random.nextInt(254) + 1}';
  }

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? baseHeaders,
    bool authenticated, {
    bool attachSessionCookie = false,
  }) async {
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      ...?baseHeaders,
    };

    if (authenticated || attachSessionCookie) {
      final session = authenticated
          ? await _sessionManager.getOrRefreshSession()
          : await _sessionManager.getSession();
      if (session == null && authenticated) {
        throw AuthenticationRequiredException(
          providerId: ProviderId('kugou'),
          message: 'Kugou session has expired or is invalid.',
        );
      }
      if (session != null) {
        final token = _normalizedKugouToken(session.token);
        headers['Cookie'] = _buildKugouGatewayCookie(session);
        headers['token'] = token;
        headers['userid'] = session.userId;
      }
    }
    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthenticationRequiredException(
        providerId: ProviderId('kugou'),
        message: 'Kugou session is unauthorized.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderException(
        providerId: ProviderId('kugou'),
        message: 'Kugou API returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ProviderException(
        providerId: ProviderId('kugou'),
        message: 'Kugou response is not a valid JSON object.',
      );
    }
    return decoded;
  }

  String _signatureAndroidParams(
    Map<String, Object?> params,
    String data,
  ) {
    final paramsString = params.keys.toList(growable: false)..sort();
    final joined = paramsString.map((key) {
      final value = params[key];
      return '$key=${value is Map || value is List ? jsonEncode(value) : value}';
    }).join();
    final bytes =
        utf8.encode('$_androidSignatureSalt$joined$data$_androidSignatureSalt');
    return crypto.md5.convert(bytes).toString();
  }

  String _normalizedKugouToken(String token) {
    final trimmed = token.trim();
    if (!trimmed.contains('KugooPwd=')) return trimmed;
    try {
      final parts = trimmed.replaceAll('&amp;', '&').split('&');
      for (final part in parts) {
        final eqIdx = part.indexOf('=');
        if (eqIdx != -1) {
          final k = part.substring(0, eqIdx).trim();
          final v = part.substring(eqIdx + 1).trim();
          if (k == 'KugooPwd' && v.isNotEmpty) {
            return v;
          }
        }
      }
      return trimmed;
    } catch (_) {
      return trimmed;
    }
  }
}
