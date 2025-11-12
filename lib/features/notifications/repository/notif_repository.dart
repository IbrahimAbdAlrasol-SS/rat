import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/utils/logger.dart';
import '../../../core/models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

class NotificationRepository {
  NotificationRepository();

  static const _channel = EventChannel('notification_stream/events');

  Stream<NotificationModel> notificationStream() {
    return _channel.receiveBroadcastStream().map((dynamic event) {
      final String payload = event is String ? event : jsonEncode(event);
      logJson(payload);
      return NotificationModel.fromJsonString(payload);
    });
  }
}
