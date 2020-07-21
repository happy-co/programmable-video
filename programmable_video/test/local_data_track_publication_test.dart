import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  group('LocalDataTrackPublication()', () {
    test('should not construct without sid', () async {
      expect(() => LocalDataTrackPublication(null), throwsAssertionError);
    });
  });
}
