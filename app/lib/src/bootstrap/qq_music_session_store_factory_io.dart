import 'dart:io';

import 'package:flutter/services.dart';
import 'package:provider_qq/provider_qq.dart';

import 'qq_music_session_store.dart';

const _channel = MethodChannel('melo_union/provider_credentials');
const _cookieEnv = 'MELO_QQ_MUSIC_COOKIE';

QqMusicSessionStore createQqMusicSessionStore() {
  return _PlatformQqMusicSessionStore();
}

final class _PlatformQqMusicSessionStore implements QqMusicSessionStore {
  QqMusicCredentials? _memoryCredentials;

  @override
  Future<QqMusicCredentials?> read() async {
    if (_memoryCredentials?.hasCookie ?? false) {
      return _memoryCredentials;
    }

    final platformCredentials = await _readFromPlatformChannel();
    if (platformCredentials?.hasCookie ?? false) {
      _memoryCredentials = platformCredentials;
      return platformCredentials;
    }

    return _readFromEnvironment();
  }

  @override
  Future<void> write(QqMusicCredentials credentials) async {
    if (!credentials.hasCookie) {
      throw ArgumentError.value(
        credentials.cookie,
        'credentials.cookie',
        'QQ Music cookie must not be empty.',
      );
    }
    _memoryCredentials = credentials;
    await _writeToPlatformChannel(credentials);
  }

  @override
  Future<void> clear() async {
    _memoryCredentials = null;
    await _clearPlatformChannel();
  }

  Future<QqMusicCredentials?> _readFromPlatformChannel() async {
    try {
      final payload = await _channel.invokeMapMethod<String, Object?>(
        'readQqMusicCredentials',
      );
      final cookie = payload?['cookie']?.toString();
      if (cookie == null || cookie.trim().isEmpty) {
        return null;
      }
      return QqMusicCredentials(cookie: cookie);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> _writeToPlatformChannel(QqMusicCredentials credentials) async {
    try {
      await _channel.invokeMethod<void>('writeQqMusicCredentials', {
        'cookie': credentials.cookie,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> _clearPlatformChannel() async {
    try {
      await _channel.invokeMethod<void>('deleteQqMusicCredentials');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  QqMusicCredentials? _readFromEnvironment() {
    final cookie = Platform.environment[_cookieEnv];
    if (cookie == null || cookie.trim().isEmpty) {
      return null;
    }
    return QqMusicCredentials(cookie: cookie);
  }
}
