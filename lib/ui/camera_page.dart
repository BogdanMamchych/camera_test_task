import 'package:camera/camera.dart';
import 'package:camera_test_task/providers/camera_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraPage extends ConsumerWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider);
    final lastImagePath = ref.watch(lastImagePathProvider);

    return Scaffold(
      body: Column(
        children: [
          Text("Camera test task"),
          Expanded(
            child: camerasAsync.when(
              data: (cameras) {
                if (cameras.isEmpty) {
                  return const Center(child: Text('Камер не знайдено'));
                }

                // Спостерігаємо за провайдером контролера
                final controllerAsync = ref.watch(cameraControllerProvider);

                return controllerAsync.when(
                  data: (controller) => CameraPreview(controller),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      Center(child: Text('Помилка ініціалізації камери: \$e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Помилка при отриманні камер: \$e')),
            ),
          ),
        ],
      ),
    );
  }
}
