import 'package:provider_contract/provider_contract.dart';

import '../auth/kugou_session_manager.dart';
import '../support/kugou_crypto.dart';
import 'kugou_api_client.dart';

final class KugouAccountApi {
  KugouAccountApi({
    required KugouSessionManager sessionManager,
    required KugouApiClient client,
    required ProviderId providerId,
  })  : _sessionManager = sessionManager,
        _client = client,
        _providerId = providerId;

  final KugouSessionManager _sessionManager;
  final KugouApiClient _client;
  final ProviderId _providerId;

  Future<({String displayName, Uri? avatarUrl, String vipType})>
      getProfileDetails() async {
    final session = await _sessionManager.getSession();
    if (session == null) {
      return (displayName: '酷狗用户', avatarUrl: null, vipType: 'none');
    }

    final clientTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/
        Duration.millisecondsPerSecond;
    final p = kugouRsaNoPaddingHex({
      'token': session.token,
      'clienttime': clientTime,
    });
    final response = await _client.androidGatewayPost(
      '/v3/get_my_info',
      authenticated: true,
      headers: const {'x-router': 'usercenter.kugou.com'},
      params: {
        'plat': 1,
        'clienttime': clientTime,
      },
      data: {
        'visit_time': clientTime,
        'usertype': 1,
        'p': p,
        'userid': int.tryParse(session.userId) ?? session.userId,
      },
    );

    final status = _intValue(response['status']);
    final errorCode = _intValue(response['error_code'] ?? response['err_code']);
    if (status == 0 || (errorCode != null && errorCode != 0)) {
      throw ProviderException(
        providerId: _providerId,
        message:
            'Kugou profile request failed (code: ${errorCode ?? 'unknown'}).',
      );
    }
    final data = _firstMap(response['data']) ?? response;
    final displayName = _stringValue(
      data['nickname'] ??
          data['username'] ??
          data['nick_name'] ??
          data['name'] ??
          data['user_name'],
    );
    final avatar = _stringValue(
      data['pic'] ??
          data['img'] ??
          data['avatar'] ??
          data['headimg'] ??
          data['head_img'],
    );
    return (
      displayName: displayName.isEmpty
          ? '酷狗用户_${_lastFour(session.userId)}'
          : displayName,
      avatarUrl: avatar.isEmpty ? null : Uri.tryParse(avatar),
      vipType:
          session.vipType ?? _stringValue(data['vip_type'] ?? data['viptype']),
    );
  }

  String _lastFour(String text) {
    if (text.length <= 4) return text;
    return text.substring(text.length - 4);
  }

  Map<String, Object?>? _firstMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    if (value is List<Object?>) {
      for (final item in value) {
        final mapped = _firstMap(item);
        if (mapped != null) return mapped;
      }
    }
    return null;
  }

  String _stringValue(Object? value) => value?.toString().trim() ?? '';

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
