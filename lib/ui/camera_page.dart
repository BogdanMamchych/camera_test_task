import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:camera_test_task/providers/camera_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  bool isRecording = false;
  String? overlayPath; // path to picked overlay image
  Timer? _recordTimer;
  int _recordSeconds = 0;

  String get _formattedRecordTime {
    final minutes = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startRecordTimer() {
    _recordTimer?.cancel();
    _recordSeconds = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordSeconds++;
      });
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
    _recordSeconds = 0;
  }

  Future<void> _toggleRecording() async {
    final controllerAsync = ref.read(cameraControllerProvider);
    if (controllerAsync is AsyncLoading) return;
    if (controllerAsync is AsyncError) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Камера недоступна')));
      return;
    }

    final controller = (controllerAsync as AsyncData<CameraController>).value;

    try {
      if (!isRecording) {
        await controller.prepareForVideoRecording();
        await controller.startVideoRecording();
        setState(() {
          isRecording = true;
        });
        _startRecordTimer();
      } else {
        // stop recording
        final XFile file = await controller.stopVideoRecording();
        setState(() {
          isRecording = false;
        });
        _stopRecordTimer();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Відео збережено: ${file.path}')),
        );
      }
    } catch (e) {
      setState(() {
        isRecording = false;
      });
      _stopRecordTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка запису: $e')));
    }
  }

  Future<void> _switchCamera(WidgetRef ref) async {
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Знімок збережено')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка зйомки: $e')));
    }
  }

  Future<void> _pickOverlayImage() async {
    try {
      final XFile? picked =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          overlayPath = picked.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не вдалося вибрати зображення: $e')),
      );
    }
  }

  // overlay button: if overlay already set -> remove it, otherwise open gallery
  Future<void> _onOverlayButtonPressed() async {
    if (overlayPath != null) {
      setState(() {
        overlayPath = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оверлей вимкнений')),
      );
    } else {
      await _pickOverlayImage();
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camerasAsync = ref.watch(camerasProvider);

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
                    if (cameras.isEmpty) {
                      return const Center(child: Text('Cameras not found'));
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

                        final double previewWidth = rotated
                            ? previewSize.height
                            : previewSize.width;
                        final double previewHeight = rotated
                            ? previewSize.width
                            : previewSize.height;

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
                        child: Text('Initialization camera error: $e'),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      Center(child: Text('Error opening camera: $e')),
                ),

                if (overlayPath != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.8,
                      child: Image.file(
                        File(overlayPath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                if (isRecording)
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
                              _formattedRecordTime,
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
                            onPressed: () => _switchCamera(ref),
                          ),

                          GestureDetector(
                            onTap: () => _takePicture(context, ref),
                            onLongPress: () => _toggleRecording(),
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
                                boxShadow: isRecording
                                    ? [
                                        BoxShadow(
                                          color: Colors.red.withValues(alpha: 0.2),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: isRecording ? 46 : 56,
                                height: isRecording ? 46 : 56,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),

                          IconButton(
                            icon: Icon(
                              overlayPath != null ? Icons.layers : Icons.image,
                              color: Colors.white,
                            ),
                            tooltip: overlayPath != null
                                ? 'Видалити оверлей'
                                : 'Додати оверлей з галереї',
                            onPressed: _onOverlayButtonPressed,
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
