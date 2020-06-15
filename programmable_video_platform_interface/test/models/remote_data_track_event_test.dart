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
      final message = null;
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

    test('SkipAbleRemoteDataTrackEvent.toString() should return correct String', () {
      final event = SkipAbleRemoteDataTrackEvent();
      expect(
        event.toString(),
        'SkipAbleRemoteDataTrackEvent',
      );
    });
  });
}
