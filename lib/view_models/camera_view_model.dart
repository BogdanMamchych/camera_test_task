import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../models/camera_model.dart';
import '../providers/camera_providers.dart';

final cameraViewModelProvider =
    StateNotifierProvider<CameraViewModel, CameraModel>(
      (ref) => CameraViewModel(ref),
    );

class CameraViewModel extends StateNotifier<CameraModel> {
  final Ref ref;
  Timer? _recordTimer;

  CameraViewModel(this.ref) : super(const CameraModel());

  String get formattedRecordTime {
    final minutes = (state.recordSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.recordSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(recordSeconds: state.recordSeconds + 1);
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
    state = state.copyWith(recordSeconds: 0);
  }

  //if loading or error, return String, if success, return CameraController
  Object initCameraController() {
    final controllerAsync = ref.read(cameraControllerProvider);

    if (controllerAsync is AsyncLoading) return 'Camera is loading';
    if (controllerAsync is AsyncError) return 'Camera is unavailable';

    final controller = (controllerAsync as AsyncData<CameraController>).value;
    return controller;
  }

  Future<String> toggleRecording() async {
    final controllerResult = initCameraController();
    if (controllerResult is String) {
      return controllerResult;
    } else {
      final CameraController controller = controllerResult as CameraController;

      try {
        if (!state.isRecording) {
          await controller.prepareForVideoRecording();
          await controller.startVideoRecording();
          state = state.copyWith(isRecording: true);
          _startRecordTimer();
          return 'Почато запис';
        } else {
          final XFile file = await controller.stopVideoRecording();
          state = state.copyWith(isRecording: false, lastImagePath: file.path);
          _stopRecordTimer();
          return 'Video is saved: ${file.path}';
        }
      } catch (e) {
        state = state.copyWith(isRecording: false);
        _stopRecordTimer();
        return 'Recording error: \$e';
      }
    }
  }

  Future<String> takePicture() async {
    final controllerResult = initCameraController();
    if (controllerResult is String) {
      return controllerResult;
    } else {
      final CameraController controller = controllerResult as CameraController;
      try {
        final XFile file = await controller.takePicture();
        state = state.copyWith(lastImagePath: file.path);
        return 'Photo is saved: ${file.path}';
      } catch (e) {
        return 'Shooting error: \$e';
      }
    }
  }

  Future<void> switchCamera() async {
    final camerasAsync = ref.read(camerasProvider);
    if (camerasAsync is AsyncData<List<CameraDescription>>) {
      final cameras = camerasAsync.value;
      if (cameras.length < 2) return;

      final idxNotifier = ref.read(cameraIndexProvider.notifier);
      idxNotifier.state = (idxNotifier.state + 1) % cameras.length;
    }
  }

  Future<String> pickOverlayImage() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (picked != null) {
        state = state.copyWith(overlayPath: picked.path);
        return 'Оверлей додано';
      }
      return 'Оберіть зображення';
    } catch (e) {
      return 'Не вдалося вибрати зображення: \$e';
    }
  }

  Future<String> onOverlayButtonPressed() async {
    if (state.overlayPath != null) {
      state = state.copyWith(overlayPath: null);
      return 'Оверлей вимкнений';
    } else {
      return await pickOverlayImage();
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    super.dispose();
  }
}
