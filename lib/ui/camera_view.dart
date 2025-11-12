import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/camera_providers.dart';
import '../view_models/camera_view_model.dart';

class CameraView extends ConsumerWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider);
    final model = ref.watch(cameraViewModelProvider);
    final viewModel = ref.read(cameraViewModelProvider.notifier);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 38.0, left: 15),
            child: Text(
              "Camera test task",
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                camerasAsync.when(
                  data: (cameras) {
                    if (cameras.isEmpty) return const Center(child: Text('Cameras not found'));

                    final controllerAsync = ref.watch(cameraControllerProvider);

                    return controllerAsync.when(
                      data: (controller) {
                        if (!controller.value.isInitialized || controller.value.previewSize == null) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final previewSize = controller.value.previewSize!;
                        final bool rotated = controller.description.sensorOrientation == 90 || controller.description.sensorOrientation == 270;

                        final double previewWidth = rotated ? previewSize.height : previewSize.width;
                        final double previewHeight = rotated ? previewSize.width : previewSize.height;

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
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('Initialization camera error: \$e')),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error opening camera: \$e')),
                ),

                if (model.overlayPath != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.8,
                      child: Image.file(
                        File(model.overlayPath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                if (model.isRecording)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0, right: 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              viewModel.formattedRecordTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.cameraswitch,
                              color: Colors.white,
                            ),
                            onPressed: () => viewModel.switchCamera(),
                          ),

                          GestureDetector(
                            onTap: () async {
                              final message = await viewModel.takePicture();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                            },
                            onLongPress: () async {
                              final message = await viewModel.toggleRecording();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 76,
                              height: 76,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: model.isRecording
                                    ? [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.2),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: model.isRecording ? 46 : 56,
                                height: model.isRecording ? 46 : 56,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),

                          IconButton(
                            icon: Icon(
                              model.overlayPath != null ? Icons.layers : Icons.image,
                              color: Colors.white,
                            ),
                            tooltip: model.overlayPath != null ? 'Видалити оверлей' : 'Додати оверлей з галереї',
                            onPressed: () async {
                              final message = await viewModel.onOverlayButtonPressed();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                            },
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
