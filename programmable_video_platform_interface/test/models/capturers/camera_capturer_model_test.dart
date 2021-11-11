import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/camera_source.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final source = CameraSource('FRONT_CAMERA', false, false, false);
  final type = 'type';

  group('.toString()', () {
    test('should return correct String', () {
      final model = CameraCapturerModel(source, type);
      expect(model.toString(), '{ source: $source, type: $type, isScreencast: false }');
    });
  });
}
