import 'package:provider_qq/provider_qq.dart';

import 'qq_music_session_store.dart';

enum QqMusicBackgroundRefreshStatus {
  noSession,
  notDue,
  succeeded,
  failed,
}

final class QqMusicBackgroundRefreshOutcome {
  const QqMusicBackgroundRefreshOutcome({
    required this.status,
    required this.message,
    this.credentials,
  });

  final QqMusicBackgroundRefreshStatus status;
  final String message;
  final QqMusicCredentials? credentials;

  bool get taskSucceeded => status != QqMusicBackgroundRefreshStatus.failed;
}

typedef QqMusicCredentialRefresher = Future<QqMusicCredentialRefreshResult>
    Function(
  QqMusicCredentials credentials,
);

Future<QqMusicBackgroundRefreshOutcome> refreshQqMusicCredentialsInBackground({
  required QqMusicSessionStore sessionStore,
  DateTime Function()? now,
  QqMusicCredentialRefresher? refresh,
}) async {
  final currentTime = (now ?? DateTime.now)();
  try {
    final credentials = await sessionStore.read();
    if (credentials == null || !credentials.hasCookie) {
      return const QqMusicBackgroundRefreshOutcome(
        status: QqMusicBackgroundRefreshStatus.noSession,
        message: '本地没有 QQ 音乐会话',
      );
    }

    final createdAt = qqMusicKeyCreatedAt(credentials.cookie);
    if (createdAt != null &&
        currentTime.isBefore(createdAt.add(const Duration(hours: 20)))) {
      return const QqMusicBackgroundRefreshOutcome(
        status: QqMusicBackgroundRefreshStatus.notDue,
        message: 'QQ 音乐密钥尚未到续期时间',
      );
    }

    final result = await (refresh ?? _refreshQqMusicCredentials)(credentials);
    final updated = result.credentials;
    if (updated == null) {
      return QqMusicBackgroundRefreshOutcome(
        status: QqMusicBackgroundRefreshStatus.failed,
        message: result.message,
      );
    }
    await sessionStore.write(updated);
    return QqMusicBackgroundRefreshOutcome(
      status: QqMusicBackgroundRefreshStatus.succeeded,
      message: result.message,
      credentials: updated,
    );
  } catch (error) {
    return QqMusicBackgroundRefreshOutcome(
      status: QqMusicBackgroundRefreshStatus.failed,
      message: '后台续期异常（${error.runtimeType}）',
    );
  }
}

DateTime? qqMusicKeyCreatedAt(String cookie) {
  final match = RegExp(
    r'(^|;\s*)psrf_musickey_createtime=([^;]+)',
    caseSensitive: false,
  ).firstMatch(cookie);
  final value = int.tryParse(match?.group(2)?.trim() ?? '');
  if (value == null || value <= 0) return null;
  return value > 1000000000000
      ? DateTime.fromMillisecondsSinceEpoch(value)
      : DateTime.fromMillisecondsSinceEpoch(value * 1000);
}

Future<QqMusicCredentialRefreshResult> _refreshQqMusicCredentials(
  QqMusicCredentials credentials,
) {
  return QqMusicProvider(credentials: credentials).refreshCredentialsDetailed();
}
