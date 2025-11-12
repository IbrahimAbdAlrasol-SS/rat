import 'package:flutter/services.dart';

class NotificationAccessService {
  const NotificationAccessService._();

  static const MethodChannel _channel = MethodChannel(
    'notification_access/methods',
  );

  static Future<bool> hasAccess() async {
    final result = await _channel.invokeMethod<bool>('checkPermission');
    return result ?? false;
  }

  static Future<void> openSettings() async {
    await _channel.invokeMethod<void>('openSettings');
  }
}
