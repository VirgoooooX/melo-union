import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:provider_netease/provider_netease.dart';
import 'package:test/test.dart';

void main() {
  test('search maps real NetEase song JSON into SourceTrack', () async {
    final provider = NeteaseMusicProvider(
      client: MockClient((request) async {
        expect(request.headers['Cookie'], isNull);
        if (request.url.path == '/api/search/get/web') {
          expect(request.url.queryParameters['s'], '孤勇者');
          return _jsonResponse({
            'code': 200,
            'result': {
              'songs': [
                {
                  'id': 1901371647,
                  'name': '孤勇者',
                  'duration': 256000,
                  'status': 0,
                  'fee': 1,
                  'artists': [
                    {'id': 2116, 'name': '陈奕迅'},
                  ],
                  'album': {
                    'id': 137142551,
                    'name': '孤勇者',
                    'picId': 109951171836610847,
                  },
                },
              ],
            },
          });
        }
        if (request.url.path == '/api/song/detail/') {
          return _jsonResponse({
            'code': 200,
            'songs': [
              {
                'id': 1901371647,
                'name': '孤勇者',
                'duration': 256000,
                'status': 0,
                'fee': 1,
                'artists': [
                  {'id': 2116, 'name': '陈奕迅'},
                ],
                'album': {
                  'id': 137142551,
                  'name': '孤勇者',
                  'picUrl': 'https://p1.music.126.net/cover.jpg',
                },
              },
            ],
          });
        }
        return http.Response('not found', 404);
      }),
    );

    final results = await provider.search('孤勇者');

    expect(provider.descriptor.status, ProviderStatus.experimental);
    expect(provider.descriptor.supports(ProviderCapability.search), isTrue);
    expect(provider.descriptor.supports(ProviderCapability.readFavorites),
        isFalse);
    expect(results.single.ref.providerId, neteaseProviderId);
    expect(results.single.ref.trackId, '1901371647');
    expect(results.single.title, '孤勇者');
    expect(results.single.artists, ['陈奕迅']);
    expect(results.single.album, '孤勇者');
    expect(results.single.artwork.toString(),
        'https://p1.music.126.net/cover.jpg');
    expect(results.single.isPlayable, isTrue);
    expect(results.single.isDownloadable, isTrue);
  });

  test(
      'authenticated provider reads profile, liked song details, setFavorite, daily recommendations, and lyrics',
      () async {
    final trackRef = ProviderTrackRef(
      providerId: neteaseProviderId,
      trackId: '1901371647',
    );
    final provider = NeteaseMusicProvider(
      credentials: const NeteaseCredentials(cookie: 'MUSIC_U=secret'),
      client: MockClient((request) async {
        if (request.url.path != '/api/song/lyric') {
          expect(request.headers['Cookie'], 'MUSIC_U=secret');
        }
        if (request.url.path == '/api/nuser/account/get') {
          return _jsonResponse({
            'code': 200,
            'profile': {
              'userId': 42,
              'nickname': 'Melo Tester',
              'avatarUrl': 'https://p1.music.126.net/avatar.jpg',
            },
          });
        }
        if (request.url.path == '/api/user/playlist') {
          expect(request.url.queryParameters['uid'], '42');
          return _jsonResponse({
            'code': 200,
            'playlist': [
              {
                'id': 37125452,
                'name': 'Melo Tester喜欢的音乐',
                'trackCount': 1,
                'coverImgUrl': 'https://p1.music.126.net/playlist.jpg',
                'creator': {'nickname': 'Melo Tester'},
              }
            ],
          });
        }
        if (request.url.path == '/api/v6/playlist/detail') {
          expect(request.url.queryParameters['id'], '37125452');
          return _jsonResponse({
            'code': 200,
            'playlist': {
              'trackIds': [
                {'id': 1901371647, 'at': 1776987399824}
              ],
            },
          });
        }
        if (request.url.path == '/api/song/detail/') {
          return _jsonResponse({
            'code': 200,
            'songs': [
              {
                'id': 1901371647,
                'name': '孤勇者',
                'duration': 256000,
                'status': 0,
                'artists': [
                  {'name': '陈奕迅'},
                ],
                'album': {'id': 137142551, 'name': '孤勇者'},
              },
            ],
          });
        }
        if (request.url.path == '/api/song/like') {
          expect(request.url.queryParameters['trackId'], '1901371647');
          expect(request.url.queryParameters['like'], 'true');
          return _jsonResponse({'code': 200});
        }
        if (request.url.path == '/api/v1/discovery/recommend/songs') {
          return _jsonResponse({
            'code': 200,
            'data': {
              'dailySongs': [
                {
                  'id': 1901371647,
                  'name': '孤勇者',
                  'duration': 256000,
                  'status': 0,
                  'artists': [
                    {'name': '陈奕迅'},
                  ],
                  'album': {'id': 137142551, 'name': '孤勇者'},
                }
              ]
            }
          });
        }
        if (request.url.path == '/api/v1/discovery/recommend/resource') {
          return _jsonResponse({
            'code': 200,
            'recommend': [
              {
                'id': 88776655,
                'name': '今日私人歌单',
                'picUrl': 'https://p1.music.126.net/recommend.jpg',
                'copywriter': '根据你的口味推荐',
                'trackCount': 30,
                'playcount': 1234567,
                'creator': {'nickname': '网易云音乐'},
              }
            ],
          });
        }
        if (request.url.path == '/api/song/enhance/player/url/v1') {
          expect(request.url.queryParameters['level'], 'higher');
          return _jsonResponse({
            'code': 200,
            'data': [
              {
                'id': 1901371647,
                'url': 'http://cdn.example.test/std.mp3',
                'type': 'mp3',
                'size': 123456,
              }
            ],
          });
        }
        if (request.url.path == '/api/song/lyric') {
          expect(request.url.queryParameters['id'], '1901371647');
          return _jsonResponse({
            'code': 200,
            'lrc': {
              'version': 1,
              'lyric': '[00:00.00] 孤勇者歌词',
            }
          });
        }
        return http.Response('not found', 404);
      }),
    );

    final profile = await provider.getProfile();
    final favorites = await provider.pullFavorites();
    final playlists = await provider.getUserPlaylists();
    final playlistTracks = await provider.getPlaylistTracks('37125452');
    await provider.setFavorite(track: trackRef, liked: true);
    final recommendations = await provider.getDailyRecommendations();
    final recommendedPlaylists = await provider.getRecommendedPlaylists();
    final lyrics = await provider.getLyrics(trackRef);
    final playbackTicket = await provider.createPlaybackTicket(
      track: trackRef,
      quality: AudioQuality.standard,
    );
    final downloadTicket = await provider.createDownloadTicket(
      track: trackRef,
      quality: AudioQuality.standard,
    );

    expect(provider.isAuthenticated, isTrue);
    expect(
        provider.descriptor.supports(ProviderCapability.authenticate), isTrue);
    expect(
        provider.descriptor.supports(ProviderCapability.readFavorites), isTrue);
    expect(provider.descriptor.supports(ProviderCapability.writeFavorites),
        isTrue);
    expect(provider.descriptor.supports(ProviderCapability.readUserPlaylists),
        isTrue);
    expect(
        provider.descriptor
            .supports(ProviderCapability.readDailyRecommendations),
        isTrue);
    expect(provider.descriptor.supports(ProviderCapability.resolvePlayback),
        isTrue);
    expect(provider.descriptor.supports(ProviderCapability.resolveDownload),
        isTrue);
    expect(provider.descriptor.supports(ProviderCapability.lyrics), isTrue);

    expect(profile?.accountId, '42');
    expect(profile?.displayName, 'Melo Tester');
    expect(favorites.tracks.single.isFavorited, isTrue);
    expect(playlists.single.name, 'Melo Tester喜欢的音乐');
    expect(playlists.single.trackCount, 1);
    expect(playlistTracks.single.title, '孤勇者');
    expect(recommendations.single.title, '孤勇者');
    expect(recommendedPlaylists.single.name, '今日私人歌单');
    expect(recommendedPlaylists.single.cover.toString(),
        'https://p1.music.126.net/recommend.jpg');
    expect(recommendedPlaylists.single.description, '根据你的口味推荐');
    expect(recommendedPlaylists.single.playCount, 1234567);
    expect(lyrics, '[00:00.00] 孤勇者歌词');
    expect(
        playbackTicket.mediaUri.toString(), 'https://cdn.example.test/std.mp3');
    expect(
        downloadTicket.mediaUri.toString(), 'https://cdn.example.test/std.mp3');
    expect(downloadTicket.bytes, 123456);
  });

  test(
      'unverified mutation and media capabilities stay unavailable without credentials',
      () async {
    final provider = NeteaseMusicProvider();

    expect(
      () => provider.setFavorite(
        track: ProviderTrackRef(
          providerId: neteaseProviderId,
          trackId: '1901371647',
        ),
        liked: true,
      ),
      throwsA(isA<CapabilityUnavailableException>()),
    );
    expect(
      () => provider.getDailyRecommendations(),
      throwsA(isA<CapabilityUnavailableException>()),
    );
  });
}

http.Response _jsonResponse(Map<String, Object?> payload) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(payload)),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
