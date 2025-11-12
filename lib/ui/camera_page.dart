import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class CameraPage extends ConsumerWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraViewModelProvider);
    final vm = ref.read(cameraViewModelProvider.notifier);

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera')),
        body: Center(child: Text('Error: ${state.error}')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Column(
        children: [
          if (state.controller == null || !state.controller!.value.isInitialized)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            AspectRatio(
              aspectRatio: state.controller!.value.aspectRatio,
              child: CameraPreview(state.controller!),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () => vm.takePicture(),
                  child: const Icon(Icons.camera_alt),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: state.isRecording ? () => vm.stopRecording() : () => vm.startRecording(),
                  child: Text(state.isRecording ? 'Stop' : 'Record'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
