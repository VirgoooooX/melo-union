import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:provider_contract/provider_contract.dart';
import 'package:provider_qq/provider_qq.dart';
import 'package:test/test.dart';

void main() {
  test('search maps QQ Music song JSON', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, '/soso/fcgi-bin/client_search_cp');
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'data': {
              'song': {
                'list': [
                  {
                    'songmid': 'song_mid_1',
                    'media_mid': 'media_mid_1',
                    'songname': '<em>晴天</em>',
                    'albumname': '叶惠美',
                    'albummid': 'album_mid_1',
                    'interval': 269,
                    'singer': [
                      {'name': '周杰伦'},
                    ],
                  },
                ],
              },
            },
          })),
          200,
        );
      }),
      searchBaseUri: Uri.parse('https://qq.test'),
    );

    expect(provider.descriptor.id, qqMusicProviderId);
    expect(provider.descriptor.supports(ProviderCapability.search), isTrue);
    expect(
        provider.descriptor.supports(ProviderCapability.readFavorites), isTrue);
    expect(provider.descriptor.supports(ProviderCapability.readCharts), isTrue);

    final results = await provider.search('晴天');
    expect(results, hasLength(1));
    expect(results.single.title, '晴天');
    expect(results.single.artists, ['周杰伦']);
    expect(results.single.album, '叶惠美');
    expect(results.single.ref.extraIds['media_mid'], 'media_mid_1');
    expect(results.single.artwork.toString(), contains('album_mid_1'));
  });

  test('creates playback and download tickets from vkey response', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, '/cgi-bin/musicu.fcg');
        final decoded = jsonDecode(
          utf8.decode((request as http.Request).bodyBytes),
        ) as Map<String, Object?>;
        final req = decoded['req_0'] as Map<String, Object?>;
        final param = req['param'] as Map<String, Object?>;
        expect(param['songmid'], ['song_mid_1']);
        expect(param['filename'], ['C400media_mid_1.m4a']);
        expect(param['uin'], '0');
        expect(request.headers['content-type'], contains('application/json'));
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'req_0': {
              'code': 0,
              'data': {
                'sip': ['http://stream.qq.test/'],
                'midurlinfo': [
                  {
                    'songmid': 'song_mid_1',
                    'filename': 'C400media_mid_1.m4a',
                    'purl': 'C400media_mid_1.m4a?vkey=abc',
                    'result': 0,
                  },
                ],
              },
            },
          })),
          200,
        );
      }),
      musicuUri: Uri.parse('https://qq.test/cgi-bin/musicu.fcg'),
      now: () => DateTime.utc(2026, 6, 30),
    );
    final ref = ProviderTrackRef(
      providerId: qqMusicProviderId,
      trackId: 'song_mid_1',
      extraIds: const {'media_mid': 'media_mid_1'},
    );

    final playback = await provider.createPlaybackTicket(
      track: ref,
      quality: AudioQuality.standard,
    );
    expect(playback.mediaUri.toString(),
        'https://stream.qq.test/C400media_mid_1.m4a?vkey=abc');
    expect(playback.headers['Referer'], 'https://y.qq.com/');

    final download = await provider.createDownloadTicket(
      track: ref,
      quality: AudioQuality.standard,
    );
    expect(download.fileExtension, 'm4a');
  });

  test('playback falls back to alternate QQ filename formats', () async {
    final filenames = <String>[];
    final provider = QqMusicProvider(
      credentials: const QqMusicCredentials(
        cookie: 'uin=o12345; qqmusic_key=abc',
      ),
      client: _FakeClient((request) {
        final decoded = jsonDecode(
          utf8.decode((request as http.Request).bodyBytes),
        ) as Map<String, Object?>;
        final req = decoded['req_0'] as Map<String, Object?>;
        final param = req['param'] as Map<String, Object?>;
        final filename = (param['filename'] as List<Object?>).single as String;
        filenames.add(filename);

        expect(param['songmid'], ['song_mid_1']);
        expect(param['uin'], '12345');
        expect((decoded['comm'] as Map<String, Object?>)['uin'], 12345);

        final purl =
            filename.startsWith('M500') ? 'M500media_mid_1.mp3?vkey=abc' : '';
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'req_0': {
              'code': 0,
              'data': {
                'sip': ['http://stream.qq.test/'],
                'midurlinfo': [
                  {
                    'songmid': 'song_mid_1',
                    'filename': filename,
                    'purl': purl,
                    'result': purl.isEmpty ? -105 : 0,
                  },
                ],
              },
            },
          })),
          200,
        );
      }),
      musicuUri: Uri.parse('https://qq.test/cgi-bin/musicu.fcg'),
      now: () => DateTime.utc(2026, 6, 30),
    );

    final playback = await provider.createPlaybackTicket(
      track: ProviderTrackRef(
        providerId: qqMusicProviderId,
        trackId: 'song_mid_1',
        extraIds: const {
          'song_mid': 'song_mid_1',
          'media_mid': 'media_mid_1',
        },
      ),
      quality: AudioQuality.standard,
    );

    expect(filenames.take(2), ['C400media_mid_1.m4a', 'M500media_mid_1.mp3']);
    expect(playback.mediaUri.toString(),
        'https://stream.qq.test/M500media_mid_1.mp3?vkey=abc');
  });

  test('lyrics maps plain lyric response', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, '/lyric/fcgi-bin/fcg_query_lyric_new.fcg');
        return http.Response(
            jsonEncode({'code': 0, 'lyric': '[00:01.00]Hi'}), 200);
      }),
      lyricBaseUri: Uri.parse('https://qq.test'),
    );

    final lyrics = await provider.getLyrics(
      ProviderTrackRef(providerId: qqMusicProviderId, trackId: 'song_mid_1'),
    );
    expect(lyrics, '[00:01.00]Hi');
  });

  test('creates and checks QQ QR login session', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        if (request.url.path == '/ptqrshow') {
          return http.Response.bytes(
            [1, 2, 3],
            200,
            headers: {'set-cookie': 'qrsig=qrsig-token; Path=/; HttpOnly'},
          );
        }
        if (request.url.path == '/ptqrlogin') {
          expect(request.headers['cookie'], contains('qrsig=qrsig-token'));
          return http.Response.bytes(
            utf8.encode(
              "ptuiCB('0','0','https://graph.qq.test/jump','0','登录成功')",
            ),
            200,
            headers: {'set-cookie': 'p_skey=music-key; uin=o12345'},
          );
        }
        if (request.url.path == '/jump') {
          return http.Response.bytes(
            const [],
            200,
            headers: {'set-cookie': 'euin=o12345'},
          );
        }
        fail('unexpected request: ${request.url}');
      }),
      qqQrShowUri: Uri.parse('https://ssl.ptlogin2.qq.com/ptqrshow'),
      qqQrCheckUri: Uri.parse('https://ssl.ptlogin2.qq.com/ptqrlogin'),
    );

    final session = await provider.createQrLoginSession(QqMusicQrLoginMode.qq);
    expect(session.imageDataUri, startsWith('data:image/png;base64,'));
    expect(session.key, contains('qrsig='));

    final result = await provider.checkQrLoginSession(session);
    expect(result.status, QqMusicQrLoginStatus.authorized);
    expect(result.credentials?.cookie, contains('qqmusic_key=music-key'));
    expect(result.credentials?.cookie, contains('qm_keyst=music-key'));
  });

  test('creates and checks WeChat QR login session', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        if (request.url.host == 'open.weixin.test') {
          return http.Response.bytes(
            utf8.encode('window.QRLogin.uuid = "wx-uuid"'),
            200,
          );
        }
        if (request.url.host == 'lp.weixin.test') {
          return http.Response.bytes(
            utf8.encode("wx_errcode='405';wx_code='wx-code';"),
            200,
          );
        }
        if (request.url.path == '/cgi-bin/musicu.fcg') {
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'code': 0,
              'req': {
                'code': 0,
                'data': {
                  'musicid': '67890',
                  'musickey': 'wx-music-key',
                  'openid': 'open-id',
                },
              },
            })),
            200,
          );
        }
        fail('unexpected request: ${request.url}');
      }),
      wxQrConnectUri: Uri.parse('https://open.weixin.test/connect/qrconnect'),
      wxQrCheckUri: Uri.parse('https://lp.weixin.test/connect/l/qrconnect'),
      musicuUri: Uri.parse('https://qq.test/cgi-bin/musicu.fcg'),
    );

    final session =
        await provider.createQrLoginSession(QqMusicQrLoginMode.wechat);
    expect(session.imageUri.toString(), contains('wx-uuid'));

    final result = await provider.checkQrLoginSession(session);
    expect(result.status, QqMusicQrLoginStatus.authorized);
    expect(result.credentials?.cookie, contains('qqmusic_key=wx-music-key'));
    expect(result.credentials?.cookie, contains('openid=open-id'));
  });

  test('temporarily hides QR login options', () {
    final provider = QqMusicProvider();
    final entries = provider.qrLoginOptions();

    expect(entries, isEmpty);
    expect(
        provider.descriptor.supports(ProviderCapability.authenticate), isTrue);
  });

  test('pullFavorites maps profile order songs', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, contains('fcg_get_profile_order_asset.fcg'));
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'data': {
              'totalsong': 2,
              'songlist': [
                {
                  'data': {
                    'songmid': 'mid_002',
                    'songname': '七里香',
                    'albumname': '七里香',
                    'albummid': 'alb_002',
                    'interval': 300,
                    'singer': [
                      {'name': '周杰伦'},
                    ],
                  },
                },
                {
                  'data': {
                    'songmid': 'mid_001',
                    'songname': '晴天',
                    'albumname': '叶惠美',
                    'albummid': 'alb_001',
                    'interval': 269,
                    'singer': [
                      {'name': '周杰伦'},
                    ],
                  },
                },
              ],
            },
          })),
          200,
        );
      }),
      credentials: QqMusicCredentials(cookie: 'uin=o12345; qqmusic_key=abc'),
    );

    final snapshot = await provider.pullFavorites();
    expect(snapshot.tracks, hasLength(2));
    expect(snapshot.tracks[0].title, '七里香');
    expect(snapshot.tracks[0].isFavorited, isTrue);
    expect(snapshot.tracks[0].ref.extraIds['song_mic'], isNull);
    expect(snapshot.tracks[0].ref.extraIds['song_mid'], 'mid_002');
    expect(snapshot.tracks[0].artwork.toString(), contains('alb_002'));
    expect(snapshot.tracks[0].artists, ['周杰伦']);
    expect(snapshot.tracks[0].likedAtSource, 'qq_import');
    expect(snapshot.tracks[0].likedAtPrecision, 'unknown');
    // likedAt is null; it gets assigned by the service layer registry sync
    expect(snapshot.tracks[0].likedAt, isNull);
  });

  test('getProfile returns uin from cookie', () async {
    final provider = QqMusicProvider(
      credentials: QqMusicCredentials(cookie: 'uin=o12345; qqmusic_key=abc'),
    );
    final profile = await provider.getProfile();
    expect(profile?.accountId, '12345');
    expect(profile?.displayName, '12345');
  });

  test('getProfile throws when signed out', () async {
    final provider = QqMusicProvider();
    expect(
      () => provider.getProfile(),
      throwsA(isA<AuthenticationRequiredException>()),
    );
  });

  test('getUserPlaylists maps created and collected playlists', () async {
    var callCount = 0;
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        callCount++;
        if (request.url.path.contains('fcg_get_profile_order_asset.fcg')) {
          if (callCount == 1) {
            // reqtype=1 (favorites check)
            return http.Response.bytes(
              utf8.encode(jsonEncode({
                'code': 0,
                'data': {'totalsong': 5},
              })),
              200,
            );
          }
          // reqtype=3 (profile ordered playlists)
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'code': 0,
              'data': {
                'cdlist': [
                  {
                    'dissid': '3003',
                    'dissname': '收藏歌单B',
                    'songnum': 12,
                    'listennum': 800,
                  },
                ],
              },
            })),
            200,
          );
        }
        // fcg_user_created_diss
        expect(request.url.path, contains('fcg_user_created_diss'));
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'data': {
              'disslist': [
                {
                  'dissid': '1001',
                  'diss_name': '我的最爱',
                  'song_cnt': 30,
                  'listen_num': 1500,
                  'diss_cover': 'http://example.com/cover.jpg',
                },
              ],
              'list': [
                {
                  'dissid': '2002',
                  'dissname': '收藏歌单A',
                  'song_count': 20,
                  'listennum': 3000,
                  'imgurl': 'http://example.com/img.jpg',
                },
              ],
            },
          })),
          200,
        );
      }),
      credentials: QqMusicCredentials(cookie: 'uin=o12345; qqmusic_key=abc'),
    );

    final playlists = await provider.getUserPlaylists();
    // Virtual favorites + created + collected + profile ordered
    expect(playlists.length, greaterThanOrEqualTo(3));
    final ids = playlists.map((p) => p.playlistId).toSet();
    expect(ids, contains('profile:favorites'));
    expect(ids, contains('1001'));
    expect(ids, contains('2002'));
    expect(ids, contains('3003'));
  });

  test('getPlaylistTracks from regular playlist strips JSONP', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, contains('fcg_ucc_getcdinfo_byids_cp.fcg'));
        return http.Response.bytes(
          utf8.encode(
            'MusicJsonCallback(${jsonEncode({
                  'code': 0,
                  'cdlist': [
                    {
                      'dissname': 'Test Playlist',
                      'songlist': [
                        {
                          'songmid': 's1',
                          'media_mid': 'm1',
                          'songname': 'Song One',
                          'albummid': 'a1',
                          'interval': 200,
                          'singer': [
                            {'name': 'Artist A'},
                          ],
                        },
                        {
                          'songmid': 's2',
                          'songname': 'Song Two',
                          'albummid': 'a2',
                          'interval': 180,
                          'singer': [
                            {'name': 'Artist B'},
                          ],
                        },
                      ],
                    },
                  ],
                })})',
          ),
          200,
        );
      }),
    );

    final tracks = await provider.getPlaylistTracks('12345');
    expect(tracks, hasLength(2));
    expect(tracks[0].title, 'Song One');
    expect(tracks[0].artists, ['Artist A']);
    expect(tracks[0].ref.extraIds['media_mid'], 'm1');
    expect(tracks[1].title, 'Song Two');
  });

  test('getPlaylistTracks resolves profile:favorites virtual playlist',
      () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, contains('fcg_get_profile_order_asset.fcg'));
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'data': {
              'totalsong': 1,
              'songlist': [
                {
                  'data': {
                    'songmid': 'fav_001',
                    'media_mid': 'fav_media_001',
                    'songname': 'Favorite Song',
                    'albummid': 'fav_alb',
                    'interval': 250,
                    'singer': [
                      {'name': 'Favorite Artist'},
                    ],
                  },
                },
              ],
            },
          })),
          200,
        );
      }),
      credentials: QqMusicCredentials(cookie: 'uin=o12345; qqmusic_key=abc'),
    );

    final tracks = await provider.getPlaylistTracks('profile:favorites');
    expect(tracks, hasLength(1));
    expect(tracks[0].title, 'Favorite Song');
    expect(tracks[0].isFavorited, isTrue);
    expect(tracks[0].ref.extraIds['media_mid'], 'fav_media_001');
  });

  test('getRecommendedPlaylists maps musicu.fcg hot recommend', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, contains('musicu.fcg'));
        final decoded = jsonDecode(
          utf8.decode((request as http.Request).bodyBytes),
        );
        expect(
            decoded['recomPlaylist']['module'], 'playlist.HotRecommendServer');
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'recomPlaylist': {
              'code': 0,
              'data': {
                'v_hot': [
                  {
                    'content_id': 5001,
                    'title': '热门推荐',
                    'cover': 'http://example.com/cover.jpg',
                    'listen_num': 99999,
                    'song_cnt': 50,
                  },
                ],
              },
            },
          })),
          200,
        );
      }),
    );

    final playlists = await provider.getRecommendedPlaylists(limit: 5);
    expect(playlists, hasLength(1));
    expect(playlists[0].name, '热门推荐');
    expect(playlists[0].playlistId, '5001');
    expect(playlists[0].trackCount, 50);
    expect(playlists[0].playCount, 99999);
  });

  test('getChartPlaylists and chart tracks map QQ top list APIs', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, contains('musicu.fcg'));
        final decoded = jsonDecode(
          utf8.decode((request as http.Request).bodyBytes),
        ) as Map<String, Object?>;
        final toplist = decoded['toplist'] as Map<String, Object?>?;
        if (toplist != null) {
          expect(toplist['module'], 'musicToplist.ToplistInfoServer');
          expect(toplist['method'], 'GetAll');
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'code': 0,
              'toplist': {
                'code': 0,
                'data': {
                  'group': [
                    {
                      'groupName': '巅峰榜',
                      'toplist': [
                        {
                          'topId': 26,
                          'title': '热歌榜',
                          'period': '2026-06-30',
                          'intro': '站内播放热度前300首歌曲',
                          'listenNum': 19600000,
                          'totalNum': 300,
                          'frontPicUrl': 'http://example.com/top.jpg',
                        },
                      ],
                    },
                  ],
                },
              },
            })),
            200,
          );
        }

        final detail = decoded['detail'] as Map<String, Object?>?;
        expect(detail?['module'], 'musicToplist.ToplistInfoServer');
        expect(detail?['method'], 'GetDetail');
        final param = detail?['param'] as Map<String, Object?>?;
        expect(param?['topId'], 26);
        expect(param?['period'], '2026-06-30');
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'detail': {
              'code': 0,
              'data': {'title': '热歌榜'},
              'songInfoList': [
                {
                  'mid': 'top_song_001',
                  'name': '榜单歌曲',
                  'album': {'mid': 'top_album', 'name': '榜单专辑'},
                  'file': {'media_mid': 'top_media_001'},
                  'interval': 218,
                  'singer': [
                    {'name': '榜单歌手'},
                  ],
                },
              ],
            },
          })),
          200,
        );
      }),
      musicuUri: Uri.parse('https://qq.test/cgi-bin/musicu.fcg'),
    );

    final charts = await provider.getChartPlaylists(limit: 5);
    expect(charts, hasLength(1));
    expect(charts.single.name, '热歌榜');
    expect(charts.single.playlistId, 'chart:26:2026-06-30');
    expect(charts.single.creatorName, '巅峰榜');
    expect(charts.single.cover.toString(), 'https://example.com/top.jpg');
    expect(charts.single.trackCount, 300);
    expect(charts.single.playCount, 19600000);

    final tracks = await provider.getPlaylistTracks(charts.single.playlistId);
    expect(tracks, hasLength(1));
    expect(tracks.single.title, '榜单歌曲');
    expect(tracks.single.artists, ['榜单歌手']);
    expect(tracks.single.ref.trackId, 'top_song_001');
    expect(tracks.single.ref.extraIds['media_mid'], 'top_media_001');
  });

  test('getDailyRecommendations returns SmartRadio songs', () async {
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, contains('musicu.fcg'));
        // SmartRadio uses short field names: mid, name, album.mid
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'recommend': {
              'code': 0,
              'data': {
                'songList': [
                  {
                    'mid': 'rec_001',
                    'file': {'media_mid': 'rec_media_001'},
                    'name': '推荐曲目',
                    'album': {'mid': 'rec_alb', 'name': '推荐专辑'},
                    'interval': 210,
                    'singer': [
                      {'name': '推荐歌手'},
                    ],
                  },
                ],
              },
            },
          })),
          200,
        );
      }),
    );

    final tracks = await provider.getDailyRecommendations();
    expect(tracks, isNotEmpty);
    expect(tracks[0].title, '推荐曲目');
    expect(tracks[0].ref.trackId, 'rec_001');
    expect(tracks[0].ref.extraIds['media_mid'], 'rec_media_001');
    expect(tracks[0].artists, ['推荐歌手']);
  });

  test('getDailyRecommendations falls back to search on SmartRadio failure',
      () async {
    // Send an error code from SmartRadio to trigger fallback
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        if (request.url.path.contains('musicu.fcg')) {
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'code': 0,
              'recommend': {
                'code': -1,
                'data': null,
              },
            })),
            200,
          );
        }
        // Fallback search
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'data': {
              'song': {
                'list': [
                  {
                    'songmid': 'hot_001',
                    'songname': '热门歌曲',
                    'albummid': 'hot_alb',
                    'interval': 200,
                    'singer': [
                      {'name': '热门歌手'}
                    ],
                  },
                ],
              },
            },
          })),
          200,
        );
      }),
    );

    final tracks = await provider.getDailyRecommendations();
    expect(tracks, isNotEmpty);
    expect(tracks[0].title, '热门歌曲');
  });

  test('authenticated setFavorite calls SetSongFav via musicu.fcg', () async {
    final trackRef = ProviderTrackRef(
      providerId: qqMusicProviderId,
      trackId: 'mid_002',
      extraIds: const {'song_mid': 'mid_002'},
    );
    final provider = QqMusicProvider(
      client: _FakeClient((request) {
        expect(request.url.path, contains('musicu.fcg'));
        final body =
            request is http.Request ? utf8.decode(request.bodyBytes) : '';
        final decoded = jsonDecode(body) as Map<String, Object?>;
        final comm = decoded['comm'] as Map<String, Object?>?;
        expect(comm?['ct'], 24);
        expect(comm?['platform'], 'yqq.json');
        expect(comm?['loginUin'], 12345);
        final fav = decoded['fav'];
        expect(fav, isNotNull);
        final params =
            (fav as Map<String, Object?>)['param'] as Map<String, Object?>?;
        expect(params?['songmid'], 'mid_002');
        expect(params?['fav'], 1);
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'code': 0,
            'fav': {'code': 0},
          })),
          200,
        );
      }),
      credentials: QqMusicCredentials(cookie: 'uin=o12345; qqmusic_key=abc'),
    );

    await expectLater(
      provider.setFavorite(track: trackRef, liked: true),
      completes,
    );
  });

  test('unauthenticated setFavorite throws AuthenticationRequiredException',
      () async {
    final provider = QqMusicProvider();
    final trackRef = ProviderTrackRef(
      providerId: qqMusicProviderId,
      trackId: 'mid_002',
    );

    await expectLater(
      () => provider.setFavorite(track: trackRef, liked: true),
      throwsA(isA<AuthenticationRequiredException>()),
    );
  });

  test('setFavorite without song mid throws ProviderException', () async {
    final provider = QqMusicProvider(
      credentials: QqMusicCredentials(cookie: 'uin=o12345; qqmusic_key=abc'),
    );
    final trackRef = ProviderTrackRef(
      providerId: qqMusicProviderId,
      trackId: '',
    );

    await expectLater(
      () => provider.setFavorite(track: trackRef, liked: true),
      throwsA(isA<ProviderException>()),
    );
  });
}

final class _FakeClient extends http.BaseClient {
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
