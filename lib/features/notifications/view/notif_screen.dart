import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePermission();
    });
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
      _ensurePermission();
    }
  }

  Future<void> _ensurePermission() async {
    final notifier = ref.read(notificationAccessProvider.notifier);
    await notifier.refreshStatus();
    final hasAccess = ref.read(notificationAccessProvider).value ?? false;
    if (!hasAccess) {
      await notifier.openSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationAccessProvider);
    ref.watch(notificationsProvider);

    return const ColoredBox(color: Colors.white);
  }
}
