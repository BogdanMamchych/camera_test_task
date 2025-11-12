import 'package:test/test.dart';
import 'package:camera_test_task/models/camera_model.dart';

void main() {
  group('CameraModel', () {
    test('default values', () {
      final m = CameraModel();
      expect(m.isRecording, isFalse);
      expect(m.overlayPath, isNull);
      expect(m.recordSeconds, equals(0));
      expect(m.lastImagePath, isNull);
    });

    test('copyWith updates fields correctly', () {
      final m = CameraModel(isRecording: false, overlayPath: null, recordSeconds: 0, lastImagePath: null);
      final m2 = m.copyWith(isRecording: true, overlayPath: 'path.png', recordSeconds: 10, lastImagePath: 'img.jpg');

      expect(m2.isRecording, isTrue);
      expect(m2.overlayPath, equals('path.png'));
      expect(m2.recordSeconds, equals(10));
      expect(m2.lastImagePath, equals('img.jpg'));
    });

    test('copyWith keeps old values when null passed', () {
      final m = CameraModel(isRecording: true, overlayPath: 'old.png', recordSeconds: 5, lastImagePath: 'old.jpg');
      final m2 = m.copyWith(overlayPath: null);

      expect(m2.overlayPath, equals('old.png'));
      expect(m2.isRecording, equals(true));
      expect(m2.recordSeconds, equals(5));
      expect(m2.lastImagePath, equals('old.jpg'));
    });
  });
}
