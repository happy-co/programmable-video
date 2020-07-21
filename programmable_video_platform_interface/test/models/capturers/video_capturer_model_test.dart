import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final isScreencast = false;

  group('.toString()', () {
    test('should return correct String', () {
      final model = VideoCapturerModel(isScreencast);
      expect(model.toString(), '{ isScreencast: $isScreencast }');
    });
  });
}
