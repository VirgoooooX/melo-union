import 'dart:io';

import 'package:provider_qq/provider_qq.dart';

const _cookieEnv = 'MELO_QQ_COOKIE';

Future<void> main(List<String> args) async {
  if (args.contains('--help')) {
    _printUsage();
    return;
  }

  final cookie = Platform.environment[_cookieEnv]?.trim();
  if (cookie == null || cookie.isEmpty) {
    throw StateError('Set $_cookieEnv before running QQ smoke.');
  }

  print('=== QQ Music Provider Diagnostic ===\n');

  final provider = QqMusicProvider(
    credentials: QqMusicCredentials(cookie: cookie),
  );

  // 1. Check capabilities
  print('Authenticated: ${provider.isAuthenticated}');
  print('Capabilities: ${provider.descriptor.capabilities.map((c) => c.name).join(', ')}');
  print('');

  // 2. Profile
  try {
    final profile = await provider.getProfile();
    print('[getProfile] OK: accountId=${profile?.accountId} displayName=${profile?.displayName}');
  } catch (e) {
    print('[getProfile] ERROR: $e');
  }
  print('');

  // 3. Pull Favorites
  try {
    final favorites = await provider.pullFavorites(forceRefresh: true);
    print('[pullFavorites] OK: count=${favorites.tracks.length}');
    for (var i = 0; i < favorites.tracks.length && i < 5; i++) {
      final t = favorites.tracks[i];
      print('  [$i] ${t.title} - ${t.artists.join(', ')} '
          '(src=${t.likedAtSource}, precision=${t.likedAtPrecision})');
    }
    if (favorites.tracks.isEmpty) {
      print('  (empty — API returned no songs)');
    } else if (favorites.tracks.length > 5) {
      print('  ... and ${favorites.tracks.length - 5} more');
    }
  } catch (e) {
    print('[pullFavorites] ERROR: $e');
  }
  print('');

  // 4. User Playlists
  try {
    final playlists = await provider.getUserPlaylists();
    print('[getUserPlaylists] OK: count=${playlists.length}');
    for (var i = 0; i < playlists.length && i < 10; i++) {
      final p = playlists[i];
      print('  [$i] id=${p.playlistId} name=${p.name} tracks=${p.trackCount} plays=${p.playCount}');
    }
    if (playlists.isEmpty) {
      print('  (empty)');
    }
  } catch (e) {
    print('[getUserPlaylists] ERROR: $e');
  }
  print('');

  // 5. Recommended Playlists
  try {
    final rec = await provider.getRecommendedPlaylists(limit: 5);
    print('[getRecommendedPlaylists] OK: count=${rec.length}');
    for (var i = 0; i < rec.length && i < 5; i++) {
      final p = rec[i];
      print('  [$i] id=${p.playlistId} name=${p.name} tracks=${p.trackCount}');
    }
  } catch (e) {
    print('[getRecommendedPlaylists] ERROR: $e');
  }
  print('');

  // 6. Daily Recommendations
  try {
    final daily = await provider.getDailyRecommendations();
    print('[getDailyRecommendations] OK: count=${daily.length}');
    for (var i = 0; i < daily.length && i < 3; i++) {
      final t = daily[i];
      print('  [$i] ${t.title} - ${t.artists.join(', ')}');
    }
  } catch (e) {
    print('[getDailyRecommendations] ERROR: $e');
  }
  print('');

  // 7. Raw cookie debug (keys only)
  final cookieKeys = cookie
      .split(';')
      .map((p) => p.trim().split('=').first.trim())
      .where((k) => k.isNotEmpty)
      .toList();
  print('Cookie keys (${cookieKeys.length}): ${cookieKeys.join(', ')}');
  print('Has uin: ${cookieKeys.any((k) => k == 'uin')}');
  print('Has qqmusic_key: ${cookieKeys.any((k) => k == 'qqmusic_key')}');

  print('\n=== Done ===');
}

void _printUsage() {
  print('''
QQ Music provider diagnostic.

Required environment:
  MELO_QQ_COOKIE=<login cookie from qqmusic_key=xxx; uin=xxx>

Usage:
  dart run tool/qq_smoke.dart
''');
}
