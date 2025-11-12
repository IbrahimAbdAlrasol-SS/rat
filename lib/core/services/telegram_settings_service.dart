import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/telegram_settings.dart';

final telegramSettingsServiceProvider = Provider<TelegramSettingsService>(
  (ref) => TelegramSettingsService(),
);

class TelegramSettingsService {
  static const _key = 'telegram_settings';

  Future<TelegramSettings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);

      if (jsonString == null || jsonString.isEmpty) {
        return TelegramSettings.empty;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TelegramSettings.fromJson(json);
    } catch (e) {
      return TelegramSettings.empty;
    }
  }

  Future<bool> saveSettings(TelegramSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      return await prefs.setString(_key, jsonString);
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_key);
    } catch (e) {
      return false;
    }
  }
}
