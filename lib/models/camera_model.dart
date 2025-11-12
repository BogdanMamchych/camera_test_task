class CameraModel {
  final bool isRecording;
  final String? overlayPath;
  final int recordSeconds;
  final String? lastImagePath;

  const CameraModel({
    this.isRecording = false,
    this.overlayPath,
    this.recordSeconds = 0,
    this.lastImagePath,
  });

  CameraModel copyWith({
    bool? isRecording,
    String? overlayPath,
    int? recordSeconds,
    String? lastImagePath,
  }) {
    return CameraModel(
      isRecording: isRecording ?? this.isRecording,
      overlayPath: overlayPath ?? this.overlayPath,
      recordSeconds: recordSeconds ?? this.recordSeconds,
      lastImagePath: lastImagePath ?? this.lastImagePath,
    );
  }
}