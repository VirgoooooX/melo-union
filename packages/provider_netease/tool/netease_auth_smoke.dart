import 'dart:io';

import 'package:provider_contract/provider_contract.dart';
import 'package:provider_netease/provider_netease.dart';

const _cookieEnv = 'MELO_NETEASE_COOKIE';
const _userIdEnv = 'MELO_NETEASE_USER_ID';
const _mutationTrackEnv = 'MELO_NETEASE_MUTATION_TRACK_ID';

Future<void> main(List<String> args) async {
  if (args.contains('--help')) {
    _printUsage();
    return;
  }

  final cookie = Platform.environment[_cookieEnv]?.trim();
  if (cookie == null || cookie.isEmpty) {
    throw StateError('Set $_cookieEnv before running authenticated smoke.');
  }

  final query = _optionValue(args, '--query') ?? '孤勇者';
  final mutationTrackId = _optionValue(args, '--mutate-track-id') ??
      Platform.environment[_mutationTrackEnv]?.trim();

  final provider = NeteaseMusicProvider(
    credentials: NeteaseCredentials(
      cookie: cookie,
      userId: _blankToNull(Platform.environment[_userIdEnv]),
    ),
  );

  final profile = await provider.getProfile();
  final favorites = await provider.pullFavorites(forceRefresh: true);
  final playlists = await provider.getUserPlaylists();
  final firstPlaylistTracks = playlists.isEmpty
      ? const <SourceTrack>[]
      : await provider.getPlaylistTracks(playlists.first.playlistId);
  final recommendations = await provider.getDailyRecommendations();
  final recommendedPlaylists = await provider.getRecommendedPlaylists();
  final searchResults = await provider.search(query);
  final target = _targetTrack(
    mutationTrackId: mutationTrackId,
    favorites: favorites.tracks,
    recommendations: recommendations,
    searchResults: searchResults,
  );
  final lyrics = await provider.getLyrics(target.ref);

  print('profile=${profile == null ? 'unknown' : 'present'}');
  print('favorites=${favorites.tracks.length}');
  print('playlists=${playlists.length}');
  print('firstPlaylistTracks=${firstPlaylistTracks.length}');
  print('recommendations=${recommendations.length}');
  print('recommendedPlaylists=${recommendedPlaylists.length}');
  print('search=${searchResults.length}');
  print('target=${target.ref.trackId}:${target.title}');
  print('lyrics=${lyrics == null || lyrics.isEmpty ? 'empty' : 'present'}');
  for (final quality in AudioQuality.values) {
    final playback = await provider.createPlaybackTicket(
      track: target.ref,
      quality: quality,
    );
    final download = await provider.createDownloadTicket(
      track: target.ref,
      quality: quality,
    );
    print(
      'quality.${quality.name}='
      '${playback.mediaUri.scheme}:${playback.mediaUri.host};'
      'ext=${download.fileExtension ?? 'unknown'};'
      'bytes=${download.bytes ?? 0}',
    );
  }

  if (mutationTrackId != null && mutationTrackId.isNotEmpty) {
    final wasLiked =
        favorites.tracks.any((track) => track.ref.trackId == mutationTrackId);
    await provider.setFavorite(track: target.ref, liked: !wasLiked);
    await provider.setFavorite(track: target.ref, liked: wasLiked);
    print('favoriteMutation=roundtrip-restored');
  } else {
    print('favoriteMutation=skipped');
  }
}

SourceTrack _targetTrack({
  required String? mutationTrackId,
  required List<SourceTrack> favorites,
  required List<SourceTrack> recommendations,
  required List<SourceTrack> searchResults,
}) {
  if (mutationTrackId != null && mutationTrackId.isNotEmpty) {
    for (final track in [...favorites, ...recommendations, ...searchResults]) {
      if (track.ref.trackId == mutationTrackId) {
        return track;
      }
    }
    return SourceTrack(
      ref: ProviderTrackRef(
        providerId: neteaseProviderId,
        trackId: mutationTrackId,
      ),
      title: 'Mutation target',
      artists: const [],
      duration: Duration.zero,
      isFavorited: false,
    );
  }
  if (favorites.isNotEmpty) return favorites.first;
  if (recommendations.isNotEmpty) return recommendations.first;
  if (searchResults.isNotEmpty) return searchResults.first;
  throw StateError('NetEase authenticated smoke found no target track.');
}

String? _optionValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  final value = args[index + 1].trim();
  return value.isEmpty ? null : value;
}

String? _blankToNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}

void _printUsage() {
  print('''
Authenticated NetEase smoke.

Required environment:
  MELO_NETEASE_COOKIE=<local account cookie>

Optional:
  MELO_NETEASE_USER_ID=<account user id>
  MELO_NETEASE_MUTATION_TRACK_ID=<track id to like/unlike and restore>

Usage:
  dart run tool/netease_auth_smoke.dart --query 孤勇者
  dart run tool/netease_auth_smoke.dart --mutate-track-id 1901371647
''');
}
