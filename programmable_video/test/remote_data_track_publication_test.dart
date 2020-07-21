import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  group('RemoteVideoTrackPublication()', () {
    test('should not construct without sid', () async {
      expect(() => RemoteDataTrackPublication(true, true, null, 'name'), throwsAssertionError);
    });

    test('should not construct without name', () async {
      expect(() => RemoteDataTrackPublication(true, true, 'sid', null), throwsAssertionError);
    });

    test('should not construct without remoteParticipant', () async {
      expect(() => RemoteDataTrackPublication(true, true, 'sid', null), throwsAssertionError);
    });

    test('should construct without subscribed', () async {
      expect(RemoteDataTrackPublication(null, true, 'sid', 'name'), isA<RemoteDataTrackPublication>());
    });

    test('should construct without enabled', () async {
      expect(RemoteDataTrackPublication(true, null, 'sid', 'name'), isA<RemoteDataTrackPublication>());
    });
  });
}
