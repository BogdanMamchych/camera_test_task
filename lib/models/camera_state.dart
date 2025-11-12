import 'package:camera/camera.dart';

class CameraState {
  final List<CameraDescription> cameras;
  final CameraController? controller;
  final int selectedIndex;
  final bool isRecording;
  final bool isBusy;
  final String? error;
  final String? lastPhotoPath;
  final String? overlayPath;

  const CameraState({
    this.cameras = const [],
    this.controller,
    this.selectedIndex = 0,
    this.isRecording = false,
    this.isBusy = false,
    this.error,
    this.lastPhotoPath,
    this.overlayPath,
  });

  CameraState copyWith({
    List<CameraDescription>? cameras,
    CameraController? controller,
    int? selectedIndex,
    bool? isRecording,
    bool? isBusy,
    String? error,
    String? lastPhotoPath,
    String? overlayPath,
  }) {
    return CameraState(
      cameras: cameras ?? this.cameras,
      controller: controller ?? this.controller,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isRecording: isRecording ?? this.isRecording,
      isBusy: isBusy ?? this.isBusy,
      error: error,
      lastPhotoPath: lastPhotoPath ?? this.lastPhotoPath,
      overlayPath: overlayPath ?? this.overlayPath,
    );
  }
}
