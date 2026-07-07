import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/platform/notification_permission_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(notificationPermissionChannelName);

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('requestPostNotifications asks Android host for permission', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      receivedCall = call;
      return true;
    });

    final granted =
        await const NotificationPermissionBridge().requestPostNotifications();

    expect(granted, isTrue);
    expect(receivedCall?.method, 'requestPostNotifications');
  });

  test('requestPostNotifications is a no-op on non-Android platforms',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var wasCalled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      wasCalled = true;
      return true;
    });

    final granted =
        await const NotificationPermissionBridge().requestPostNotifications();

    expect(granted, isTrue);
    expect(wasCalled, isFalse);
  });
}
