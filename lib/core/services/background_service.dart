import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundServiceInitializer {
  const BackgroundServiceInitializer._();

  static Future<void> ensureInitialized() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onServiceStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'notification_watcher_channel',
        initialNotificationTitle: 'Notification watcher نشط',
        initialNotificationContent: 'يعمل في الخلفية لالتقاط الإشعارات',
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );

    await service.startService();
  }
}

@pragma('vm:entry-point')
Future<void> onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
    await service.setForegroundNotificationInfo(
      title: 'Notification watcher',
      content: 'الخدمة تعمل في الخلفية.',
    );
  }
}
