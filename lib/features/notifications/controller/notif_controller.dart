import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/notification_model.dart';
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

  void _handleIncomingNotification(NotificationModel notification) {
    final current = state.value ?? const <NotificationModel>[];
    final updated = <NotificationModel>[notification, ...current];
    state = AsyncValue.data(updated.take(50).toList());
  }
}
