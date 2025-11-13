import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/notification_model.dart';
import '../../../core/models/telegram_settings.dart';
import '../../../core/services/telegram_service.dart';
import '../repository/notif_repository.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<NotificationModel>>(
      NotificationsController.new,
    );

class NotificationsController extends AsyncNotifier<List<NotificationModel>> {
  StreamSubscription<NotificationModel>? _subscription;

  @override
  FutureOr<List<NotificationModel>> build() {
    final repository = ref.read(notificationRepositoryProvider);

    _subscription ??= repository.notificationStream().listen(
      _handleIncomingNotification,
    );

    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });

    return const [];
  }

  Future<void> _handleIncomingNotification(
    NotificationModel notification,
  ) async {
    final current = state.value ?? const <NotificationModel>[];
    final updated = <NotificationModel>[notification, ...current];
    state = AsyncValue.data(updated.take(50).toList());

    // إرسال الإشعار إلى تلكرام
    _sendToTelegram(notification);
  }

  Future<void> _sendToTelegram(NotificationModel notification) async {
    try {
      final settings = TelegramSettings.instance;
      if (settings.isValid && settings.isEnabled) {
        await ref
            .read(telegramServiceProvider)
            .sendNotification(notification: notification, settings: settings);
      }
    } catch (e) {
      // تجاهل الأخطاء لعدم تعطيل التطبيق
    }
  }
}
