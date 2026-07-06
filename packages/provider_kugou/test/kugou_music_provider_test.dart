import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:provider_contract/provider_contract.dart';
import 'package:provider_kugou/provider_kugou.dart';
import 'package:provider_kugou/src/api/kugou_api_client.dart';
import 'package:provider_kugou/src/api/kugou_catalog_api.dart';
import 'package:provider_kugou/src/api/kugou_library_api.dart';
import 'package:provider_kugou/src/api/kugou_media_api.dart';
import 'package:provider_kugou/src/auth/kugou_qr_login_service_impl.dart';
import 'package:provider_kugou/src/auth/kugou_session_manager.dart';
import 'package:provider_kugou/src/model/kugou_media_resolution.dart';
import 'package:test/test.dart';

void main() {
  test('Kugou descriptor exposes integration capabilities for live testing',
      () {
    final provider = KugouMusicProvider.create(
      secureStore: _MockSecureSessionStore(),
    );

    expect(provider.descriptor.id.value, 'kugou');
    expect(provider.descriptor.capabilities, {
      ProviderCapability.authenticate,
      ProviderCapability.readFavorites,
      ProviderCapability.writeFavorites,
      ProviderCapability.readUserPlaylists,
      ProviderCapability.readDailyRecommendations,
      ProviderCapability.readCharts,
      ProviderCapability.search,
      ProviderCapability.resolvePlayback,
      ProviderCapability.resolveDownload,
      ProviderCapability.lyrics,
      ProviderCapability.artwork,
    });
  });

  test('Kugou QR login creation failures do not create mock sessions',
      () async {
    final apiClient = KugouApiClient(
      sessionManager: KugouSessionManager(
        secureStore: _MockSecureSessionStore(),
      ),
      client:
          _FakeClient((request) => http.Response('server unavailable', 503)),
    );
    final service = KugouQrLoginServiceImpl(apiClient: apiClient);

    await expectLater(
      service.createQrLoginSession(),
      throwsA(isA<ProviderException>()),
    );
  });

  test('Kugou library API requests signed private playlists', () async {
    final session = KugouSession(
      userId: '12345',
      token: 'mock_token',
      deviceId: 'mock_device',
      mid: 'mock_mid',
      deviceFingerprint: 'mock_fp',
      updatedAt: DateTime.now(),
    );
    final store = _MockSecureSessionStore()..session = session;
    final sessionManager = KugouSessionManager(
      secureStore: store,
      initialSession: session,
    );
    final api = KugouLibraryApi(
      client: KugouApiClient(
        sessionManager: sessionManager,
        client: _FakeClient((request) {
          expect(request.url.host, 'gateway.kugou.com');
          expect(request.url.path, '/v7/get_all_list');
          expect(request.url.queryParameters['signature'], isNotEmpty);
          expect(request.headers['x-router'], 'cloudlist.service.kugou.com');
          expect(request.headers['Cookie'], contains('userid=12345'));
          expect(request.headers['Cookie'], contains('token=mock_token'));
          expect((request as http.Request).body, contains('"total_ver":979'));
          expect(request.body, contains('"userid":"12345"'));
          expect(request.body, contains('"token":"mock_token"'));
          return _jsonResponse(
            '{"status":1,"data":{"info":[{"listid":7,"listname":"我喜欢","songcount":2,"is_def":2},{"listid":9,"listname":"自建歌单","songcount":3,"is_fav":0},{"listid":11,"listname":"收藏歌单","songcount":4,"is_fav":1}]}}',
          );
        }),
      ),
      providerId: kugouProviderId,
    );

    final playlists = await api.getUserPlaylists();
    expect(playlists, hasLength(3));
    expect(playlists.first.playlistId, '7');
    expect(playlists.first.isFavoriteCollection, isTrue);
    expect(playlists[1].name, '自建歌单');
    expect(playlists.last.name, '收藏歌单');
    expect(playlists.last.isFavoriteCollection, isFalse);
  });

  test('Kugou library API retries private playlists with C# device ids',
      () async {
    final session = KugouSession(
      userId: '12345',
      token: 'mock_token',
      deviceId: '-',
      mid: 'mock_mid',
      deviceFingerprint: 'mock_dfid',
      installGuid: 'mock-guid',
      installMac: 'mock-mac',
      installDev: 'mock-dev',
      updatedAt: DateTime.now(),
    );
    var calls = 0;
    final api = KugouLibraryApi(
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore()..session = session,
          initialSession: session,
        ),
        client: _FakeClient((request) {
          calls += 1;
          if (calls == 1) {
            expect(request.url.queryParameters['mid'], 'mock_mid');
            expect(request.url.queryParameters['uuid'], '-');
            return _jsonResponse('{"status":0,"error_code":20017}');
          }

          final expectedMid =
              KugouSessionManager.calculateKugouMid('mock_dfid');
          final expectedUuid =
              KugouSessionManager.calculateKugouUuid('mock_dfid', expectedMid);
          expect(request.url.queryParameters['mid'], expectedMid);
          expect(request.url.queryParameters['uuid'], expectedUuid);
          expect(request.headers['Cookie'],
              contains('KUGOU_API_MID=$expectedMid'));
          return _jsonResponse(
            '{"status":1,"data":{"info":[{"listid":7,"listname":"我喜欢","songcount":2,"is_fav":1}]}}',
          );
        }),
      ),
      providerId: kugouProviderId,
    );

    final playlists = await api.getUserPlaylists();
    expect(calls, 2);
    expect(playlists.single.playlistId, '7');
  });

  test('Kugou library API maps private playlist tracks', () async {
    const playableHash = 'abcdef1234567890abcdef1234567890';
    final session = KugouSession(
      userId: '12345',
      token: 'mock_token',
      deviceId: 'mock_device',
      mid: 'mock_mid',
      deviceFingerprint: 'mock_fp',
      updatedAt: DateTime.now(),
    );
    final api = KugouLibraryApi(
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore()..session = session,
          initialSession: session,
        ),
        client: _FakeClient((request) {
          expect(request.url.path, '/v4/get_list_all_file');
          expect((request as http.Request).body, contains('"listid":"9"'));
          expect(request.body, contains('"show_relate_goods":1'));
          return _jsonResponse(
            '{"status":1,"data":{"info":[{"Hash":"11111111111111111111111111111111","SQFileHash":"$playableHash","filename":"歌手 - 歌曲.mp3","timelen":241000,"albuminfo":{"id":123,"name":"专辑"},"album_audio_id":456,"fileid":"file-1","addtime":1783300000,"singerinfo":[{"name":"歌手"}],"trans_param":{"union_cover":"http://imge.kugou.com/stdmusic/{size}/song.jpg"}}]}}',
          );
        }),
      ),
      providerId: kugouProviderId,
    );

    final tracks = await api.getPlaylistTracks('9');
    expect(tracks.single.hash, playableHash);
    expect(tracks.single.title, '歌曲');
    expect(tracks.single.artists, ['歌手']);
    expect(tracks.single.album, '专辑');
    expect(tracks.single.albumId, '123');
    expect(tracks.single.albumAudioId, '456');
    expect(tracks.single.artwork.toString(), contains('/400/song.jpg'));
    expect(tracks.single.favoriteFileId, 'file-1');
    expect(tracks.single.duration, const Duration(milliseconds: 241000));
  });

  test('Kugou API client sends imported raw cookie when available', () async {
    final session = KugouSession(
      userId: '12345',
      token: 'KugooID=12345&KugooPwd=token',
      deviceId: 'mock_device',
      mid: 'mid',
      deviceFingerprint: 'dfid',
      refreshMetadata: const {
        'cookie':
            'KugooID=12345; KuGoo=KugooID=12345&KugooPwd=token; mid=mid; kg_dfid_collect=dfid',
      },
      updatedAt: DateTime.now(),
    );
    final store = _MockSecureSessionStore()..session = session;
    final sessionManager = KugouSessionManager(
      secureStore: store,
      initialSession: session,
    );
    final api = KugouApiClient(
      sessionManager: sessionManager,
      client: _FakeClient((request) {
        expect(
          request.headers['Cookie'],
          'KugooID=12345; KuGoo=KugooID=12345&KugooPwd=token; mid=mid; kg_dfid_collect=dfid',
        );
        return http.Response(
          '{"ok":true}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await api.get(Uri.parse('https://example.test/session'),
        authenticated: true);
  });

  test('Kugou catalog maps public chart playlists and tracks', () async {
    final catalog = KugouCatalogApi(
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore(),
        ),
        client: _FakeClient((request) {
          if (request.url.path == '/rank/list&json=true') {
            return http.Response(
              '{"rank":{"list":[{"rankid":8888,"rankname":"TOP500","play_times":123,"img_9":"http://imge.kugou.com/mcommon/{size}/cover.png"}]}}',
              200,
            );
          }
          if (request.url.path == '/rank/info/') {
            return http.Response(
              '{"songs":{"list":[{"hash":"ABC","filename":"Singer - Song","duration":251,"album_id":42,"album_audio_id":99}]}}',
              200,
            );
          }
          return http.Response('{}', 404);
        }),
      ),
    );

    final charts = await catalog.getChartPlaylists(limit: 1);
    expect(charts.single.playlistId, 'rank:8888');
    expect(charts.single.name, 'TOP500');
    expect(charts.single.cover.toString(), contains('/400/cover.png'));

    final tracks = await catalog.getChartTracks('8888');
    expect(tracks.single.hash, 'ABC');
    expect(tracks.single.title, 'Song');
    expect(tracks.single.artists, ['Singer']);
    expect(tracks.single.duration, const Duration(seconds: 251));
  });

  test('Kugou catalog parses public playlist detail HTML data', () async {
    final catalog = KugouCatalogApi(
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore(),
        ),
        client: _FakeClient((request) {
          return http.Response(
            '<script>var data=[{"hash":"DEF","filename":"Artist - Playlist Song","duration":241000,"album_id":123,"trans_param":{"union_cover":"http://imge.kugou.com/stdmusic/{size}/song.jpg"}}]; specialData={};</script>',
            200,
          );
        }),
      ),
    );

    final tracks = await catalog.getRecommendedPlaylistTracks('8268942');
    expect(tracks.single.hash, 'DEF');
    expect(tracks.single.title, 'Playlist Song');
    expect(tracks.single.artists, ['Artist']);
    expect(tracks.single.duration, const Duration(milliseconds: 241000));
    expect(tracks.single.artwork.toString(), contains('/400/song.jpg'));
  });

  test('Kugou media resolver falls back to legacy playInfo URL', () async {
    final session = KugouSession(
      userId: '12345',
      token: 'mock_token',
      deviceId: 'mock_device',
      mid: 'mock_mid',
      deviceFingerprint: 'mock_fp',
      updatedAt: DateTime.now(),
    );
    final media = KugouMediaApi(
      providerId: kugouProviderId,
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore()..session = session,
          initialSession: session,
        ),
        client: _FakeClient((request) {
          if (request.url.host == 'wwwapi.kugou.com') {
            return http.Response(
              '{"data":{},"status":0,"err_code":20010}',
              200,
            );
          }
          if (request.url.host == 'm.kugou.com' &&
              request.url.path == '/app/i/getSongInfo.php') {
            return http.Response(
              '{"errcode":0,"url":"https://sharefs.kugou.com/song.mp3","bitRate":128,"fileSize":3481452,"extName":"mp3"}',
              200,
            );
          }
          return http.Response('{}', 404);
        }),
      ),
    );

    final resolution = await media.resolve(
      track: ProviderTrackRef(providerId: kugouProviderId, trackId: 'ABC'),
      requestedQuality: AudioQuality.high,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/song.mp3');
    expect(resolution.quality, AudioQuality.low);
    expect(resolution.format, 'mp3');
  });

  test('Kugou media resolver accepts map-shaped legacy backup URLs', () async {
    final media = KugouMediaApi(
      providerId: kugouProviderId,
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore(),
        ),
        client: _FakeClient((request) {
          if (request.url.host == 'wwwapi.kugou.com') {
            return http.Response(
              '{"data":{},"status":0,"err_code":20010}',
              200,
            );
          }
          return http.Response(
            '{"errcode":0,"url":"","backup_url":{"0":"https://sharefs.kugou.com/backup.mp3"},"bitRate":128,"fileSize":1,"extName":"mp3"}',
            200,
          );
        }),
      ),
    );

    final resolution = await media.resolve(
      track: ProviderTrackRef(providerId: kugouProviderId, trackId: 'ABC'),
      requestedQuality: AudioQuality.high,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/backup.mp3');
  });

  test('Kugou media resolver falls back to authenticated v5 URL', () async {
    const hash = 'abcdef1234567890abcdef1234567890';
    final session = KugouSession(
      userId: '12345',
      token: 'mock_token',
      deviceId: '-',
      mid: 'mock_mid',
      deviceFingerprint: 'mock_dfid',
      installGuid: 'mock-guid',
      installMac: 'mock-mac',
      installDev: 'mock-dev',
      updatedAt: DateTime.now(),
    );
    final media = KugouMediaApi(
      providerId: kugouProviderId,
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore()..session = session,
          initialSession: session,
        ),
        client: _FakeClient((request) {
          if (request.url.host == 'wwwapi.kugou.com') {
            return http.Response(
              '{"data":{},"status":0,"err_code":20010}',
              200,
            );
          }
          if (request.url.host == 'm.kugou.com') {
            return http.Response('{"errcode":0,"url":""}', 200);
          }
          expect(request.url.host, 'gateway.kugou.com');
          expect(request.url.path, '/v5/url');
          expect(request.headers['x-router'], 'trackercdn.kugou.com');
          expect(request.url.queryParameters['key'], isNotEmpty);
          expect(request.url.queryParameters['hash'], hash);
          return _jsonResponse(
            '{"status":1,"data":{"high":{"url":"https://sharefs.kugou.com/private.mp3","bitrate":320}}}',
          );
        }),
      ),
    );

    final resolution = await media.resolve(
      track: ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: hash,
        extraIds: const {'albumId': '123', 'albumAudioId': '456'},
      ),
      requestedQuality: AudioQuality.high,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/private.mp3');
  });

  test('Kugou library API adds and removes playlist tracks', () async {
    final session = KugouSession(
      userId: '12345',
      token: 'mock_token',
      deviceId: 'mock_device',
      mid: 'mock_mid',
      deviceFingerprint: 'mock_fp',
      updatedAt: DateTime.now(),
    );
    final api = KugouLibraryApi(
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore()..session = session,
          initialSession: session,
        ),
        client: _FakeClient((request) {
          if (request.url.path == '/cloudlist.service/v6/add_song') {
            expect((request as http.Request).body, contains('"listid":"9"'));
            expect(request.body, contains('"hash":"ABC"'));
            expect(request.body, contains('"album_id":123'));
            return _jsonResponse('{"status":1}');
          } else if (request.url.path == '/v4/delete_songs') {
            expect((request as http.Request).body, contains('"listid":"9"'));
            expect(request.body, contains('"fileid":"file-1"'));
            return _jsonResponse('{"status":1}');
          }
          return http.Response('not found', 404);
        }),
      ),
      providerId: kugouProviderId,
    );

    await api.addTrackToPlaylist('9', 'ABC', albumId: '123');
    await api.removeTrackFromPlaylist('9', 'ABC', favoriteFileId: 'file-1');
  });
}

class _MockSecureSessionStore implements KugouSecureSessionStore {
  KugouSession? session;

  @override
  Future<KugouSession?> read() async => session;

  @override
  Future<void> write(KugouSession s) async => session = s;

  @override
  Future<void> clear() async => session = null;
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);
  final http.Response Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

http.Response _jsonResponse(String body, {int statusCode = 200}) {
  return http.Response.bytes(
    utf8.encode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
