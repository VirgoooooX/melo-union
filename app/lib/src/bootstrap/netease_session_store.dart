import 'package:provider_netease/provider_netease.dart';

abstract interface class NeteaseSessionStore {
  Future<NeteaseCredentials?> read();

  Future<void> write(NeteaseCredentials credentials);

  Future<void> clear();
}

final class NullNeteaseSessionStore implements NeteaseSessionStore {
  const NullNeteaseSessionStore();

  @override
  Future<NeteaseCredentials?> read() async => null;

  @override
  Future<void> write(NeteaseCredentials credentials) async {}

  @override
  Future<void> clear() async {}
}
