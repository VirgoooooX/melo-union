import 'package:melo_union_app/src/bootstrap/qq_music_background_refresh.dart';
import 'package:melo_union_app/src/bootstrap/qq_music_session_store.dart';
import 'package:provider_qq/provider_qq.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('background refresh exits without a session', () async {
    var refreshCalls = 0;
    final outcome = await refreshQqMusicCredentialsInBackground(
      sessionStore: _MemoryQqSessionStore(),
      refresh: (credentials) async {
        refreshCalls++;
        throw StateError('must not refresh');
      },
    );

    expect(outcome.status, QqMusicBackgroundRefreshStatus.noSession);
    expect(outcome.taskSucceeded, isTrue);
    expect(refreshCalls, 0);
  });

  test('background refresh skips a key younger than twenty hours', () async {
    final now = DateTime.utc(2026, 8, 5, 12);
    final createdAt = now.subtract(const Duration(hours: 19));
    var refreshCalls = 0;
    final outcome = await refreshQqMusicCredentialsInBackground(
      sessionStore: _MemoryQqSessionStore(
        QqMusicCredentials(
          cookie:
              'uin=123; qqmusic_key=key; psrf_musickey_createtime=${createdAt.millisecondsSinceEpoch ~/ 1000}',
        ),
      ),
      now: () => now,
      refresh: (credentials) async {
        refreshCalls++;
        throw StateError('must not refresh');
      },
    );

    expect(outcome.status, QqMusicBackgroundRefreshStatus.notDue);
    expect(refreshCalls, 0);
  });

  test('background refresh persists credentials returned for a due key',
      () async {
    final now = DateTime.utc(2026, 8, 5, 12);
    final createdAt = now.subtract(const Duration(hours: 21));
    final store = _MemoryQqSessionStore(
      QqMusicCredentials(
        cookie:
            'uin=123; qqmusic_key=old; psrf_musickey_createtime=${createdAt.millisecondsSinceEpoch ~/ 1000}',
      ),
    );
    final updated = QqMusicCredentials(
      cookie:
          'uin=123; qqmusic_key=new; psrf_musickey_createtime=${now.millisecondsSinceEpoch ~/ 1000}',
    );

    final outcome = await refreshQqMusicCredentialsInBackground(
      sessionStore: store,
      now: () => now,
      refresh: (credentials) async {
        return QqMusicCredentialRefreshResult.success(
          credentials: updated,
          protocol: QqMusicCredentialRefreshProtocol.loginServer,
        );
      },
    );

    expect(outcome.status, QqMusicBackgroundRefreshStatus.succeeded);
    expect(store.credentials?.cookie, updated.cookie);
    expect(store.writeCount, 1);
  });

  test('background refresh preserves old credentials on failure', () async {
    final original = const QqMusicCredentials(
      cookie:
          'uin=123; qqmusic_key=old; psrf_musickey_createtime=1; psrf_qqrefresh_token=secret',
    );
    final store = _MemoryQqSessionStore(original);

    final outcome = await refreshQqMusicCredentialsInBackground(
      sessionStore: store,
      now: () => DateTime.utc(2026, 8, 5),
      refresh: (credentials) async {
        return QqMusicCredentialRefreshResult.failure(
          message: 'LoginServer 返回码 0/10001',
        );
      },
    );

    expect(outcome.status, QqMusicBackgroundRefreshStatus.failed);
    expect(outcome.message, 'LoginServer 返回码 0/10001');
    expect(store.credentials?.cookie, original.cookie);
    expect(store.writeCount, 0);
    expect(outcome.message, isNot(contains('secret')));
  });
}

final class _MemoryQqSessionStore implements QqMusicSessionStore {
  _MemoryQqSessionStore([this.credentials]);

  QqMusicCredentials? credentials;
  int writeCount = 0;

  @override
  Future<void> clear() async => credentials = null;

  @override
  Future<QqMusicCredentials?> read() async => credentials;

  @override
  Future<void> write(QqMusicCredentials credentials) async {
    writeCount++;
    this.credentials = credentials;
  }
}
