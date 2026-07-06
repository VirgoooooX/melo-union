import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:provider_kugou/provider_kugou.dart';

import 'kugou_session_store.dart';

const _channel = MethodChannel('melo_union/provider_credentials');
const _sessionEnv = 'MELO_KUGOU_SESSION';

KugouSessionStore createKugouSessionStore() {
  return _PlatformKugouSessionStore();
}

final class _PlatformKugouSessionStore implements KugouSessionStore {
  KugouSession? _memorySession;

  @override
  Future<KugouSession?> read() async {
    if (_memorySession != null) {
      return _memorySession;
    }

    final platformSession = await _readFromPlatformChannel();
    if (platformSession != null) {
      _memorySession = platformSession;
      return platformSession;
    }

    return _readFromEnvironment();
  }

  @override
  Future<void> write(KugouSession session) async {
    _memorySession = session;
    await _writeToPlatformChannel(session);
  }

  @override
  Future<void> clear() async {
    _memorySession = null;
    await _clearPlatformChannel();
  }

  Future<KugouSession?> _readFromPlatformChannel() async {
    try {
      final payload = await _channel.invokeMapMethod<String, Object?>(
        'readKugouCredentials',
      );
      final raw = payload?['session']?.toString();
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return KugouSession.fromJson(decoded);
      }
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> _writeToPlatformChannel(KugouSession session) async {
    try {
      final raw = jsonEncode(session.toJson());
      await _channel.invokeMethod<void>('writeKugouCredentials', {
        'session': raw,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> _clearPlatformChannel() async {
    try {
      await _channel.invokeMethod<void>('deleteKugouCredentials');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  KugouSession? _readFromEnvironment() {
    final raw = Platform.environment[_sessionEnv];
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return KugouSession.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }
}
