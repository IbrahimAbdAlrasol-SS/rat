import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/utils/logger.dart';
import '../models/notification_model.dart';
import '../models/telegram_settings.dart';

final telegramServiceProvider = Provider<TelegramService>(
  (ref) => TelegramService(),
);

class TelegramService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<bool> sendNotification({
    required NotificationModel notification,
    required TelegramSettings settings,
  }) async {
    if (!settings.isValid || !settings.isEnabled) {
      return false;
    }

    try {
      final message = _formatNotificationMessage(notification);
      final url =
          'https://api.telegram.org/bot${settings.botToken}/sendMessage';

      final response = await _dio.post(
        url,
        data: {
          'chat_id': settings.chatId,
          'text': message,
          'parse_mode': 'HTML',
        },
      );

      if (response.statusCode == 200) {
        logInfo('تم إرسال الإشعار إلى تلكرام بنجاح');
        return true;
      } else {
        logError('فشل إرسال الإشعار: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logError('خطأ في إرسال الإشعار إلى تلكرام: $e');
      return false;
    }
  }

  Future<bool> testConnection(TelegramSettings settings) async {
    if (!settings.isValid) {
      return false;
    }

    try {
      final url = 'https://api.telegram.org/bot${settings.botToken}/getMe';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['ok'] == true) {
        final botUsername = response.data['result']['username'];
        logInfo('اتصال ناجح مع البوت: @$botUsername');

        // إرسال رسالة تجريبية
        await _dio.post(
          'https://api.telegram.org/bot${settings.botToken}/sendMessage',
          data: {
            'chat_id': settings.chatId,
            'text': '✅ تم الاتصال بنجاح!\n\nبوت مراقبة الإشعارات جاهز للعمل.',
          },
        );

        return true;
      }

      return false;
    } catch (e) {
      logError('خطأ في اختبار الاتصال: $e');
      return false;
    }
  }

  String _formatNotificationMessage(NotificationModel notification) {
    final buffer = StringBuffer();

    buffer.writeln('🔔 <b>إشعار جديد</b>\n');

    if (notification.title.isNotEmpty) {
      buffer.writeln('📌 <b>العنوان:</b>');
      buffer.writeln(_escapeHtml(notification.title));
      buffer.writeln();
    }

    if (notification.text.isNotEmpty) {
      buffer.writeln('💬 <b>المحتوى:</b>');
      buffer.writeln(_escapeHtml(notification.text));
      buffer.writeln();
    }

    buffer.writeln('📱 <b>التطبيق:</b> ${_escapeHtml(notification.package)}');
    buffer.writeln('🕐 <b>الوقت:</b> ${_formatTime(notification.time)}');

    if (notification.actions.isNotEmpty) {
      buffer.writeln(
        '\n⚡ <b>الإجراءات:</b> ${notification.actions.join(", ")}',
      );
    }

    return buffer.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }
}
