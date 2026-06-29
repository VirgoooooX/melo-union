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
      displayName: '网易云音乐',
      capabilities: {
        ProviderCapability.search,
        ProviderCapability.artwork,
        ProviderCapability.resolvePlayback,
        ProviderCapability.resolveDownload,
        ProviderCapability.lyrics,
        if (credentials?.hasCookie ?? false) ...{
          ProviderCapability.authenticate,
          ProviderCapability.readFavorites,
          ProviderCapability.writeFavorites,
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

    // 1. Fetch user's playlists to locate the "Liked Music" playlist ID (always the first one)
    final playlistsPayload = await _getJson(
      '/api/user/playlist',
      query: {
        'uid': userId,
        'limit': '1',
      },
      authenticated: true,
    );
    final playlists = playlistsPayload['playlist'] as List<Object?>? ?? const [];
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
        'n': '0', // Minimal chunk tracks returned, we use trackIds for full listing
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

    // 3. Fetch song details in chunks of 200
    final tracks = <SourceTrack>[];
    for (final chunk in _chunks(ids, 200)) {
      tracks.addAll(
        await _songDetails(chunk, favoritedIds: ids.toSet()),
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
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _requireCapability(ProviderCapability.resolvePlayback);
    final br = quality == AudioQuality.high ? 320000 : 128000;
    final resolvedUrl = await _resolvePlayerUrl(track.trackId, br);
    final playUri = resolvedUrl != null
        ? Uri.parse(resolvedUrl).replace(scheme: 'https')
        : Uri.parse('https://music.163.com/song/media/outer/url?id=${track.trackId}.mp3');
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
    final br = quality == AudioQuality.high ? 320000 : 128000;
    final resolvedUrl = await _resolvePlayerUrl(track.trackId, br);
    final downloadUri = resolvedUrl != null
        ? Uri.parse(resolvedUrl).replace(scheme: 'https')
        : Uri.parse('https://music.163.com/song/media/outer/url?id=${track.trackId}.mp3');
    return DownloadTicket(
      mediaUri: downloadUri,
      headers: _headers(authenticated: isAuthenticated),
      expiresAt: _now().add(const Duration(hours: 12)),
      trackRef: track,
      quality: quality,
      fileExtension: 'mp3',
    );
  }

  Future<String?> _resolvePlayerUrl(String songId, int br) async {
    try {
      final payload = await _getJson(
        '/api/song/enhance/player/url',
        query: {
          'id': songId,
          'ids': '[$songId]',
          'br': br.toString(),
        },
        authenticated: isAuthenticated,
      );
      final data = payload['data'] as List<Object?>? ?? const [];
      if (data.isNotEmpty) {
        final item = data.first as Map<Object?, Object?>?;
        if (item != null) {
          final url = item['url'] as String?;
          if (url != null && url.isNotEmpty) {
            return url;
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
