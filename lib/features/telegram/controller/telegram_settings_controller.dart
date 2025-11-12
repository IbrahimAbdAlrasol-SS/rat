import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/telegram_settings.dart';
import '../../../core/services/telegram_service.dart';
import '../../../core/services/telegram_settings_service.dart';

final telegramSettingsProvider =
    StateNotifierProvider<TelegramSettingsController, AsyncValue<TelegramSettings>>(
  (ref) => TelegramSettingsController(
    ref.watch(telegramSettingsServiceProvider),
    ref.watch(telegramServiceProvider),
  ),
);

class TelegramSettingsController
    extends StateNotifier<AsyncValue<TelegramSettings>> {
  TelegramSettingsController(
    this._settingsService,
    this._telegramService,
  ) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  final TelegramSettingsService _settingsService;
  final TelegramService _telegramService;

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _settingsService.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> saveSettings(TelegramSettings settings) async {
    try {
      final success = await _settingsService.saveSettings(settings);
      if (success) {
        state = AsyncValue.data(settings);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> testConnection() async {
    final currentSettings = state.valueOrNull;
    if (currentSettings == null || !currentSettings.isValid) {
      return false;
    }

    return await _telegramService.testConnection(currentSettings);
  }

  Future<void> toggleEnabled(bool enabled) async {
    final currentSettings = state.valueOrNull;
    if (currentSettings == null) return;

    final updatedSettings = currentSettings.copyWith(isEnabled: enabled);
    await saveSettings(updatedSettings);
  }
}
