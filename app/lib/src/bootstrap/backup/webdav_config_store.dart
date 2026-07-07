import 'package:flutter/services.dart';

import 'backup_target.dart';

abstract interface class WebDavConfigStore {
  Future<WebDavConfig?> read();

  Future<void> write(WebDavConfig config);

  Future<void> clear();
}

final class PlatformWebDavConfigStore implements WebDavConfigStore {
  const PlatformWebDavConfigStore({
    MethodChannel channel = const MethodChannel(
      'melo_union/provider_credentials',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<WebDavConfig?> read() async {
    try {
      final payload = await _channel.invokeMapMethod<String, Object?>(
        'readWebDavConfig',
      );
      final url = payload?['url']?.toString();
      final username = payload?['username']?.toString();
      final password = payload?['password']?.toString();
      final remoteDirectory = payload?['remoteDirectory']?.toString();
      if (url == null ||
          url.trim().isEmpty ||
          username == null ||
          username.trim().isEmpty ||
          password == null ||
          password.isEmpty) {
        return null;
      }
      return WebDavConfig(
        baseUri: Uri.parse(url.trim()),
        username: username.trim(),
        password: password,
        remoteDirectory: remoteDirectory?.trim().isNotEmpty == true
            ? remoteDirectory!.trim()
            : '/MeloUnion/backups/',
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(WebDavConfig config) async {
    try {
      await _channel.invokeMethod<void>('writeWebDavConfig', {
        'url': config.baseUri.toString(),
        'username': config.username,
        'password': config.password,
        'remoteDirectory': config.remoteDirectory,
      });
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('deleteWebDavConfig');
    } on MissingPluginException {
      return;
    }
  }
}
