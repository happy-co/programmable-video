import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import 'model_instances.dart';

void main() {
  final remoteDataTrack = ModelInstances.remoteDataTrackModel;

  group('.toString()', () {
    test('StringMessage.toString() should return correct String', () {
      final message = 'test';
      final event = StringMessage(remoteDataTrack, message);
      expect(
        event.toString(),
        'StringMessage: { remoteDataTrackModel: $remoteDataTrack, message: $message }',
      );
    });

    test('BufferMessage.toString() should return correct String', () {
      final dynamic message = null;
      final event = BufferMessage(remoteDataTrack, message);
      expect(
        event.toString(),
        'StringMessage: { remoteDataTrackModel: $remoteDataTrack, message: $message }',
      );
    });

    test('UnknownEvent.toString() should return correct String', () {
      final eventName = 'unknown';
      final event = UnknownEvent(remoteDataTrack, eventName);
      expect(
        event.toString(),
        'UnknownEvent: { eventName: $eventName }',
      );
    });

    test('SkippableRemoteDataTrackEvent.toString() should return correct String', () {
      final event = SkippableRemoteDataTrackEvent();
      expect(
        event.toString(),
        'SkippableRemoteDataTrackEvent',
      );
    });
  });
}
