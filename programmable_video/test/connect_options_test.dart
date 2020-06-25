import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  group('ConnectOptions()', () {
    test('should not construct without accessToken', () async {
      expect(() => ConnectOptions(null), throwsAssertionError);
      expect(() => ConnectOptions(''), throwsAssertionError);
    });

    test('should not construct with empty audioTracks list', () async {
      expect(() => ConnectOptions('token', audioTracks: []), throwsAssertionError);
    });

    test('should not construct with empty dataTracks list', () async {
      expect(() => ConnectOptions('token', dataTracks: []), throwsAssertionError);
    });

    test('should not construct with empty videoTracks list', () async {
      expect(() => ConnectOptions('token', videoTracks: []), throwsAssertionError);
    });

    test('should not construct with empty preferredAudioCodecs list', () async {
      expect(() => ConnectOptions('token', preferredAudioCodecs: []), throwsAssertionError);
    });

    test('should not construct with empty preferredVideoCodecs list', () async {
      expect(() => ConnectOptions('token', preferredVideoCodecs: []), throwsAssertionError);
    });
  });
}
