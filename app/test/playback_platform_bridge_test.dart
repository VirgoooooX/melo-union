import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/platform/playback_platform_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(playbackPlatformChannelName);

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loadQueue serializes playback items for Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      receivedCall = call;
      return true;
    });

    final didLoad = await const PlaybackPlatformBridge().loadQueue(
      [
        PlatformPlaybackItem(
          mediaUri: Uri.parse('https://example.test/audio.mp3'),
          title: 'Midnight Signal',
          artists: const ['Luna Park'],
          providerId: 'aurora_stream',
          trackId: 'alpha_midnight',
          headers: const {'Authorization': 'Bearer demo'},
          expiresAt: DateTime.utc(2026, 6, 29, 12),
        ),
      ],
      playWhenReady: true,
    );

    expect(didLoad, isTrue);
    expect(receivedCall?.method, 'loadQueue');
    final arguments = Map<String, Object?>.from(
      receivedCall!.arguments as Map<Object?, Object?>,
    );
    expect(arguments['playWhenReady'], isTrue);

    final items =
        jsonDecode(arguments['itemsJson']! as String) as List<Object?>;
    final item = Map<String, Object?>.from(items.single! as Map);
    expect(item['mediaUri'], 'https://example.test/audio.mp3');
    expect(item['title'], 'Midnight Signal');
    expect(item['artist'], 'Luna Park');
    expect(item['providerId'], 'aurora_stream');
    expect(item['trackId'], 'alpha_midnight');
    expect(item['expiresAt'], '2026-06-29T12:00:00.000Z');
  });

  test('commands are no-ops on non-Android platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var wasCalled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      wasCalled = true;
      return true;
    });

    final didPlay = await const PlaybackPlatformBridge().play();

    expect(didPlay, isFalse);
    expect(wasCalled, isFalse);
  });
}
