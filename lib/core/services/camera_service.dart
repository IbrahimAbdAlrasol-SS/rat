import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

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
    final storageGranted = await Permission.storage.isGranted ||
                          await Permission.photos.isGranted;

    return cameraGranted && storageGranted;
  }

  /// التقاط صورة سيلفي (الكاميرا الأمامية)
  Future<File?> takeSelfie() async {
    try {
      // التحقق من الصلاحيات أولاً
      final hasPerms = await hasPermissions();
      if (!hasPerms) {
        final granted = await requestPermissions();
        if (!granted) {
          return null;
        }
      }

      // التقاط الصورة باستخدام الكاميرا الأمامية
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (photo == null) {
        return null;
      }

      // حفظ الصورة في مجلد التطبيق
      final File imageFile = File(photo.path);
      final savedFile = await _saveImageLocally(imageFile);

      return savedFile;
    } catch (e) {
      print('خطأ في التقاط الصورة: $e');
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

      print('تم حفظ الصورة في: $savedPath');
      return savedFile;
    } catch (e) {
      print('خطأ في حفظ الصورة: $e');
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
      files.sort((a, b) =>
        b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files;
    } catch (e) {
      print('خطأ في جلب الصور: $e');
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
      print('خطأ في حذف الصورة: $e');
      return false;
    }
  }
}
