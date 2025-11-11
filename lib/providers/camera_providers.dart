import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final camerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

final cameraIndexProvider = StateProvider<int>((ref) => 0);

final cameraControllerProvider = FutureProvider.autoDispose<CameraController>((
  ref,
) async {
  final cameras = await ref.watch(camerasProvider.future);
  final index = ref.watch(cameraIndexProvider);
  final desc = cameras[index];

  final controller = CameraController(
    desc,
    ResolutionPreset.medium,
    enableAudio: true,
  );
  await controller.initialize();

  ref.onDispose(() {
    try {
      controller.dispose();
    } catch (_) {}
  });

  return controller;
});

final lastImagePathProvider = StateProvider<String?>((ref) => null);
