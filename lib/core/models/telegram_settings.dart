import '../config/telegram_config.dart';

class TelegramSettings {
  const TelegramSettings._({required this.chatId, required this.isEnabled});

  final String chatId;
  final bool isEnabled;

  String get botToken => TelegramConfig.botToken;

  bool get isValid => chatId.isNotEmpty && botToken.isNotEmpty;

  static const instance = TelegramSettings._(
    chatId: TelegramConfig.chatId,
    isEnabled: TelegramConfig.isEnabledByDefault,
  );
}
