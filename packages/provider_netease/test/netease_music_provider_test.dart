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
        expect(request.url.path, '/api/search/get/web');
        expect(request.url.queryParameters['s'], '孤勇者');
        expect(request.headers['Cookie'], isNull);
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
                  'picUrl': 'https://p1.music.126.net/cover.jpg',
                },
              },
            ],
          },
        });
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
    expect(results.single.isPlayable, isTrue);
    expect(results.single.isDownloadable, isFalse);
  });

  test('authenticated provider reads profile and liked song details', () async {
    final provider = NeteaseMusicProvider(
      credentials: const NeteaseCredentials(cookie: 'MUSIC_U=secret'),
      client: MockClient((request) async {
        expect(request.headers['Cookie'], 'MUSIC_U=secret');
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
        if (request.url.path == '/api/song/like/get') {
          expect(request.url.queryParameters['uid'], '42');
          return _jsonResponse({
            'code': 200,
            'ids': [1901371647],
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
        return http.Response('not found', 404);
      }),
    );

    final profile = await provider.getProfile();
    final favorites = await provider.pullFavorites();

    expect(provider.isAuthenticated, isTrue);
    expect(
        provider.descriptor.supports(ProviderCapability.authenticate), isTrue);
    expect(
        provider.descriptor.supports(ProviderCapability.readFavorites), isTrue);
    expect(profile?.accountId, '42');
    expect(profile?.displayName, 'Melo Tester');
    expect(favorites.tracks.single.isFavorited, isTrue);
  });

  test('unverified mutation and media capabilities stay unavailable', () async {
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
      () => provider.createDownloadTicket(
        track: ProviderTrackRef(
          providerId: neteaseProviderId,
          trackId: '1901371647',
        ),
        quality: AudioQuality.standard,
      ),
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
