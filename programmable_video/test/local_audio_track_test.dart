import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'mock_platform_interface.dart';

void main() {
  MockInterface mockInterface;
  setUpAll(() {
    mockInterface = MockInterface();
    ProgrammableVideoPlatform.instance = mockInterface;
  });

  group('LocalAudioTrack()', () {
    test('should not construct without enabled', () async {
      expect(() => LocalAudioTrack(null), throwsAssertionError);
    });
  });

  group('.enable()', () {
    test('should call interface code to enable the track', () async {
      final localAudioTrack = LocalAudioTrack(true);
      await localAudioTrack.enable(false);

      expect(mockInterface.enableAudioTrackWasCalled, true);
    });
  });

  group('.isEnabled()', () {
    test('should return correct value', () async {
      final constructionBool = true;
      final localAudioTrack = LocalAudioTrack(constructionBool);
      expect(localAudioTrack.isEnabled, constructionBool);
      await localAudioTrack.enable(!constructionBool);
      expect(localAudioTrack.isEnabled, !constructionBool);
    });
  });
}
