import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  group('RemoteAudioTrack()', () {
    test('should not construct without name', () async {
      expect(() => RemoteAudioTrack('sid', true, null), throwsAssertionError);
    });

    test('should not construct without enabled', () async {
      expect(() => RemoteAudioTrack('sid', null, 'name'), throwsAssertionError);
    });
  });
}
