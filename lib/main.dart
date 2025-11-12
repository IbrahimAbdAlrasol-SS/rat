import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/services/background_service.dart';
import 'features/notifications/view/notif_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundServiceInitializer.ensureInitialized();

  // طلب صلاحيات الكاميرا والتخزين عند بدء التطبيق
  await _requestPermissions();

  runApp(const ProviderScope(child: NotificationApp()));
}

/// طلب الصلاحيات الأساسية عند بدء التطبيق
Future<void> _requestPermissions() async {
  // طلب صلاحية الكاميرا
  await Permission.camera.request();

  // طلب صلاحيات التخزين حسب نسخة Android
  final photosStatus = await Permission.photos.request();

  if (Platform.isAndroid && !photosStatus.isGranted) {
    await Permission.storage.request();
  }
}

class NotificationApp extends StatelessWidget {
  const NotificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ورقة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: false,
      ),
      home: const NotifScreen(),
    );
  }
}
