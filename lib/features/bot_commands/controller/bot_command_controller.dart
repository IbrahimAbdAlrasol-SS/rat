import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bot_command_service.dart';

final botCommandControllerProvider =
    StateNotifierProvider<BotCommandController, bool>(
  (ref) => BotCommandController(ref),
);

class BotCommandController extends StateNotifier<bool> {
  BotCommandController(this._ref) : super(false) {
    // بدء الخدمة تلقائياً
    _startService();
  }

  final Ref _ref;

  void _startService() {
    final service = _ref.read(botCommandServiceProvider);
    service.startListening();
    state = true;
  }

  void toggleService() {
    final service = _ref.read(botCommandServiceProvider);

    if (state) {
      service.stopListening();
      state = false;
    } else {
      service.startListening();
      state = true;
    }
  }

  @override
  void dispose() {
    final service = _ref.read(botCommandServiceProvider);
    service.stopListening();
    super.dispose();
  }
}
