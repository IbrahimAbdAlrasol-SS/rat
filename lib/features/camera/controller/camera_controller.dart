import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/camera_service.dart';

// Provider للخدمة
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

// Provider لآخر صورة تم التقاطها
final lastSelfieProvider = StateProvider<File?>((ref) => null);

// Provider لجميع الصور المحفوظة
final savedSelfiesProvider = FutureProvider<List<File>>((ref) async {
  final service = ref.watch(cameraServiceProvider);
  return service.getSavedSelfies();
});

// Controller للكاميرا
class CameraController extends StateNotifier<AsyncValue<File?>> {
  final CameraService _cameraService;
  final Ref _ref;

  CameraController(this._cameraService, this._ref) : super(const AsyncValue.data(null));

  /// التقاط صورة سيلفي
  Future<void> takeSelfie() async {
    state = const AsyncValue.loading();

    try {
      final file = await _cameraService.takeSelfie();

      if (file != null) {
        // تحديث آخر صورة
        _ref.read(lastSelfieProvider.notifier).state = file;

        // إعادة تحميل قائمة الصور
        _ref.invalidate(savedSelfiesProvider);

        state = AsyncValue.data(file);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// طلب الصلاحيات
  Future<bool> requestPermissions() async {
    return await _cameraService.requestPermissions();
  }

  /// التحقق من الصلاحيات
  Future<bool> hasPermissions() async {
    return await _cameraService.hasPermissions();
  }

  /// حذف صورة
  Future<void> deleteSelfie(File file) async {
    await _cameraService.deleteSelfie(file);

    // تحديث آخر صورة إذا كانت هي المحذوفة
    if (_ref.read(lastSelfieProvider) == file) {
      _ref.read(lastSelfieProvider.notifier).state = null;
    }

    // إعادة تحميل قائمة الصور
    _ref.invalidate(savedSelfiesProvider);
  }
}

// Provider للـ controller
final cameraControllerProvider = StateNotifierProvider<CameraController, AsyncValue<File?>>((ref) {
  final service = ref.watch(cameraServiceProvider);
  return CameraController(service, ref);
});
