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
import 'package:provider_kugou/src/mapper/kugou_track_mapper.dart';
import 'package:provider_kugou/src/model/kugou_media_resolution.dart';
import 'package:provider_kugou/src/model/kugou_remote_track.dart';
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

  test('Kugou library API maps private playlist tracks', () async {
    // The track carries both a 128k FileHash and a lossless SQFileHash.
    // The mapper must prefer the standard FileHash so /v5/url can authorize
    // it at 128k for a free account; picking SQFileHash yields 20006.
    const playableHash = 'abcdef1234567890abcdef1234567890';
    const sqHash = 'fedcba9876543210fedcba9876543210';
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
            '{"status":1,"data":{"info":[{"Hash":"11111111111111111111111111111111","FileHash":"$playableHash","SQFileHash":"$sqHash","filename":"歌手 - 歌曲.mp3","timelen":241000,"albuminfo":{"id":123,"name":"专辑"},"album_audio_id":456,"fileid":"file-1","collecttime":1783300000,"singerinfo":[{"name":"歌手"}],"trans_param":{"union_cover":"http://imge.kugou.com/stdmusic/{size}/song.jpg"}}]}}',
          );
        }),
      ),
      providerId: kugouProviderId,
    );

    final tracks = await api.getPlaylistTracks('9');
    // Standard FileHash wins over SQFileHash / Hash for playback authorization.
    expect(tracks.single.hash, playableHash);
    expect(tracks.single.title, '歌曲');
    expect(tracks.single.artists, ['歌手']);
    expect(tracks.single.album, '专辑');
    expect(tracks.single.albumId, '123');
    expect(tracks.single.albumAudioId, '456');
    expect(tracks.single.artwork.toString(), contains('/400/song.jpg'));
    expect(tracks.single.favoriteFileId, 'file-1');
    expect(
      tracks.single.favoriteTime,
      DateTime.fromMillisecondsSinceEpoch(
        1783300000 * 1000,
        isUtc: true,
      ),
    );
    expect(tracks.single.duration, const Duration(milliseconds: 241000));
  });

  test('Kugou track mapper exposes raw and imported liked-at metadata', () {
    final mapper = KugouTrackMapper(providerId: kugouProviderId);
    final rawLikedAt = DateTime.utc(2026, 7, 6, 12);

    final rawTrack = mapper.map(
      KugouRemoteTrack(
        hash: 'raw',
        title: 'Raw',
        artists: const ['Artist'],
        duration: const Duration(minutes: 3),
        favoriteFileId: '1',
        favoriteTime: rawLikedAt,
      ),
      isFavorited: true,
    );
    expect(rawTrack.likedAt, rawLikedAt);
    expect(rawTrack.likedAtSource, 'kugou_raw');
    expect(rawTrack.likedAtPrecision, 'exact');
    expect(rawTrack.ref.extraIds['searchTitle'], 'Raw');
    expect(rawTrack.ref.extraIds['searchArtists'], 'Artist');

    final importedTrack = mapper.map(
      const KugouRemoteTrack(
        hash: 'imported',
        title: 'Imported',
        artists: ['Artist'],
        duration: Duration(minutes: 3),
        favoriteFileId: '2',
      ),
      isFavorited: true,
    );
    expect(importedTrack.likedAt, isNull);
    expect(importedTrack.likedAtSource, 'kugou_import');
    expect(importedTrack.likedAtPrecision, 'unknown');

    final searchTrack = mapper.map(
      const KugouRemoteTrack(
        hash: 'search',
        title: 'Search',
        artists: ['Artist'],
        duration: Duration(minutes: 3),
      ),
    );
    expect(searchTrack.likedAtSource, isNull);
    expect(searchTrack.likedAtPrecision, isNull);
  });

  test(
      'Kugou mapper falls back to SQFileHash only when no standard hash exists',
      () async {
    // Track has only a lossless SQFileHash (no FileHash/Hash). Mapper must
    // fall back to SQ so the track is at least visible; the resolver will then
    // surface QualityUnavailable if the account can't play lossless.
    const sqHash = 'fedcba9876543210fedcba9876543210';
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
          if (request.url.path == '/v4/get_list_all_file') {
            return _jsonResponse(
              '{"status":1,"data":{"info":[{"SQFileHash":"$sqHash","filename":"歌手 - 歌曲.mp3","timelen":241000,"albuminfo":{"id":123,"name":"专辑"},"album_audio_id":456,"fileid":"file-1","addtime":1783300000,"singerinfo":[{"name":"歌手"}],"trans_param":{"union_cover":"http://imge.kugou.com/stdmusic/{size}/song.jpg"}}]}}',
            );
          }
          return http.Response('{}', 404);
        }),
      ),
      providerId: kugouProviderId,
    );

    final tracks = await api.getPlaylistTracks('9');
    expect(tracks.single.hash, sqHash);
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
        final cookie = request.headers['Cookie'] ?? '';
        expect(cookie, contains('KugooID=12345'));
        expect(cookie, contains('KuGoo=KugooID=12345&KugooPwd=token'));
        expect(cookie, contains('mid=mid'));
        expect(cookie, contains('kg_dfid_collect=dfid'));
        expect(cookie, contains('KUGOU_API_MID=mid'));
        expect(cookie, contains('dfid=dfid'));
        expect(cookie, contains('userid=12345'));
        expect(cookie, contains('token=token'));
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

  test('Kugou device registration uses QR login device identity', () async {
    const installGuid = '11111111-2222-4333-8444-555555555555';
    final expectedMid = KugouSessionManager.calculateKugouMid(installGuid);
    final session = KugouSession(
      userId: '12345',
      token: 'mock_token',
      deviceId: '-',
      mid: expectedMid,
      deviceFingerprint: '-',
      installGuid: installGuid,
      installMac: 'MOCKMAC12345',
      installDev: 'MOCKDEV123456789',
      updatedAt: DateTime.now(),
    );
    final store = _MockSecureSessionStore()..session = session;
    final api = KugouApiClient(
      sessionManager: KugouSessionManager(
        secureStore: store,
        initialSession: session,
      ),
      client: _FakeClient((request) {
        expect(request.url.host, 'userservice.kugou.com');
        expect(request.url.path, '/risk/v2/r_register_dev');
        expect(request.url.queryParameters['dfid'], '-');
        expect(request.url.queryParameters['mid'], expectedMid);
        expect(request.headers['mid'], expectedMid);
        expect(
            request.headers['Cookie'], contains('KUGOU_API_GUID=$installGuid'));
        expect(
            request.headers['Cookie'], contains('KUGOU_API_MID=$expectedMid'));
        expect(request.headers['Cookie'], contains('token=mock_token'));
        expect(request.headers['Cookie'], contains('userid=12345'));
        return _jsonResponse('{"status":1,"data":{"dfid":"server_dfid"}}');
      }),
    );

    await api.registerWebDevice();

    expect(store.session?.deviceFingerprint, 'server_dfid');
    expect(store.session?.mid, expectedMid);
  });

  test('Kugou catalog maps public chart playlists and tracks', () async {
    const playableHash = 'abcdef1234567890abcdef1234567890';
    const sqHash = 'fedcba9876543210fedcba9876543210';
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
              '{"songs":{"list":[{"hash":"11111111111111111111111111111111","FileHash":"$playableHash","SQFileHash":"$sqHash","filename":"Singer - Song","duration":251,"album_id":42,"album_audio_id":99}]}}',
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
    expect(tracks.single.hash, playableHash);
    expect(tracks.single.sqHash, sqHash);
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

  test('Kugou provider enriches low private refs from search before playback',
      () async {
    const lowHash = '11111111111111111111111111111111';
    const hqHash = '22222222222222222222222222222222';
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
    final requestedHashes = <String>[];
    final provider = KugouMusicProvider.create(
      secureStore: _MockSecureSessionStore()..session = session,
      initialSession: session,
      httpClient: _FakeClient((request) {
        if (request.url.host == 'songsearch.kugou.com') {
          expect(request.url.queryParameters['keyword'], 'Full Song Singer');
          return _jsonResponse(
            '{"data":{"lists":[{"SongName":"Full Song","SingerName":"Singer","Duration":270,"FileHash":"$lowHash","HQFileHash":"$hqHash","AlbumID":"123","AlbumAudioID":"456"}]}}',
          );
        }
        if (request.url.host == 'gateway.kugou.com' &&
            request.url.path == '/v5/url') {
          final hash = request.url.queryParameters['hash'] ?? '';
          requestedHashes.add(hash);
          expect(hash, hqHash);
          return _jsonResponse(
            '{"status":1,"data":{"320":{"url":"https://sharefs.kugou.com/full.mp3","bitrate":320,"fileSize":12000000,"fileType":"mp3"}}}',
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final track = ProviderTrackRef(
      providerId: kugouProviderId,
      trackId: lowHash,
      extraIds: const {
        'favoriteFileId': 'favorite-1',
        'fileHash': lowHash,
        'rawHash': lowHash,
        'expectedDurationMs': '270000',
        'searchTitle': 'Full Song',
        'searchArtists': 'Singer',
      },
    );

    final ticket = await provider.createPlaybackTicket(
      track: track,
      quality: AudioQuality.high,
    );

    expect(ticket.mediaUri.toString(), 'https://sharefs.kugou.com/full.mp3');
    expect(ticket.trackRef, track);
    expect(requestedHashes, [hqHash]);
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

  test('Kugou v5/url uses temporary dfid when session dfid is missing',
      () async {
    const hash = 'abcdef1234567890abcdef1234567890';
    final session = KugouSession(
      userId: '12345',
      token: 'mock_token',
      deviceId: '-',
      mid: 'mock_mid',
      deviceFingerprint: '-',
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
                '{"data":{},"status":0,"err_code":20010}', 200);
          }
          if (request.url.host == 'm.kugou.com') {
            return http.Response('{"errcode":0,"url":""}', 200);
          }
          expect(request.url.path, '/v5/url');
          final dfid = request.url.queryParameters['dfid'];
          expect(dfid, isNotNull);
          expect(dfid, isNot('-'));
          expect(dfid, matches(RegExp(r'^[A-F0-9]{24}$')));
          expect(request.headers['Cookie'], contains('dfid=$dfid'));
          expect(request.headers['Cookie'], contains('KUGOU_API_MID=mock_mid'));
          return _jsonResponse(
            '{"status":1,"data":{"128":{"url":"https://sharefs.kugou.com/128.mp3","bitrate":128}}}',
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
      requestedQuality: AudioQuality.standard,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/128.mp3');
  });

  test('Kugou v5/url uses music-lib flac probe for candidate hashes', () async {
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
    String? sentQuality;
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
                '{"data":{},"status":0,"err_code":20010}', 200);
          }
          if (request.url.host == 'm.kugou.com') {
            return http.Response('{"errcode":0,"url":""}', 200);
          }
          expect(request.url.path, '/v5/url');
          expect(request.url.query, contains('module='));
          sentQuality = request.url.queryParameters['quality'];
          return _jsonResponse(
            '{"status":1,"data":{"128":{"url":"https://sharefs.kugou.com/128.mp3","bitrate":128}}}',
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
      requestedQuality: AudioQuality.standard,
      use: KugouMediaUse.playback,
    );

    expect(sentQuality, 'flac');
    expect(resolution.url.toString(), 'https://sharefs.kugou.com/128.mp3');
  });

  test(
      'Kugou favorite playback uses authenticated full variant before play/getdata',
      () async {
    const publicHash = '11111111111111111111111111111111';
    const fileHash = 'abcdef1234567890abcdef1234567890';
    const sqHash = 'fedcba9876543210fedcba9876543210';
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
    var playGetDataCalled = false;
    String? firstV5Hash;
    String? firstV5Quality;
    final media = KugouMediaApi(
      providerId: kugouProviderId,
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore()..session = session,
          initialSession: session,
        ),
        client: _FakeClient((request) {
          if (request.url.host == 'wwwapi.kugou.com' &&
              request.url.path == '/yy/index.php') {
            playGetDataCalled = true;
            return _jsonResponse(
              '{"data":{"play_url":"https://sharefs.kugou.com/partial.mp3","bitrate":128,"filesize":123},"err_code":0}',
            );
          }
          expect(request.url.host, 'gateway.kugou.com');
          expect(request.url.path, '/v5/url');
          firstV5Hash ??= request.url.queryParameters['hash'];
          firstV5Quality ??= request.url.queryParameters['quality'];
          return _jsonResponse(
            '{"status":1,"data":{"128":{"url":"https://sharefs.kugou.com/full.mp3","bitrate":128,"fileSize":456}}}',
          );
        }),
      ),
    );

    final resolution = await media.resolve(
      track: ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: publicHash,
        extraIds: const {
          'albumId': '123',
          'albumAudioId': '456',
          'favoriteFileId': 'file-1',
          'fileHash': fileHash,
          'sqHash': sqHash,
        },
      ),
      requestedQuality: AudioQuality.lossless,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/full.mp3');
    expect(firstV5Hash, sqHash);
    expect(firstV5Quality, 'flac');
    expect(playGetDataCalled, isFalse);
  });

  test('Kugou v5/url ignores nested preview URLs when full quality URL exists',
      () async {
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
          expect(request.url.path, '/v5/url');
          return _jsonResponse(
            '{"status":1,"data":{"free_part":{"url":"https://sharefs.kugou.com/preview.mp3"},"flac":{"url":"https://sharefs.kugou.com/full.flac","bitrate":1000,"fileSize":32000000}}}',
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
      requestedQuality: AudioQuality.lossless,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/full.flac');
    expect(resolution.quality, AudioQuality.lossless);
    expect(resolution.format, 'flac');
  });

  test('Kugou v5/url prefers quality bucket over data preview URL', () async {
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
          expect(request.url.path, '/v5/url');
          return _jsonResponse(
            '{"status":1,"data":{"url":"https://sharefs.kugou.com/preview.mp3","flac":{"url":"https://sharefs.kugou.com/full.flac","bitrate":1000,"fileSize":32000000}}}',
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
      requestedQuality: AudioQuality.lossless,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/full.flac');
  });

  test('Kugou fallback skips URLs too small for expected duration', () async {
    const sqHash = 'fedcba9876543210fedcba9876543210';
    const hqHash = 'abcdef1234567890abcdef1234567890';
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
    final triedHashes = <String>[];
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
          if (request.url.path == '/v5/url') {
            final hash = request.url.queryParameters['hash'] ?? '';
            triedHashes.add(hash);
            if (hash == sqHash) {
              return _jsonResponse(
                '{"status":1,"data":{"128":{"url":"https://sharefs.kugou.com/preview.mp3","bitrate":128,"fileSize":900000}}}',
              );
            }
            return _jsonResponse(
              '{"status":1,"data":{"320":{"url":"https://sharefs.kugou.com/full.mp3","bitrate":320,"fileSize":12000000}}}',
            );
          }
          return _jsonResponse('{"status":0,"error_code":0,"data":{}}');
        }),
      ),
    );

    final resolution = await media.resolve(
      track: ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: sqHash,
        extraIds: const {
          'sqHash': sqHash,
          'hqHash': hqHash,
          'expectedDurationMs': '270000',
        },
      ),
      requestedQuality: AudioQuality.standard,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/full.mp3');
    expect(triedHashes, containsAllInOrder([sqHash, hqHash]));
  });

  test('Kugou v5/url 20006 falls back to signed v6 priv_url', () async {
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
      vipToken: 'mock_vip_token',
      vipType: '6',
      updatedAt: DateTime.now(),
    );
    int v5Calls = 0;
    int v6Calls = 0;
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
                '{"data":{},"status":0,"err_code":20010}', 200);
          }
          if (request.url.host == 'm.kugou.com') {
            return http.Response('{"errcode":0,"url":""}', 200);
          }
          if (request.url.path == '/v5/url') {
            v5Calls++;
            return _jsonResponse(
                '{"status":0,"error_code":20006,"data":{"url":""}}');
          }
          if (request.url.host == 'tracker.kugou.com' &&
              request.url.path == '/v6/priv_url') {
            v6Calls++;
            expect(request.url.queryParameters['signature'], isNotEmpty);
            expect(request.url.queryParameters['token'], 'mock_token');
            expect(request.headers['Cookie'],
                contains('vip_token=mock_vip_token'));
            final body = (request as http.Request).body;
            expect(body, contains('"viptoken":"mock_vip_token"'));
            expect(body, isNot(contains('"quality"')));
            expect(body, contains('"qualities"'));
            final bodyJson = jsonDecode(body) as Map<String, dynamic>;
            expect(
              bodyJson['qualities'],
              [
                '128',
                '320',
                'flac',
                'high',
                'multitrack',
                'viper_atmos',
                'viper_tape',
                'viper_clear',
                'super',
              ],
            );
            return _jsonResponse(
              '{"status":1,"data":{"url":"https://sharefs.kugou.com/v6.flac","bitrate":1000,"fileSize":99,"fileType":"flac"}}',
            );
          }
          return http.Response('{}', 404);
        }),
      ),
    );

    final resolution = await media.resolve(
      track: ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: hash,
        extraIds: const {'albumId': '123', 'albumAudioId': '456'},
      ),
      requestedQuality: AudioQuality.lossless,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/v6.flac');
    expect(resolution.quality, AudioQuality.lossless);
    expect(v5Calls, 1);
    expect(v6Calls, 1);
  });

  test('Kugou v6 priv_url resolves album_audio_id from songinfo v2', () async {
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
      vipToken: 'mock_vip_token',
      vipType: '6',
      refreshMetadata: const {
        'cookie':
            't=web_t; KugooID=54321; mid=web_mid; uuid=web_uuid; dfid=web_dfid',
      },
      updatedAt: DateTime.now(),
    );
    int songinfoCalls = 0;
    int v6Calls = 0;
    final media = KugouMediaApi(
      providerId: kugouProviderId,
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore()..session = session,
          initialSession: session,
        ),
        client: _FakeClient((request) {
          if (request.url.host == 'wwwapi.kugou.com' &&
              request.url.path == '/yy/index.php') {
            return http.Response(
                '{"data":{},"status":0,"err_code":20010}', 200);
          }
          if (request.url.host == 'm.kugou.com') {
            return http.Response('{"errcode":0,"url":""}', 200);
          }
          if (request.url.path == '/v5/url') {
            return _jsonResponse(
                '{"status":0,"error_code":20006,"data":{"url":""}}');
          }
          if (request.url.host == 'wwwapi.kugou.com' &&
              request.url.path == '/play/songinfo') {
            songinfoCalls++;
            expect(request.url.queryParameters['hash'], hash);
            expect(request.url.queryParameters['token'], 'web_t');
            expect(request.url.queryParameters['userid'], '54321');
            expect(request.url.queryParameters['signature'], isNotEmpty);
            expect(request.headers['Cookie'], contains('KugooID=54321'));
            return _jsonResponse(
              '{"status":1,"data":{"encode_album_audio_id":"encoded-987","album_audio_id":987}}',
            );
          }
          if (request.url.host == 'tracker.kugou.com' &&
              request.url.path == '/v6/priv_url') {
            v6Calls++;
            final body = jsonDecode((request as http.Request).body)
                as Map<String, dynamic>;
            final resource = body['resource'] as Map<String, dynamic>;
            expect(resource['album_audio_id'], '987');
            return _jsonResponse(
              '{"status":1,"data":{"url":"https://sharefs.kugou.com/v6.mp3","bitrate":320,"fileSize":99,"fileType":"mp3"}}',
            );
          }
          return http.Response('{}', 404);
        }),
      ),
    );

    final resolution = await media.resolve(
      track: ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: hash,
        extraIds: const {'albumId': '123'},
      ),
      requestedQuality: AudioQuality.high,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(), 'https://sharefs.kugou.com/v6.mp3');
    expect(songinfoCalls, 1);
    expect(v6Calls, 1);
  });

  test('Kugou fallback uses songinfo v2 before tracker', () async {
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
      refreshMetadata: const {
        'cookie':
            't=web_t; KugooID=54321; mid=web_mid; uuid=web_uuid; dfid=web_dfid',
      },
      updatedAt: DateTime.now(),
    );
    int songinfoCalls = 0;
    var trackerCalled = false;
    final media = KugouMediaApi(
      providerId: kugouProviderId,
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore()..session = session,
          initialSession: session,
        ),
        client: _FakeClient((request) {
          if (request.url.host == 'wwwapi.kugou.com' &&
              request.url.path == '/yy/index.php') {
            return http.Response(
                '{"data":{},"status":0,"err_code":20010}', 200);
          }
          if (request.url.host == 'm.kugou.com') {
            return http.Response('{"errcode":0,"url":""}', 200);
          }
          if (request.url.path == '/v5/url') {
            return _jsonResponse(
                '{"status":0,"error_code":20006,"data":{"url":""}}');
          }
          if (request.url.host == 'tracker.kugou.com' &&
              request.url.path == '/v6/priv_url') {
            return _jsonResponse('{"status":0,"error_code":0,"data":{}}');
          }
          if (request.url.host == 'wwwapi.kugou.com' &&
              request.url.path == '/play/songinfo') {
            songinfoCalls++;
            if (request.url.queryParameters.containsKey('hash')) {
              return _jsonResponse(
                '{"status":1,"data":{"encode_album_audio_id":"encoded-123","album_audio_id":123}}',
              );
            }
            expect(
              request.url.queryParameters['encode_album_audio_id'],
              'encoded-123',
            );
            return _jsonResponse(
              '{"status":1,"data":{"play_backup_url":"https://sharefs.kugou.com/songinfo.mp3","bitrate":128,"filesize":42,"extname":"mp3"}}',
            );
          }
          if (request.url.host.contains('trackercdn')) {
            trackerCalled = true;
          }
          return http.Response('{}', 404);
        }),
      ),
    );

    final resolution = await media.resolve(
      track: ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: hash,
        extraIds: const {'albumId': '123', 'albumAudioId': '456'},
      ),
      requestedQuality: AudioQuality.standard,
      use: KugouMediaUse.playback,
    );

    expect(
      resolution.url.toString(),
      'https://sharefs.kugou.com/songinfo.mp3',
    );
    expect(songinfoCalls, 2);
    expect(trackerCalled, isFalse);
  });

  test('Kugou tracker fallback sends QR app cookie', () async {
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
    var trackerCalls = 0;
    final media = KugouMediaApi(
      providerId: kugouProviderId,
      client: KugouApiClient(
        sessionManager: KugouSessionManager(
          secureStore: _MockSecureSessionStore()..session = session,
          initialSession: session,
        ),
        client: _FakeClient((request) {
          if (request.url.host == 'wwwapi.kugou.com' &&
              request.url.path == '/yy/index.php') {
            return http.Response(
                '{"data":{},"status":0,"err_code":20010}', 200);
          }
          if (request.url.host == 'm.kugou.com') {
            return http.Response('{"errcode":0,"url":""}', 200);
          }
          if (request.url.path == '/v5/url') {
            return _jsonResponse(
                '{"status":0,"error_code":20006,"data":{"url":""}}');
          }
          if (request.url.host == 'tracker.kugou.com' &&
              request.url.path == '/v6/priv_url') {
            return _jsonResponse('{"status":0,"error_code":0,"data":{}}');
          }
          if (request.url.host.contains('trackercdn.kugou.com') ||
              request.url.host.contains('trackercdnbj.kugou.com')) {
            trackerCalls++;
            final cookie = request.headers['Cookie'] ?? '';
            expect(cookie, contains('KUGOU_API_MID=mock_mid'));
            expect(cookie, contains('dfid=mock_dfid'));
            expect(cookie, contains('userid=12345'));
            expect(cookie, contains('token=mock_token'));
            return _jsonResponse(
              '{"status":1,"errcode":0,"url":"https://fs.youthandroid2.kugou.com/tracker.mp3","bitRate":128,"fileSize":42,"extName":"mp3"}',
            );
          }
          return http.Response('{}', 404);
        }),
      ),
    );

    final resolution = await media.resolve(
      track: ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: hash,
        extraIds: const {'albumId': '123', 'albumAudioId': '456'},
      ),
      requestedQuality: AudioQuality.standard,
      use: KugouMediaUse.playback,
    );

    expect(resolution.url.toString(),
        'https://fs.youthandroid2.kugou.com/tracker.mp3');
    expect(trackerCalls, 1);
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
