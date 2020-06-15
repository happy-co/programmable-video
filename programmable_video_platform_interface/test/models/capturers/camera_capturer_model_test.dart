import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/camera_source.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final cameraSource = CameraSource.FRONT_CAMERA;
  final type = 'type';

  group('CameraCapturerModel()', () {
    test('should not construct without CameraSource', () {
      expect(() => CameraCapturerModel(null, type), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = CameraCapturerModel(cameraSource, type);
      expect(model.toString(), '{ source: $cameraSource, type: $type, isScreencast: false }');
    });
  });
}
