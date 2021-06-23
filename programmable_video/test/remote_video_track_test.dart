import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  group('RemoteVideoTrack()', () {
    test('should not construct without name', () async {
      expect(() => RemoteVideoTrack('sid', true, null, MockRemoteParticipant()), throwsAssertionError);
    });

    test('should not construct without enabled', () async {
      expect(() => RemoteVideoTrack('sid', null, 'name', MockRemoteParticipant()), throwsAssertionError);
    });
  });
}

class MockRemoteParticipant extends Mock implements RemoteParticipant {}
