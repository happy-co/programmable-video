import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final code = 20101;
  final message = 'access token invalid';

  group('.toString()', () {
    test('should return correct String', () {
      final model = TwilioExceptionModel(code, message);
      expect(model.toString(), '{ code: $code, message: $message }');
    });
  });
}
