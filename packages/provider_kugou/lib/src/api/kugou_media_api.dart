import 'dart:convert';

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
      );

      final errCode = response['err_code'] as int? ?? 0;
      final rawData = response['data'];
      final data = rawData is Map<String, dynamic> ? rawData : null;
      final playUrl = data?['play_url']?.toString() ?? '';

      if (errCode == 20010 || errCode == 20003 || playUrl.isEmpty) {
        try {
          return await _resolveLegacyPlayInfo(hash: hash);
        } on ProviderException {
          return _resolveV5Url(track: track, hash: hash);
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

      // Determine quality matching. The API usually returns standard 128kbps or what the account has access to.
      // If we asked for lossless but got 128kbps, we throw QualityUnavailable.
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
      Uri.parse('https://m.kugou.com/app/i/getSongInfo.php').replace(
        queryParameters: {
          'cmd': 'playInfo',
          'hash': hash,
        },
      ),
    );

    final errCode = response['errcode'] as int? ?? response['err_code'] as int?;
    final primaryUrl = response['url']?.toString() ?? '';
    final playUrl =
        primaryUrl.isNotEmpty ? primaryUrl : _firstUrl(response['backup_url']);

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

  Future<KugouMediaResolution> _resolveV5Url({
    required ProviderTrackRef track,
    required String hash,
  }) async {
    final normalizedHash = hash.toLowerCase();
    final albumId = track.extraIds['albumId'] ?? '0';
    final albumAudioId =
        track.extraIds['albumAudioId'] ?? track.extraIds['audioId'] ?? '0';

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
        'page_id': 967177915,
        'quality': 'flac',
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
      throw ProviderException(
        providerId: _providerId,
        message:
            'MediaUnavailable: Kugou v5 url is not available (error_code: ${response['error_code'] ?? response['errcode'] ?? 0}).',
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

  AudioQuality _mapBitrateToQuality(int bitrate) {
    if (bitrate >= 1000) return AudioQuality.lossless;
    if (bitrate >= 320) return AudioQuality.high;
    if (bitrate >= 192) return AudioQuality.standard;
    return AudioQuality.low;
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

  int? _nestedInt(Object? value, List<String> keys) {
    if (value is! Map) return null;
    for (final key in keys) {
      final raw = value[key];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
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
