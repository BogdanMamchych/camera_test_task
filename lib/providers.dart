import 'package:camera_test_task/models/camera_state.dart';
import 'package:camera_test_task/view_models/camera_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'repositories/camera_repository.dart';


final cameraRepositoryProvider = Provider<ICameraRepository>((ref) => CameraRepository());

final cameraViewModelProvider =
    StateNotifierProvider<CameraViewModel, CameraState>(
  (ref) => CameraViewModel(ref),
);