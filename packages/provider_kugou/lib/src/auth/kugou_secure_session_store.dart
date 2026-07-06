import 'kugou_session.dart';

abstract interface class KugouSecureSessionStore {
  Future<KugouSession?> read();
  Future<void> write(KugouSession session);
  Future<void> clear();
}
