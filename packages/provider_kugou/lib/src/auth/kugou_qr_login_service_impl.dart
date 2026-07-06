import '../api/kugou_api_client.dart';
import 'kugou_qr_login_service.dart';
import 'kugou_session.dart';

final class KugouQrLoginServiceImpl implements KugouQrLoginService {
  KugouQrLoginServiceImpl({
    required KugouApiClient apiClient,
  }) : _apiClient = apiClient;

  final KugouApiClient _apiClient;

  @override
  Future<KugouQrLoginSession> createQrLoginSession() async {
    // ignore: avoid_print
    print('[KugouQrLogin] createQrLoginSession');

    // Anonymous QR context — no token, no userid, no device preregistration.
    // MakcRe and music-lib references confirm the QR endpoint accepts
    // unauthenticated requests with just device identity fields.
    final response = await _apiClient.webGet(
      Uri.parse('https://login-user.kugou.com/v2/qrcode'),
      extraParams: {
        'appid': 1001,
        'type': 1,
        'plat': 4,
        'qrcode_txt':
            'https://h5.kugou.com/apps/loginQRCode/html/index.html?appid=3116&',
        'srcappid': 2919,
      },
    );

    // ignore: avoid_print
    print(
        '[KugouQrLogin] /v2/qrcode status=${response['status']} error_code=${response['error_code']}');

    if (response['status'] == 1 || response['error_code'] == 0) {
      final data = response['data'] is Map
          ? response['data'] as Map<String, dynamic>
          : response;
      final key = (data['key'] ??
                  data['qrcode'] ??
                  response['key'] ??
                  response['qrcode'])
              ?.toString() ??
          '';
      if (key.isNotEmpty) {
        final qrcodeUrl =
            'https://h5.kugou.com/apps/loginQRCode/html/index.html?qrcode=$key';
        return KugouQrLoginSession(
          key: key,
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          loginUri: Uri.parse(qrcodeUrl),
        );
      }
    }

    throw StateError(
      '酷狗拒绝创建登录二维码（错误码：${response['error_code'] ?? 'unknown'}）',
    );
  }

  @override
  Future<KugouQrLoginResult> checkQrLoginSession(
      KugouQrLoginSession session) async {
    if (DateTime.now().isAfter(session.expiresAt)) {
      return const KugouQrLoginResult(status: KugouQrLoginStatus.expired);
    }

    try {
      // music-lib / KugouMusic.NET reference:
      //   GET https://login-user.kugou.com/v2/get_userinfo_qrcode
      //   encryptType: 'web'
      //   params: plat=4, appid=3116, srcappid=2919, qrcode=<key>
      final response = await _apiClient.webGet(
        Uri.parse('https://login-user.kugou.com/v2/get_userinfo_qrcode'),
        extraParams: {
          'plat': 4,
          'appid': 3116,
          'srcappid': 2919,
          'qrcode': session.key,
        },
      );

      final data = (response['data'] is Map)
          ? response['data'] as Map<String, dynamic>
          : response;
      // In MakcRe response: data.status / response.status
      //   0 = expired, 1 = waiting, 2 = scanned, 4 = authorized
      final status =
          data['status']?.toString() ?? response['status']?.toString() ?? '';

      switch (status) {
        case '1':
          return const KugouQrLoginResult(status: KugouQrLoginStatus.waiting);
        case '2':
          return const KugouQrLoginResult(status: KugouQrLoginStatus.scanned);
        case '0':
          return const KugouQrLoginResult(status: KugouQrLoginStatus.expired);
        case '4':
          final token = data['token']?.toString() ?? '';
          final userid = data['userid']?.toString() ?? '';
          if (token.isNotEmpty && userid.isNotEmpty) {
            // Device identity is assigned later by KugouAuthService
            // via getOrCreateDeviceDetails() before saving the session.
            final sessionData = KugouSession(
              userId: userid,
              token: token,
              deviceId: '', // placeholder – overridden by auth service
              mid: '', // placeholder – overridden by auth service
              deviceFingerprint: '', // placeholder – overridden by auth service
              vipToken: data['vip_token']?.toString(),
              vipType: data['vip_type']?.toString(),
              updatedAt: DateTime.now(),
            );
            return KugouQrLoginResult(
              status: KugouQrLoginStatus.authorized,
              session: sessionData,
            );
          }
          return const KugouQrLoginResult(
            status: KugouQrLoginStatus.failed,
            message: 'Failed to retrieve tokens from Kugou server.',
          );
        default:
          return const KugouQrLoginResult(status: KugouQrLoginStatus.waiting);
      }
    } catch (error) {
      return KugouQrLoginResult(
        status: KugouQrLoginStatus.failed,
        message: 'Failed to check Kugou QR login session: $error',
      );
    }
  }
}
