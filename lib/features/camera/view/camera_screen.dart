import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/camera_controller.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraControllerProvider);
    final lastSelfie = ref.watch(lastSelfieProvider);
    final savedSelfiesAsync = ref.watch(savedSelfiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 الكاميرا - سيلفي'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // منطقة عرض الصورة
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple, width: 2),
              ),
              child: lastSelfie != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        lastSelfie,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_front,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد صورة',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط على الزر لالتقاط صورة سيلفي',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // زر التقاط الصورة
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: cameraState.isLoading
                    ? null
                    : () async {
                        final controller = ref.read(cameraControllerProvider.notifier);
                        await controller.takeSelfie();

                        if (context.mounted) {
                          cameraState.when(
                            data: (file) {
                              if (file != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ تم التقاط الصورة وحفظها محلياً'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            error: (error, _) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ خطأ: $error'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            loading: () {},
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: cameraState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.camera_alt, size: 28),
                label: Text(
                  cameraState.isLoading ? 'جاري التقاط الصورة...' : '📷 التقاط صورة سيلفي',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),

          // قائمة الصور المحفوظة
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          'الصور المحفوظة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: savedSelfiesAsync.when(
                      data: (selfies) {
                        if (selfies.isEmpty) {
                          return Center(
                            child: Text(
                              'لا توجد صور محفوظة',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: selfies.length,
                          itemBuilder: (context, index) {
                            final selfie = selfies[index];
                            return GestureDetector(
                              onTap: () {
                                ref.read(lastSelfieProvider.notifier).state = selfie;
                              },
                              onLongPress: () {
                                _showDeleteDialog(context, ref, selfie);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selfie,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text('خطأ في تحميل الصور: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل أنت متأكد من حذف هذه الصورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(cameraControllerProvider.notifier).deleteSelfie(file);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ تم حذف الصورة'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
