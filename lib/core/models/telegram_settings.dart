import '../config/telegram_config.dart';

class TelegramSettings {
  const TelegramSettings({
    required this.chatId,
    required this.isEnabled,
  });

  final String chatId;
  final bool isEnabled;

  /// التوكن الثابت من الإعدادات
  String get botToken => TelegramConfig.botToken;

  bool get isValid => chatId.isNotEmpty;

  TelegramSettings copyWith({
    String? chatId,
    bool? isEnabled,
  }) {
    return TelegramSettings(
      chatId: chatId ?? this.chatId,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'chatId': chatId,
        'isEnabled': isEnabled,
      };

  factory TelegramSettings.fromJson(Map<String, dynamic> json) {
    return TelegramSettings(
      chatId: json['chatId']?.toString() ?? '',
      isEnabled: json['isEnabled'] == true,
    );
  }

  static const empty = TelegramSettings(
    chatId: '',
    isEnabled: false,
  );
}
