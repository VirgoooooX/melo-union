import 'dart:convert';
import 'dart:io';

import 'package:provider_contract/provider_contract.dart';
import 'package:provider_kugou/provider_kugou.dart';

const _sessionEnv = 'MELO_KUGOU_SESSION';

Future<void> main(List<String> args) async {
  final limit = _intArg(args, '--limit') ?? 20;
  final query = _stringArg(args, '--query') ?? '周杰伦';
  final includeFavorites = !args.contains('--skip-favorites');
  final quality = _qualityArg(args) ?? AudioQuality.standard;
  final session = _sessionFromEnvironment();
  final store = _MemoryKugouSessionStore(session);
  final provider = KugouMusicProvider.create(
    secureStore: store,
    initialSession: session,
  );

  print('=== Kugou live playback smoke ===');
  print('authenticated=${provider.isAuthenticated}');
  print('quality=${quality.name}');
  print('limit=$limit');

  if (provider.isAuthenticated) {
    try {
      final profile = await provider.getProfile();
      print('profile=${profile?.displayName ?? '(unknown)'}');
    } catch (error) {
      print('profile=ERROR ${_short(error)}');
    }
  }

  final candidates = <_Candidate>[];

  if (includeFavorites && provider.isAuthenticated) {
    try {
      final favorites = await provider.pullFavorites(forceRefresh: true);
      print('favorites=${favorites.tracks.length} partial=${favorites.partialFailureReason != null}');
      candidates.addAll(favorites.tracks.take(limit).map((track) => _Candidate('favorites', track)));
    } catch (error) {
      print('favorites=ERROR ${_short(error)}');
    }
  }

  final recommended = await provider.getDailyRecommendations();
  print('daily=${recommended.length}');
  candidates.addAll(recommended.take(limit).map((track) => _Candidate('daily', track)));

  final playlists = await provider.getRecommendedPlaylists();
  print('playlists=${playlists.length}');
  if (playlists.isNotEmpty) {
    final first = playlists.first;
    print('playlists.first=${first.name} ${first.playlistId}');
    final tracks = await provider.getPlaylistTracks(first.playlistId);
    print('playlists.first.tracks=${tracks.length}');
    candidates.addAll(tracks.take(limit).map((track) => _Candidate('playlist:${first.name}', track)));
  }

  final charts = await provider.getChartPlaylists(limit: 3);
  print('charts=${charts.length}');
  if (charts.isNotEmpty) {
    final first = charts.first;
    print('charts.first=${first.name} ${first.playlistId}');
    final tracks = await provider.getPlaylistTracks(first.playlistId);
    print('charts.first.tracks=${tracks.length}');
    candidates.addAll(tracks.take(limit).map((track) => _Candidate('chart:${first.name}', track)));
  }

  final search = await provider.search(query);
  print('search[$query]=${search.length}');
  candidates.addAll(search.take(limit).map((track) => _Candidate('search:$query', track)));

  final seen = <ProviderTrackRef>{};
  final unique = <_Candidate>[];
  for (final candidate in candidates) {
    if (seen.add(candidate.track.ref)) unique.add(candidate);
  }

  var ok = 0;
  final failures = <String>[];
  for (final candidate in unique.take(limit * 4)) {
    final result = await _checkPlayback(provider, candidate, quality);
    print(result.line);
    if (result.ok) {
      ok++;
    } else {
      failures.add(result.line);
    }
  }

  print('summary=ok:$ok fail:${failures.length} total:${ok + failures.length}');
  if (failures.isNotEmpty) {
    exitCode = 2;
  }
}

final class _MemoryKugouSessionStore implements KugouSecureSessionStore {
  _MemoryKugouSessionStore([this._session]);

  KugouSession? _session;

  @override
  Future<void> clear() async {
    _session = null;
  }

  @override
  Future<KugouSession?> read() async => _session;

  @override
  Future<void> write(KugouSession session) async {
    _session = session;
  }
}

final class _Candidate {
  const _Candidate(this.source, this.track);

  final String source;
  final SourceTrack track;
}

final class _PlaybackCheck {
  const _PlaybackCheck({required this.ok, required this.line});

  final bool ok;
  final String line;
}

Future<_PlaybackCheck> _checkPlayback(
  KugouMusicProvider provider,
  _Candidate candidate,
  AudioQuality quality,
) async {
  final track = candidate.track;
  try {
    final ticket = await provider.createPlaybackTicket(
      track: track.ref,
      quality: quality,
    );
    final probe = await _probe(ticket.mediaUri, ticket.headers);
    final ok = probe.startsWith('HTTP 2') || probe.startsWith('HTTP 206');
    return _PlaybackCheck(
      ok: ok,
      line:
          '${ok ? 'OK' : 'BAD'} [${candidate.source}] ${_trackLabel(track)} '
          'q=${ticket.quality.name} fmt=${_safe(ticket.mediaUri.path.split('.').last)} '
          'host=${ticket.mediaUri.host} probe=$probe',
    );
  } catch (error) {
    return _PlaybackCheck(
      ok: false,
      line: 'FAIL [${candidate.source}] ${_trackLabel(track)} ${_short(error)}',
    );
  }
}

Future<String> _probe(Uri uri, Map<String, String> headers) async {
  if (!uri.isScheme('http') && !uri.isScheme('https')) {
    return 'unsupported:${uri.scheme}';
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(uri);
    request.headers.add(HttpHeaders.rangeHeader, 'bytes=0-0');
    headers.forEach(request.headers.add);
    final response = await request.close().timeout(const Duration(seconds: 12));
    await response.drain<List<int>>(<int>[]);
    return 'HTTP ${response.statusCode} bytes=${response.contentLength}';
  } finally {
    client.close(force: true);
  }
}

KugouSession? _sessionFromEnvironment() {
  final raw = Platform.environment[_sessionEnv];
  if (raw == null || raw.trim().isEmpty) return null;
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('MELO_KUGOU_SESSION must be a JSON object.');
  }
  return KugouSession.fromJson(decoded);
}

AudioQuality? _qualityArg(List<String> args) {
  final raw = _stringArg(args, '--quality');
  if (raw == null) return null;
  return AudioQuality.values.byName(raw);
}

int? _intArg(List<String> args, String name) {
  final raw = _stringArg(args, name);
  return raw == null ? null : int.tryParse(raw);
}

String? _stringArg(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == name && i + 1 < args.length) return args[i + 1];
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}

String _trackLabel(SourceTrack track) {
  final artists = track.artists.join('/');
  return '${_safe(track.title)} - ${_safe(artists)} hash=${_fingerprint(track.ref.trackId)}';
}

String _short(Object error) {
  final text = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  return text.length <= 220 ? text : '${text.substring(0, 220)}...';
}

String _safe(String value) => value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();

String _fingerprint(String value) {
  if (value.length <= 8) return '***';
  return '${value.substring(0, 4)}***${value.substring(value.length - 4)}';
}
