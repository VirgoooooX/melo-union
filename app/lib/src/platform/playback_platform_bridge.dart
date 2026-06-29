import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String playbackPlatformChannelName = 'melounion/playback';

final class PlatformPlaybackItem {
  const PlatformPlaybackItem({
    required this.mediaUri,
    required this.title,
    required this.artists,
    required this.providerId,
    required this.trackId,
    this.headers = const {},
    this.expiresAt,
  });

  final Uri mediaUri;
  final String title;
  final List<String> artists;
  final String providerId;
  final String trackId;
  final Map<String, String> headers;
  final DateTime? expiresAt;

  Map<String, Object?> toJson() {
    return {
      'mediaUri': mediaUri.toString(),
      'title': title,
      'artist': artists.join(', '),
      'artists': artists,
      'providerId': providerId,
      'trackId': trackId,
      'headers': headers,
      'expiresAt': expiresAt?.toUtc().toIso8601String(),
    };
  }
}

final class PlaybackPlatformBridge {
  const PlaybackPlatformBridge();

  static const MethodChannel _channel =
      MethodChannel(playbackPlatformChannelName);

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> loadQueue(
    List<PlatformPlaybackItem> items, {
    required bool playWhenReady,
  }) {
    final itemsJson = jsonEncode([
      for (final item in items) item.toJson(),
    ]);
    return _invokeBool('loadQueue', {
      'itemsJson': itemsJson,
      'playWhenReady': playWhenReady,
    });
  }

  Future<bool> play() => _invokeBool('play');

  Future<bool> pause() => _invokeBool('pause');

  Future<bool> stop() => _invokeBool('stop');

  Future<bool> next() => _invokeBool('next');

  Future<bool> previous() => _invokeBool('previous');

  Future<Map<String, Object?>> status() async {
    if (!isSupported) {
      return const {'state': 'unsupported'};
    }
    try {
      final value = await _channel.invokeMapMethod<String, Object?>('status');
      return value ?? const {'state': 'unknown'};
    } on MissingPluginException {
      return const {'state': 'unsupported'};
    }
  }

  Future<bool> _invokeBool(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!isSupported) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>(method, arguments) ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
