import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/notification_model.dart';
import '../../telegram/view/telegram_settings_screen.dart';
import '../../camera/view/camera_screen.dart';
import '../../bot_commands/controller/bot_command_controller.dart';
import '../controller/notif_controller.dart';
import '../controller/notification_access_controller.dart';

class NotifScreen extends ConsumerStatefulWidget {
  const NotifScreen({super.key});

  @override
  ConsumerState<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends ConsumerState<NotifScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // بدء خدمة الأوامر
    Future.microtask(() => ref.read(botCommandControllerProvider));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationAccessProvider.notifier).refreshStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = ref.watch(notificationAccessProvider);
    final notificationsState = ref.watch(notificationsProvider);
    final botCommandStatus = ref.watch(botCommandControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مراقب الإشعارات'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.camera_alt),
              tooltip: 'الكاميرا',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.telegram),
              tooltip: 'إعدادات تلكرام',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelegramSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'الوضع الحالي',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      permission.when(
                        data: (hasAccess) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hasAccess
                                  ? 'الوصول للإشعارات مفعّل'
                                  : 'الوصول للإشعارات غير مفعّل',
                            ),
                            Icon(
                              hasAccess ? Icons.check_circle : Icons.error,
                              color: hasAccess
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                          ],
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('خطأ: ${err.toString()}'),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('خدمة استقبال الأوامر'),
                          Row(
                            children: [
                              Icon(
                                botCommandStatus
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: botCommandStatus
                                    ? Colors.green
                                    : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                botCommandStatus ? 'نشط' : 'متوقف',
                                style: TextStyle(
                                  color: botCommandStatus
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(notificationAccessProvider.notifier)
                              .openSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('تفعيل الخدمة'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(notificationAccessProvider.notifier)
                              .refreshStatus();
                        },
                        child: const Text('تحديث الحالة'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'آخر الإشعارات المستلمة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: notificationsState.when(
                  data: (items) => items.isEmpty
                      ? const Center(
                          child: Text('لم يتم التقاط أي إشعارات بعد.'),
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notification = items[index];
                            return _NotificationTile(
                              notification: notification,
                            );
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      Center(child: Text('خطأ أثناء قراءة الإشعارات: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title.isEmpty ? 'بدون عنوان' : notification.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              notification.text.isEmpty ? 'لا يوجد محتوى' : notification.text,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _InfoChip(label: 'التطبيق', value: notification.package),
                _InfoChip(
                  label: 'الوقت',
                  value: notification.time.toLocal().toIso8601String(),
                ),
                if (notification.actions.isNotEmpty)
                  _InfoChip(
                    label: 'عدد الإجراءات',
                    value: notification.actions.length.toString(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
