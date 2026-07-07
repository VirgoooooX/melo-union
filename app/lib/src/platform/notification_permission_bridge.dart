import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String notificationPermissionChannelName = 'melo_union/notifications';

final class NotificationPermissionBridge {
  const NotificationPermissionBridge();

  static const MethodChannel _channel =
      MethodChannel(notificationPermissionChannelName);

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> requestPostNotifications() async {
    if (!isSupported) {
      return true;
    }
    try {
      return await _channel.invokeMethod<bool>('requestPostNotifications') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
