import 'dart:convert';
import 'package:provider_contract/provider_contract.dart';
import 'kugou_api_client.dart';

final class KugouLyricsApi {
  KugouLyricsApi({required KugouApiClient client}) : _client = client;

  final KugouApiClient _client;

  Future<String?> getLyrics(ProviderTrackRef track) async {
    final hash = track.trackId;

    try {
      // 1. Search for lyric candidates by hash
      final searchResponse = await _client.get(
        Uri.parse('http://lyrics.kugou.com/search').replace(
          queryParameters: {
            'ver': '1',
            'man': 'yes',
            'client': 'pc',
            'hash': hash,
          },
        ),
      );

      final candidates = searchResponse['candidates'] as List<dynamic>? ?? [];
      if (candidates.isEmpty) return null;

      // Find candidate matching hash or default to first
      final bestCandidate = candidates.firstWhere(
        (c) => c['soundhash']?.toString().toLowerCase() == hash.toLowerCase(),
        orElse: () => candidates.first,
      );

      final id = bestCandidate['id']?.toString() ?? '';
      final accesskey = bestCandidate['accesskey']?.toString() ?? '';
      if (id.isEmpty || accesskey.isEmpty) return null;

      // 2. Download and decode base64 lyrics (request format: lrc)
      final downloadResponse = await _client.get(
        Uri.parse('http://lyrics.kugou.com/download').replace(
          queryParameters: {
            'ver': '1',
            'client': 'pc',
            'id': id,
            'accesskey': accesskey,
            'fmt': 'lrc',
          },
        ),
      );

      final status = downloadResponse['status'] as int? ?? 0;
      if (status != 200) return null;

      final contentBase64 = downloadResponse['content']?.toString() ?? '';
      if (contentBase64.isEmpty) return null;

      final decodedBytes = base64Decode(contentBase64);
      return utf8.decode(decodedBytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
}
