import 'dart:io';

import 'package:flutter/services.dart';
import 'package:provider_netease/provider_netease.dart';

import 'netease_session_store.dart';

const _channel = MethodChannel('melo_union/provider_credentials');
const _cookieEnv = 'MELO_NETEASE_COOKIE';
const _userIdEnv = 'MELO_NETEASE_USER_ID';

NeteaseSessionStore createNeteaseSessionStore() {
  return _PlatformNeteaseSessionStore();
}

final class _PlatformNeteaseSessionStore implements NeteaseSessionStore {
  NeteaseCredentials? _memoryCredentials;

  @override
  Future<NeteaseCredentials?> read() async {
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
  Future<void> write(NeteaseCredentials credentials) async {
    if (!credentials.hasCookie) {
      throw ArgumentError.value(
        credentials.cookie,
        'credentials.cookie',
        'NetEase cookie must not be empty.',
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

  Future<NeteaseCredentials?> _readFromPlatformChannel() async {
    try {
      final payload = await _channel.invokeMapMethod<String, Object?>(
        'readNeteaseCredentials',
      );
      final cookie = payload?['cookie']?.toString();
      if (cookie == null || cookie.trim().isEmpty) {
        return null;
      }
      return NeteaseCredentials(
        cookie: cookie,
        userId: _blankToNull(payload?['userId']?.toString()),
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> _writeToPlatformChannel(NeteaseCredentials credentials) async {
    try {
      await _channel.invokeMethod<void>('writeNeteaseCredentials', {
        'cookie': credentials.cookie,
        if (credentials.userId != null) 'userId': credentials.userId,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> _clearPlatformChannel() async {
    try {
      await _channel.invokeMethod<void>('deleteNeteaseCredentials');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  NeteaseCredentials? _readFromEnvironment() {
    final cookie = Platform.environment[_cookieEnv];
    if (cookie == null || cookie.trim().isEmpty) {
      return null;
    }
    return NeteaseCredentials(
      cookie: cookie,
      userId: _blankToNull(Platform.environment[_userIdEnv]),
    );
  }

  String? _blankToNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}
