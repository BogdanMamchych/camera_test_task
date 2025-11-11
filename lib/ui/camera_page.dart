import 'package:camera/camera.dart';
import 'package:camera_test_task/providers/camera_providers.dart';
import 'package:camera_test_task/providers/static_photo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraPage extends ConsumerWidget {
  const CameraPage({super.key});

  void _switchCamera(WidgetRef ref) {
    final camerasAsync = ref.read(camerasProvider);
    if (camerasAsync is AsyncData<List<CameraDescription>>) {
      final cameras = camerasAsync.value;
      if (cameras.length < 2) return;

      final idxNotifier = ref.read(cameraIndexProvider.notifier);
      idxNotifier.state = (idxNotifier.state + 1) % cameras.length;
    }
  }

  Future<void> _takePicture(BuildContext context, WidgetRef ref) async {
    final controllerAsync = ref.read(cameraControllerProvider);
    final lastImagePathNotifier = ref.read(lastImagePathProvider.notifier);

    if (controllerAsync is AsyncLoading) return;
    if (controllerAsync is AsyncError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Камера недоступна')));
      return;
    }

    try {
      final controller = (controllerAsync as AsyncData<CameraController>).value;
      final XFile file = await controller.takePicture();
      lastImagePathNotifier.state = file.path;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка зйомки: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider);
    final showStaticPhoto = ref.watch(showStaticPhotoProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 38.0, left: 15),
            child: Text(
              "Camera test task",
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                camerasAsync.when(
                  data: (cameras) {
                    if (cameras.isEmpty) {
                      return const Center(child: Text('Камер не знайдено'));
                    }

                    final controllerAsync = ref.watch(cameraControllerProvider);

                    return controllerAsync.when(
                      data: (controller) {
                        if (!controller.value.isInitialized ||
                            controller.value.previewSize == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final previewSize = controller.value.previewSize!;
                        final bool rotated =
                            controller.description.sensorOrientation == 90 ||
                                controller.description.sensorOrientation == 270;

                        final double previewWidth =
                            rotated ? previewSize.height : previewSize.width;
                        final double previewHeight =
                            rotated ? previewSize.width : previewSize.height;

                        return Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: previewWidth,
                              height: previewHeight,
                              child: CameraPreview(controller),
                            ),
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(
                        child: Text('Помилка ініціалізації камери: $e'),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      Center(child: Text('Помилка при отриманні камер: $e')),
                ),

                if (showStaticPhoto)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.8,
                      child: Image(
                        image: const AssetImage('assets/images/static_photo.jpg'),
                        colorBlendMode: BlendMode.modulate,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Кнопки внизу — SafeArea, щоб не лізли під системні елементи
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.cameraswitch),
                            onPressed: () => _switchCamera(ref),
                          ),
                          IconButton(
                            onPressed: () => _takePicture(context, ref),
                            icon: const Icon(Icons.camera_alt),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(showStaticPhotoProvider.notifier).state =
                                  !showStaticPhoto;
                            },
                            icon: const Icon(Icons.photo_library),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
