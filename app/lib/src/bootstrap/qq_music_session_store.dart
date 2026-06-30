import 'package:provider_qq/provider_qq.dart';

abstract interface class QqMusicSessionStore {
  Future<QqMusicCredentials?> read();

  Future<void> write(QqMusicCredentials credentials);

  Future<void> clear();
}

final class NullQqMusicSessionStore implements QqMusicSessionStore {
  const NullQqMusicSessionStore();

  @override
  Future<QqMusicCredentials?> read() async => null;

  @override
  Future<void> write(QqMusicCredentials credentials) async {}

  @override
  Future<void> clear() async {}
}
