import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('RemoteVideoTrackPublication()', () {
    test('should not construct without sid', () async {
      expect(() => RemoteVideoTrackPublication(true, true, null, 'name', MockRemoteParticipant()), throwsAssertionError);
    });

    test('should not construct without name', () async {
      expect(() => RemoteVideoTrackPublication(true, true, 'sid', null, MockRemoteParticipant()), throwsAssertionError);
    });

    test('should not construct without remoteParticipant', () async {
      expect(() => RemoteVideoTrackPublication(true, true, 'sid', null, null), throwsAssertionError);
    });

    test('should construct without subscribed', () async {
      expect(RemoteVideoTrackPublication(null, true, 'sid', 'name', MockRemoteParticipant()), isA<RemoteVideoTrackPublication>());
    });

    test('should construct without enabled', () async {
      expect(RemoteVideoTrackPublication(true, null, 'sid', 'name', MockRemoteParticipant()), isA<RemoteVideoTrackPublication>());
    });
  });
}

class MockRemoteParticipant extends Mock implements RemoteParticipant {}
