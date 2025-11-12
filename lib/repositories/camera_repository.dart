import 'package:camera/camera.dart';

abstract class ICameraRepository {
  Future<List<CameraDescription>> availableCamerasList();
  Future<CameraController> createController(
    CameraDescription desc,
    ResolutionPreset preset,
  );
  Future<void> disposeController(CameraController controller);
}

class CameraRepository implements ICameraRepository {
  @override
  Future<List<CameraDescription>> availableCamerasList() async {
    return await availableCameras();
  }

  @override
  Future<CameraController> createController(
    CameraDescription desc,
    ResolutionPreset preset,
  ) async {
    final controller = CameraController(desc, preset);
    await controller.initialize();
    return controller;
  }

  @override
  Future<void> disposeController(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (_) {}
  }
}
