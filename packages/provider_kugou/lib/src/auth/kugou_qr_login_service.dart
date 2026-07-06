import 'kugou_session.dart';

enum KugouQrLoginStatus {
  waiting,
  scanned,
  authorized,
  expired,
  failed,
}

final class KugouQrLoginSession {
  const KugouQrLoginSession({
    required this.key,
    required this.expiresAt,
    this.loginUri,
    this.imageDataUri,
  });

  final String key;
  final DateTime expiresAt;
  final Uri? loginUri;
  final String? imageDataUri;
}

final class KugouQrLoginResult {
  const KugouQrLoginResult({
    required this.status,
    this.session,
    this.message,
  });

  final KugouQrLoginStatus status;
  final KugouSession? session;
  final String? message;
}

abstract interface class KugouQrLoginService {
  Future<KugouQrLoginSession> createQrLoginSession();
  Future<KugouQrLoginResult> checkQrLoginSession(KugouQrLoginSession session);
}
