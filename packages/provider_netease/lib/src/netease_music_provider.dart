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

final class NeteaseMusicProvider implements MusicProvider {
  NeteaseMusicProvider({
    NeteaseCredentials? credentials,
    http.Client? client,
    Uri? baseUri,
    DateTime Function()? now,
  })  : _credentials = credentials,
        _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse('https://music.163.com'),
        _now = now ?? DateTime.now {
    descriptor = ProviderDescriptor(
      id: neteaseProviderId,
      displayName: 'NetEase Cloud Music',
      capabilities: {
        ProviderCapability.search,
        ProviderCapability.artwork,
        if (credentials?.hasCookie ?? false) ...{
          ProviderCapability.authenticate,
          ProviderCapability.readFavorites,
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
  final DateTime Function() _now;

  @override
  late final ProviderDescriptor descriptor;

  @override
  bool get isAuthenticated => _credentials?.hasCookie ?? false;

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

    final likedPayload = await _getJson(
      '/api/song/like/get',
      query: {'uid': userId},
      authenticated: true,
    );
    final rawIds = likedPayload['ids'] as List<Object?>? ?? const [];
    final ids = rawIds.map((id) => id.toString()).toList(growable: false);
    final tracks = <SourceTrack>[];
    for (final chunk in _chunks(ids, 200)) {
      tracks.addAll(
        await _songDetails(chunk, favoritedIds: ids.toSet()),
      );
    }
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
    return songs
        .whereType<Map<Object?, Object?>>()
        .map((song) => _trackFromSong(_stringMap(song)))
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
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _unsupported(ProviderCapability.resolvePlayback);
  }

  @override
  Future<DownloadTicket> createDownloadTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _unsupported(ProviderCapability.resolveDownload);
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
      duration:
          Duration(milliseconds: (song['duration'] as num?)?.toInt() ?? 0),
      isFavorited: favoritedIds.contains(id) || song['starred'] == true,
      artwork: _optionalUri(album['picUrl'] ?? album['blurPicUrl']),
      isPlayable: status == null || status == 0,
      isDownloadable: false,
      isrc: song['isrc']?.toString(),
    ).copyWith(
      isPlayable: (status == null || status == 0) && fee != 4,
    );
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
