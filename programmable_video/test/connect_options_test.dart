import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  group('ConnectOptions()', () {
    test('should not construct without accessToken', () async {
      expect(() => ConnectOptions(''), throwsAssertionError);
    });
  });
}
