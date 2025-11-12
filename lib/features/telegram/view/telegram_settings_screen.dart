import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/telegram_settings.dart';
import '../controller/telegram_settings_controller.dart';

class TelegramSettingsScreen extends ConsumerStatefulWidget {
  const TelegramSettingsScreen({super.key});

  @override
  ConsumerState<TelegramSettingsScreen> createState() =>
      _TelegramSettingsScreenState();
}

class _TelegramSettingsScreenState
    extends ConsumerState<TelegramSettingsScreen> {
  late TextEditingController _botTokenController;
  late TextEditingController _chatIdController;
  bool _isEnabled = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _botTokenController = TextEditingController();
    _chatIdController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(telegramSettingsProvider).valueOrNull;
      if (settings != null) {
        _botTokenController.text = settings.botToken;
        _chatIdController.text = settings.chatId;
        _isEnabled = settings.isEnabled;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _botTokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final settings = TelegramSettings(
      botToken: _botTokenController.text.trim(),
      chatId: _chatIdController.text.trim(),
      isEnabled: _isEnabled,
    );

    if (!settings.isValid) {
      _showMessage('الرجاء إدخال توكن البوت ومعرف الدردشة');
      return;
    }

    final success =
        await ref.read(telegramSettingsProvider.notifier).saveSettings(settings);

    if (success) {
      _showMessage('تم حفظ الإعدادات بنجاح');
    } else {
      _showMessage('فشل حفظ الإعدادات');
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);

    // حفظ الإعدادات أولاً
    await _saveSettings();

    final success =
        await ref.read(telegramSettingsProvider.notifier).testConnection();

    setState(() => _isTesting = false);

    if (success) {
      _showMessage('✅ الاتصال ناجح! تحقق من بوت تلكرام الخاص بك');
    } else {
      _showMessage('❌ فشل الاتصال. تحقق من المعلومات المدخلة');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات تلكرام'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'كيفية الحصول على المعلومات:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoStep('1', 'افتح @BotFather في تلكرام'),
                      _buildInfoStep('2', 'أرسل /newbot لإنشاء بوت جديد'),
                      _buildInfoStep('3', 'احفظ توكن البوت (Bot Token)'),
                      _buildInfoStep('4', 'افتح @userinfobot للحصول على معرف الدردشة (Chat ID)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _botTokenController,
                decoration: const InputDecoration(
                  labelText: 'توكن البوت (Bot Token)',
                  hintText: '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _chatIdController,
                decoration: const InputDecoration(
                  labelText: 'معرف الدردشة (Chat ID)',
                  hintText: '123456789',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.chat),
                ),
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('تفعيل إرسال الإشعارات'),
                subtitle: const Text('عند التفعيل، سيتم إرسال جميع الإشعارات إلى تلكرام'),
                value: _isEnabled,
                onChanged: (value) {
                  setState(() => _isEnabled = value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isTesting ? 'جاري الاختبار...' : 'اختبار الاتصال'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('حفظ الإعدادات'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text(
              number,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
