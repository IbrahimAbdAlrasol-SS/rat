import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../common/utils/logger.dart';

class CameraService {
  Future<CameraDescription?> _findFrontCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return null;
      }

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          return camera;
        }
      }

      return cameras.first;
    } catch (e) {
      logError('تعذر الحصول على معلومات الكاميرا: $e');
      return null;
    }
  }

  /// طلب صلاحيات الكاميرا والتخزين
  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    // For Android 13+ (API 33+), use photos permission
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      return cameraStatus.isGranted &&
          (storageStatus.isGranted || photosStatus.isGranted);
    }

    return cameraStatus.isGranted && storageStatus.isGranted;
  }

  /// التحقق من حالة الصلاحيات
  Future<bool> hasPermissions() async {
    final cameraGranted = await Permission.camera.isGranted;
    final storageGranted =
        await Permission.storage.isGranted || await Permission.photos.isGranted;

    return cameraGranted && storageGranted;
  }

  /// التقاط صورة سيلفي (الكاميرا الأمامية)
  Future<File?> takeSelfie() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // التحقق من الصلاحيات أولاً
      final hasPerms = await hasPermissions();
      if (!hasPerms) {
        final granted = await requestPermissions();
        if (!granted) {
          return null;
        }
      }

      final cameraDescription = await _findFrontCamera();
      if (cameraDescription == null) {
        logError('لم يتم العثور على كاميرا أمامية');
        return null;
      }

      final controller = CameraController(
        cameraDescription,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await controller.initialize();
        await controller.setFlashMode(FlashMode.off);

        final XFile captured = await controller.takePicture();
        final File imageFile = File(captured.path);
        final savedFile = await _saveImageLocally(imageFile);
        return savedFile;
      } finally {
        await controller.dispose();
      }
    } catch (e) {
      logError('خطأ في التقاط الصورة: $e');
      return null;
    }
  }

  /// حفظ الصورة في مجلد التطبيق المحلي
  Future<File> _saveImageLocally(File imageFile) async {
    try {
      // الحصول على مجلد التطبيق
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/selfies');

      // إنشاء المجلد إذا لم يكن موجوداً
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // إنشاء اسم فريد للصورة
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'selfie_$timestamp.jpg';
      final savedPath = '${imagesDir.path}/$fileName';

      // نسخ الصورة إلى المجلد المحلي
      final savedFile = await imageFile.copy(savedPath);

      logInfo('تم حفظ الصورة في: $savedPath');
      return savedFile;
    } catch (e) {
      logError('خطأ في حفظ الصورة: $e');
      return imageFile;
    }
  }

  /// الحصول على جميع الصور المحفوظة
  Future<List<File>> getSavedSelfies() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/selfies');

      if (!await imagesDir.exists()) {
        return [];
      }

      final files = await imagesDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.jpg'))
          .map((entity) => entity as File)
          .toList();

      // ترتيب حسب آخر تعديل (الأحدث أولاً)
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      return files;
    } catch (e) {
      logError('خطأ في جلب الصور: $e');
      return [];
    }
  }

  /// حذف صورة محددة
  Future<bool> deleteSelfie(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      logError('خطأ في حذف الصورة: $e');
      return false;
    }
  }
}
