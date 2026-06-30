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
    expect(provider.descriptor.supports(ProviderCapability.readFavorites),
        isFalse);

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

    final download = await provider.createDownloadTicket(
      track: ref,
      quality: AudioQuality.standard,
    );
    expect(download.fileExtension, 'm4a');
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

  test('exposes QQ and WeChat QR login options without auth capability', () {
    final provider = QqMusicProvider();
    final entries = provider.qrLoginOptions();

    expect(entries.map((entry) => entry.mode), [
      QqMusicQrLoginMode.qq,
      QqMusicQrLoginMode.wechat,
    ]);
    expect(
        provider.descriptor.supports(ProviderCapability.authenticate), isFalse);
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
