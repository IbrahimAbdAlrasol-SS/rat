class TelegramSettings {
  const TelegramSettings({
    required this.botToken,
    required this.chatId,
    required this.isEnabled,
  });

  final String botToken;
  final String chatId;
  final bool isEnabled;

  bool get isValid => botToken.isNotEmpty && chatId.isNotEmpty;

  TelegramSettings copyWith({
    String? botToken,
    String? chatId,
    bool? isEnabled,
  }) {
    return TelegramSettings(
      botToken: botToken ?? this.botToken,
      chatId: chatId ?? this.chatId,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'botToken': botToken,
        'chatId': chatId,
        'isEnabled': isEnabled,
      };

  factory TelegramSettings.fromJson(Map<String, dynamic> json) {
    return TelegramSettings(
      botToken: json['botToken']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      isEnabled: json['isEnabled'] == true,
    );
  }

  static const empty = TelegramSettings(
    botToken: '',
    chatId: '',
    isEnabled: false,
  );
}
