import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  group('RemoteAudioTrackPublication()', () {
    test('should not construct without sid', () async {
      expect(() => RemoteAudioTrackPublication(true, true, null, 'name'), throwsAssertionError);
    });

    test('should not construct without name', () async {
      expect(() => RemoteAudioTrackPublication(true, true, 'sid', null), throwsAssertionError);
    });

    test('should construct without subscribed', () async {
      expect(RemoteAudioTrackPublication(null, true, 'sid', 'name'), isA<RemoteAudioTrackPublication>());
    });

    test('should construct without enabled', () async {
      expect(RemoteAudioTrackPublication(true, null, 'sid', 'name'), isA<RemoteAudioTrackPublication>());
    });
  });
}
