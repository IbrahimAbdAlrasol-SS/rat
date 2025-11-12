import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_access_service.dart';

final notificationAccessProvider =
    AsyncNotifierProvider<NotificationAccessController, bool>(
      NotificationAccessController.new,
    );

class NotificationAccessController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return NotificationAccessService.hasAccess();
  }

  Future<void> refreshStatus() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(NotificationAccessService.hasAccess);
  }

  Future<void> openSettings() async {
    await NotificationAccessService.openSettings();
  }
}
