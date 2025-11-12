import 'package:camera_test_task/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/camera_state.dart';
import '../repositories/camera_repository.dart';
import 'dart:async';

class CameraViewModel extends StateNotifier<CameraState> {
  final Ref ref;
  late final ICameraRepository _repo;
  Timer? _recordTimer;

  CameraViewModel(this.ref) : super(const CameraState()) {
    _repo = ref.read(cameraRepositoryProvider);
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isBusy: true, error: null);
    try {
      final cams = await _repo.availableCamerasList();
      state = state.copyWith(cameras: cams);
      if (cams.isNotEmpty) {
        await switchCamera(0);
      }
      state = state.copyWith(isBusy: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isBusy: false);
    }
  }

  Future<void> switchCamera(int index) async {
    if (index < 0 || index >= state.cameras.length) return;
    state = state.copyWith(isBusy: true, error: null);
    try {
      final old = state.controller;
      if (old != null) await _repo.disposeController(old);

      final controller = await _repo.createController(
        state.cameras[index],
        ResolutionPreset.high,
      );

      state = state.copyWith(
        controller: controller,
        selectedIndex: index,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isBusy: false);
    }
  }

  Future<void> takePicture() async {
    final ctl = state.controller;
    if (ctl == null || !ctl.value.isInitialized || ctl.value.isTakingPicture) return;
    state = state.copyWith(isBusy: true);
    try {
      final file = await ctl.takePicture();
      state = state.copyWith(lastPhotoPath: file.path, isBusy: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isBusy: false);
    }
  }

  Future<void> startRecording() async {
    final ctl = state.controller;
    if (ctl == null || !ctl.value.isInitialized || state.isRecording) return;
    try {
      await ctl.startVideoRecording();
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {});
      state = state.copyWith(isRecording: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopRecording() async {
    final ctl = state.controller;
    if (ctl == null || !state.isRecording) return;
    try {
      final file = await ctl.stopVideoRecording();
      _recordTimer?.cancel();
      _recordTimer = null;
      state = state.copyWith(isRecording: false, lastPhotoPath: file.path);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pickOverlay(String path) async {
    state = state.copyWith(overlayPath: path);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    try {
      state.controller?.dispose();
    } catch (_) {}
    super.dispose();
  }
}
