import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:provider_contract/provider_contract.dart';
import '../model/kugou_media_resolution.dart';
import 'kugou_api_client.dart';

abstract interface class KugouMediaResolver {
  Future<KugouMediaResolution> resolve({
    required ProviderTrackRef track,
    required AudioQuality requestedQuality,
    required KugouMediaUse use,
  });
}

final class KugouMediaApi implements KugouMediaResolver {
  KugouMediaApi({
    required KugouApiClient client,
    required ProviderId providerId,
  })  : _client = client,
        _providerId = providerId;

  final KugouApiClient _client;
  final ProviderId _providerId;

  @override
  Future<KugouMediaResolution> resolve({
    required ProviderTrackRef track,
    required AudioQuality requestedQuality,
    required KugouMediaUse use,
  }) async {
    final hash = track.trackId;
    final albumId = track.extraIds['albumId'] ?? '';

    try {
      final response = await _client.get(
        Uri.parse('https://wwwapi.kugou.com/yy/index.php').replace(
          queryParameters: {
            'r': 'play/getdata',
            'hash': hash,
            if (albumId.isNotEmpty) 'album_id': albumId,
          },
        ),
        attachSessionCookie: true,
      );

      final errCode = response['err_code'] as int? ?? 0;
      final rawData = response['data'];
      final data = rawData is Map<String, dynamic> ? rawData : null;
      final playUrl = data?['play_url']?.toString() ?? '';

      if (errCode == 20010 || errCode == 20003 || playUrl.isEmpty) {
        try {
          return await _resolveLegacyPlayInfo(hash: hash);
        } on ProviderException catch (legacyError) {
          return _resolveAuthenticatedFallbacks(
            track: track,
            hash: hash,
            requestedQuality: requestedQuality,
            legacyError: legacyError,
          );
        }
      }
      if (errCode != 0 || playUrl.isEmpty) {
        throw ProviderException(
          providerId: _providerId,
          message:
              'MediaUnavailable: This track is not available (err_code: $errCode).',
        );
      }

      final fileSize = data?['filesize'] as int? ?? 0;
      final bitrate = data?['bitrate'] as int? ?? 128;
      final actualQuality = _mapBitrateToQuality(bitrate);

      return KugouMediaResolution(
        url: Uri.parse(playUrl),
        quality: actualQuality,
        format: playUrl.split('.').last.split('?').first.toLowerCase(),
        fileSize: fileSize,
        expiresAt:
            DateTime.now().add(const Duration(hours: 1)), // conservative TTL
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );
    } on ProviderException {
      rethrow;
    } catch (e) {
      throw ProviderException(
        providerId: _providerId,
        message: 'Failed to resolve Kugou media: $e',
      );
    }
  }

  Future<KugouMediaResolution> _resolveLegacyPlayInfo({
    required String hash,
  }) async {
    final response = await _client.get(
      Uri.parse('http://m.kugou.com/app/i/getSongInfo.php').replace(
        queryParameters: {
          'cmd': 'playInfo',
          'hash': hash,
        },
      ),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1',
        'Referer': 'http://m.kugou.com',
        ..._randomChinaIpHeaders(),
      },
      attachSessionCookie: true,
    );

    final errCode = response['errcode'] as int? ?? response['err_code'] as int?;
    final playUrl = _pickKugouResponseUrl(response);

    if ((errCode != null && errCode != 0) || playUrl.isEmpty) {
      throw ProviderException(
        providerId: _providerId,
        message:
            'MediaUnavailable: This track is not available (err_code: $errCode).',
      );
    }

    final bitrate = response['bitRate'] as int? ??
        response['bitrate'] as int? ??
        response['bit_rate'] as int? ??
        128;
    final actualQuality = _mapBitrateToQuality(bitrate);
    final fileSize = response['fileSize'] as int? ??
        response['filesize'] as int? ??
        response['size'] as int? ??
        0;
    final extName = response['extName']?.toString().toLowerCase();

    return KugouMediaResolution(
      url: Uri.parse(playUrl),
      quality: actualQuality,
      format: extName == null || extName.isEmpty
          ? playUrl.split('.').last.split('?').first.toLowerCase()
          : extName,
      fileSize: fileSize,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );
  }

  Future<KugouMediaResolution> _resolveAuthenticatedFallbacks({
    required ProviderTrackRef track,
    required String hash,
    required AudioQuality requestedQuality,
    ProviderException? legacyError,
  }) async {
    final failures = <String>[
      if (legacyError != null) _fallbackFailureMessage('legacy', legacyError),
    ];

    for (final candidate in _candidateHashes(track, hash)) {
      for (final attempt in <Future<KugouMediaResolution> Function()>[
        () => _resolveV5Url(
              track: track,
              hash: candidate.hash,
              requestedQuality: requestedQuality,
              kugouQualityOverride: candidate.v5Quality,
            ),
        () => _resolvePrivUrlV6(
              track: track,
              hash: candidate.hash,
            ),
        () => _resolveSonginfoV2(hash: candidate.hash),
        () => _resolveTrackerSongInfo(hash: candidate.hash),
      ]) {
        try {
          return await attempt();
        } on ProviderException catch (e) {
          failures.add(
            _fallbackFailureMessage(
              'fallback:${candidate.label}',
              e,
            ),
          );
        }
      }
    }

    throw ProviderException(
      providerId: _providerId,
      message: 'MediaUnavailable: Kugou returned no playable URL from '
          'play/getdata, legacy playInfo, v5/url, v6/priv_url, '
          'songinfo v2, or tracker. '
          'Failures: ${failures.join(' | ')}',
    );
  }

  String _fallbackFailureMessage(String label, ProviderException error) {
    return '$label=${error.message.replaceAll('\n', ' ')}';
  }

  List<({String hash, String label, String? v5Quality})> _candidateHashes(
    ProviderTrackRef track,
    String primaryHash,
  ) {
    final candidates = <({String? hash, String label, String? v5Quality})>[
      (hash: primaryHash, label: 'hash', v5Quality: 'flac'),
      (hash: track.extraIds['sqHash'], label: 'sqHash', v5Quality: 'flac'),
      (hash: track.extraIds['hqHash'], label: 'hqHash', v5Quality: 'flac'),
      (hash: track.extraIds['resHash'], label: 'resHash', v5Quality: 'flac'),
      (
        hash: track.extraIds['ogg320Hash'],
        label: 'ogg320Hash',
        v5Quality: 'flac'
      ),
      (hash: track.extraIds['fileHash'], label: 'fileHash', v5Quality: 'flac'),
      (
        hash: track.extraIds['ogg128Hash'],
        label: 'ogg128Hash',
        v5Quality: 'flac'
      ),
      (hash: track.trackId, label: 'trackId', v5Quality: 'flac'),
    ];
    final seen = <String>{};
    final result = <({String hash, String label, String? v5Quality})>[];
    for (final candidate in candidates) {
      final normalized = candidate.hash?.trim().toLowerCase() ?? '';
      if (!_isKugouHash(normalized) || !seen.add(normalized)) {
        continue;
      }
      result.add((
        hash: normalized,
        label: candidate.label,
        v5Quality: candidate.v5Quality,
      ));
    }
    return result;
  }

  bool _isKugouHash(String value) {
    return RegExp(r'^[a-f0-9]{32}$').hasMatch(value) &&
        value != '00000000000000000000000000000000';
  }

  Future<KugouMediaResolution> _resolveV5Url({
    required ProviderTrackRef track,
    required String hash,
    required AudioQuality requestedQuality,
    String? kugouQualityOverride,
  }) async {
    final normalizedHash = hash.toLowerCase();
    final albumId = track.extraIds['albumId'] ?? '0';
    final albumAudioId = track.extraIds['mixSongId'] ??
        track.extraIds['albumAudioId'] ??
        track.extraIds['audioId'] ??
        '0';

    final kugouQuality =
        kugouQualityOverride ?? _kugouQualityFor(requestedQuality);
    final response = await _client.androidGatewayGet(
      '/v5/url',
      authenticated: true,
      headers: const {'x-router': 'trackercdn.kugou.com'},
      sessionParams: (userId, token, mid) => {
        if (userId != '0' && mid.isNotEmpty)
          'key': _v5Key(normalizedHash, mid, userId),
      },
      params: {
        'album_id': albumId.isEmpty ? '0' : albumId,
        'area_code': 1,
        'hash': normalizedHash,
        'ssa_flag': 'is_fromtrack',
        'version': 11436,
        'clientver': 11440,
        'page_id': 967177915,
        'quality': kugouQuality,
        'album_audio_id': albumAudioId.isEmpty ? '0' : albumAudioId,
        'behavior': 'play',
        'pid': 411,
        'cmd': 26,
        'pidversion': 3001,
        'IsFreePart': 0,
        'ppage_id': '356753938,823673182,967485191',
        'cdnBackup': 1,
        'kcard': 0,
        'module': '',
      },
    );
    final playUrl = _pickKugouResponseUrl(response);
    if (playUrl.isEmpty) {
      // error_code 20006 = the requested quality is not available for this
      // account/track (typically VIP-only FLAC on a free account). Per doc
      // §6.2 we do not silently downgrade; surface the condition so the UI
      // can tell the user their requested tier is unavailable.
      final errCode = response['error_code'] ??
          response['errcode'] ??
          response['err_code'] ??
          0;
      if (errCode.toString() == '20006') {
        throw ProviderException(
          providerId: _providerId,
          message:
              'QualityUnavailable: Kugou rejected quality=$kugouQuality for '
              'this track (error_code: 20006). Try a lower quality tier.',
        );
      }
      throw ProviderException(
        providerId: _providerId,
        message:
            'MediaUnavailable: Kugou v5 url is not available (error_code: $errCode).',
      );
    }

    final bitrate = response['bitrate'] as int? ??
        response['bitRate'] as int? ??
        _nestedInt(response['data'], const ['bitrate', 'bitRate']) ??
        128;
    return KugouMediaResolution(
      url: Uri.parse(playUrl),
      quality: _mapBitrateToQuality(bitrate),
      format: _formatFromResponse(response, playUrl),
      fileSize: response['fileSize'] as int? ??
          response['filesize'] as int? ??
          _nestedInt(response['data'], const ['fileSize', 'filesize']) ??
          0,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );
  }

  Future<KugouMediaResolution> _resolvePrivUrlV6({
    required ProviderTrackRef track,
    required String hash,
  }) async {
    final normalizedHash = hash.toLowerCase();
    var albumAudioId = track.extraIds['mixSongId'] ??
        track.extraIds['albumAudioId'] ??
        track.extraIds['audioId'] ??
        '';
    if (albumAudioId.trim().isEmpty || albumAudioId == '0') {
      albumAudioId = await _lookupSonginfoAlbumAudioId(normalizedHash) ?? '0';
    }
    final response = await _client.androidGatewayPost(
      '/v6/priv_url',
      authenticated: true,
      endpoint: Uri.parse('http://tracker.kugou.com/v6/priv_url'),
      data: const {},
      deviceBodyBuilder: (userId, token, mid, vipToken, vipType, data) {
        final effectiveVipType = vipType.isEmpty ? '6' : vipType;
        return <String, Object?>{
          'area_code': '1',
          'behavior': 'play',
          'qualities': _v6Qualities(),
          'resource': <String, Object?>{
            'album_audio_id': albumAudioId.trim().isEmpty ? '0' : albumAudioId,
            'collect_list_id': '3',
            'collect_time': DateTime.now().millisecondsSinceEpoch,
            'hash': normalizedHash,
            'id': 0,
            'page_id': 1,
            'type': 'audio',
          },
          'token': token,
          'tracker_param': <String, Object?>{
            'all_m': 1,
            'auth': '',
            'is_free_part': 0,
            'key': _v5Key(normalizedHash, mid, userId),
            'module_id': 0,
            'need_climax': 1,
            'need_xcdn': 1,
            'open_time': '',
            'pid': '411',
            'pidversion': '3001',
            'priv_vip_type': '6',
            'viptoken': vipToken,
          },
          'userid': userId,
          'vip': effectiveVipType,
        };
      },
    );

    final playUrl = _pickKugouResponseUrl(response);
    if (playUrl.isEmpty) {
      final errCode = response['error_code'] ??
          response['errcode'] ??
          response['err_code'] ??
          _nestedInt(response['data'], const ['error_code', 'errcode']) ??
          0;
      throw ProviderException(
        providerId: _providerId,
        message:
            'MediaUnavailable: Kugou v6 priv_url is not available (error_code: $errCode).',
      );
    }

    final bitrate = response['bitrate'] as int? ??
        response['bitRate'] as int? ??
        _nestedInt(response['data'], const ['bitrate', 'bitRate']) ??
        _bitrateFromUrl(playUrl);
    return KugouMediaResolution(
      url: Uri.parse(playUrl),
      quality: _mapBitrateToQuality(bitrate),
      format: _formatFromResponse(response, playUrl),
      fileSize: response['fileSize'] as int? ??
          response['filesize'] as int? ??
          _nestedInt(response['data'], const ['fileSize', 'filesize']) ??
          0,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );
  }

  Future<String?> _lookupSonginfoAlbumAudioId(String hash) async {
    try {
      final response = await _client.songinfoV2Get(hash: hash);
      final data = _mapValue(response['data']);
      final raw = data['album_audio_id'] ?? data['audio_id'];
      final value = _formatNumericString(raw);
      return value.isEmpty ? null : value;
    } on ProviderException {
      return null;
    }
  }

  Future<KugouMediaResolution> _resolveSonginfoV2({
    required String hash,
  }) async {
    final normalizedHash = hash.toLowerCase();
    final step1 = await _client.songinfoV2Get(hash: normalizedHash);
    final step1Data = _mapValue(step1['data']);
    final encodeAlbumAudioId =
        step1Data['encode_album_audio_id']?.toString().trim() ?? '';
    if (encodeAlbumAudioId.isEmpty) {
      throw ProviderException(
        providerId: _providerId,
        message:
            'MediaUnavailable: Kugou songinfo v2 missing encode_album_audio_id.',
      );
    }

    final step2 =
        await _client.songinfoV2Get(encodeAlbumAudioId: encodeAlbumAudioId);
    final data = _mapValue(step2['data']);
    final playUrl = (data['play_url']?.toString().trim().isNotEmpty == true
            ? data['play_url']
            : data['play_backup_url'])
        ?.toString()
        .trim()
        .replaceAll(r'\/', '/');
    if (playUrl == null || playUrl.isEmpty) {
      final status = step2['status'] ?? step2['error_code'] ?? 0;
      throw ProviderException(
        providerId: _providerId,
        message:
            'MediaUnavailable: Kugou songinfo v2 play URL is not available (status: $status).',
      );
    }

    final bitrate = _intFromValue(data['bitrate']) ?? _bitrateFromUrl(playUrl);
    return KugouMediaResolution(
      url: Uri.parse(playUrl),
      quality: _mapBitrateToQuality(bitrate),
      format:
          (data['extname']?.toString().trim().toLowerCase().isNotEmpty == true)
              ? data['extname'].toString().trim().toLowerCase()
              : playUrl.split('.').last.split('?').first.toLowerCase(),
      fileSize: _intFromValue(data['filesize']) ?? 0,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );
  }

  Future<KugouMediaResolution> _resolveTrackerSongInfo({
    required String hash,
  }) async {
    final normalizedHash = hash.toLowerCase();
    final kgCloudV2 = _md5('$normalizedHash' 'kgcloudv2');
    final kgCloud = _md5('$normalizedHash' 'kgcloud');
    final uris = <Uri>[
      Uri.parse('https://trackercdn.kugou.com/i/v2/').replace(
        queryParameters: {
          'cdnBackup': '1',
          'behavior': 'download',
          'pid': '1',
          'cmd': '21',
          'appid': '1001',
          'hash': normalizedHash,
          'key': kgCloudV2,
        },
      ),
      Uri.parse('http://trackercdnbj.kugou.com/i/v2/').replace(
        queryParameters: {
          'cmd': '23',
          'pid': '1',
          'behavior': 'download',
          'hash': normalizedHash,
          'key': kgCloudV2,
        },
      ),
      Uri.parse('http://trackercdn.kugou.com/i/').replace(
        queryParameters: {
          'cmd': '4',
          'pid': '1',
          'forceDown': '0',
          'vip': '1',
          'hash': normalizedHash,
          'key': kgCloud,
        },
      ),
    ];

    ProviderException? lastError;
    for (final uri in uris) {
      try {
        final response = await _client.get(
          uri,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
            'Referer': 'https://www.kugou.com/',
          }..addAll(_randomChinaIpHeaders()),
          attachSessionCookie: true,
        );
        final errCode = response['errcode'] ?? response['error_code'] ?? 0;
        final playUrl = _pickKugouResponseUrl(response);
        if (errCode.toString() != '0' || playUrl.isEmpty) {
          lastError = ProviderException(
            providerId: _providerId,
            message:
                'MediaUnavailable: Kugou tracker URL is not available (error_code: $errCode).',
          );
          continue;
        }
        final bitrate = response['bitRate'] as int? ??
            response['bitrate'] as int? ??
            _bitrateFromUrl(playUrl);
        return KugouMediaResolution(
          url: Uri.parse(playUrl),
          quality: _mapBitrateToQuality(bitrate),
          format: _formatFromResponse(response, playUrl),
          fileSize:
              response['fileSize'] as int? ?? response['filesize'] as int? ?? 0,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        );
      } on ProviderException catch (e) {
        lastError = e;
      }
    }

    throw lastError ??
        ProviderException(
          providerId: _providerId,
          message: 'MediaUnavailable: Kugou tracker URL is not available.',
        );
  }

  AudioQuality _mapBitrateToQuality(int bitrate) {
    if (bitrate >= 1000) return AudioQuality.lossless;
    if (bitrate >= 320) return AudioQuality.high;
    if (bitrate >= 192) return AudioQuality.standard;
    return AudioQuality.low;
  }

  /// Maps MeloUnion's requested quality tier to the Kugou /v5/url `quality`
  /// vocabulary. Kugou accepts: `128`, `320`, `flac`, `high`, `super`, `sq`.
  /// We request the tier that matches user intent rather than always asking
  /// for FLAC — asking a free account for FLAC yields error_code 20006.

  List<String> _v6Qualities() {
    return const <String>[
      '128',
      '320',
      'flac',
      'high',
      'multitrack',
      'viper_atmos',
      'viper_tape',
      'viper_clear',
      'super',
    ];
  }

  int _bitrateFromUrl(String playUrl) {
    final lower = playUrl.toLowerCase();
    if (lower.contains('.flac') || lower.contains('/flac')) return 1000;
    if (lower.contains('320')) return 320;
    if (lower.contains('128')) return 128;
    return 128;
  }

  String _md5(String value) =>
      crypto.md5.convert(utf8.encode(value)).toString();

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

  String _kugouQualityFor(AudioQuality requested) {
    switch (requested) {
      case AudioQuality.lossless:
        return 'flac';
      case AudioQuality.high:
        return '320';
      case AudioQuality.standard:
        return '128';
      case AudioQuality.low:
        return '128';
    }
  }

  String _firstUrl(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List<dynamic>) {
      for (final item in value) {
        final url = _firstUrl(item);
        if (url.isNotEmpty) return url;
      }
      return '';
    }
    if (value is Map<dynamic, dynamic>) {
      for (final item in value.values) {
        final url = _firstUrl(item);
        if (url.isNotEmpty) return url;
      }
      return '';
    }
    return value.toString();
  }

  String _v5Key(String hash, String mid, String userId) {
    const salt = '185672dd44712f60bb1736df5a377e82';
    return crypto.md5
        .convert(utf8.encode('${hash}$salt' '3116$mid$userId'))
        .toString();
  }

  String _pickKugouResponseUrl(Map<String, dynamic> response) {
    final deepUrl = _pickKugouUrlDeep(response);
    if (deepUrl.isNotEmpty) return deepUrl;

    for (final key in const ['url', 'backup_url']) {
      final url = _firstUrl(response[key]).replaceAll(r'\/', '/');
      if (url.isNotEmpty) return url;
    }
    final data = response['data'];
    if (data is Map) {
      for (final key in const ['url', 'backup_url']) {
        final url = _firstUrl(data[key]).replaceAll(r'\/', '/');
        if (url.isNotEmpty) return url;
      }
      for (final quality in const ['flac', 'high', '320', '128', 'super']) {
        final item = data[quality];
        if (item is Map) {
          for (final key in const ['url', 'backup_url']) {
            final url = _firstUrl(item[key]).replaceAll(r'\/', '/');
            if (url.isNotEmpty) return url;
          }
        }
      }
    }
    return '';
  }

  String _pickKugouUrlDeep(Object? value) {
    if (value is Map) {
      for (final key in const [
        'url',
        'backup_url',
        'play_url',
        'play_backup_url',
      ]) {
        final url = _firstNonEmptyUrl([
          _firstUrl(value[key]),
          _urlFromJsonText(value[key]),
        ]);
        if (_looksPlayableUrl(url)) return url;
      }
      for (final item in value.values) {
        final url = _pickKugouUrlDeep(item);
        if (url.isNotEmpty) return url;
      }
    }
    if (value is List) {
      for (final item in value) {
        final url = _pickKugouUrlDeep(item);
        if (url.isNotEmpty) return url;
      }
    }
    return '';
  }

  bool _looksPlayableUrl(String value) {
    final lower = value.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return false;
    }
    return lower.contains('.mp3') ||
        lower.contains('.flac') ||
        lower.contains('.m4a') ||
        lower.contains('/fs/') ||
        lower.contains('fs.') ||
        lower.contains('kugou.com');
  }

  String _firstNonEmptyUrl(Iterable<String> values) {
    for (final value in values) {
      final normalized = value.replaceAll(r'\/', '/').trim();
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  String _urlFromJsonText(Object? value) {
    if (value == null) return '';
    final text = jsonEncode(value).replaceAll(r'\/', '/');
    final match = RegExp(r'https?://[^"\\\]\s]+').firstMatch(text);
    return match?.group(0) ?? '';
  }

  int? _nestedInt(Object? value, List<String> keys) {
    if (value is! Map) return null;
    for (final key in keys) {
      final raw = value[key];
      final parsed = _intFromValue(raw);
      if (parsed != null) return parsed;
    }
    return null;
  }

  int? _intFromValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Map<String, Object?> _mapValue(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  String _formatNumericString(Object? value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    if (value is num) return value.toInt().toString();
    return value.toString().trim();
  }

  String _formatFromResponse(Map<String, dynamic> response, String playUrl) {
    final text = (response['fileType'] ??
            response['extName'] ??
            response['extname'] ??
            _nestedString(
                response['data'], const ['fileType', 'extName', 'extname']))
        ?.toString()
        .toLowerCase();
    if (text != null && text.isNotEmpty) return text;
    return playUrl.split('.').last.split('?').first.toLowerCase();
  }

  Object? _nestedString(Object? value, List<String> keys) {
    if (value is! Map) return null;
    for (final key in keys) {
      final raw = value[key];
      if (raw != null && raw.toString().trim().isNotEmpty) return raw;
    }
    return null;
  }
}
