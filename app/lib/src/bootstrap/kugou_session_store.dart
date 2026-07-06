import 'package:provider_kugou/provider_kugou.dart';

abstract interface class KugouSessionStore implements KugouSecureSessionStore {}

final class NullKugouSessionStore implements KugouSessionStore {
  const NullKugouSessionStore();

  @override
  Future<KugouSession?> read() async => null;

  @override
  Future<void> write(KugouSession session) async {}

  @override
  Future<void> clear() async {}
}
