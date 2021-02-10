import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../model_instances.dart';

void main() {
  final room = ModelInstances.roomModel;
  final twilioException = ModelInstances.twilioExceptionModel;
  final remoteParticipant = ModelInstances.remoteParticipantModel;

  group('.toString()', () {
    test('ConnectFailure.toString() should return correct String', () {
      final event = ConnectFailure(room, twilioException);
      expect(
        event.toString(),
        'ConnectFailure: { roomModel: $room, exception: $twilioException }',
      );
    });

    test('Connected.toString() should return correct String', () {
      final event = Connected(room);
      expect(event.toString(), 'Connected: { roomModel: $room }');
    });

    test('Disconnected.toString() should return correct String', () {
      final event = Disconnected(room, twilioException);
      expect(
        event.toString(),
        'Disconnected: { roomModel: $room, exception: $twilioException }',
      );
    });

    test('ParticipantConnected.toString() should return correct String', () {
      final event = ParticipantConnected(room, remoteParticipant);
      expect(
        event.toString(),
        'ParticipantConnected: { roomModel: $room, connectedParticipant: $remoteParticipant }',
      );
    });

    test('ParticipantDisconnected.toString() should return correct String', () {
      final event = ParticipantDisconnected(room, remoteParticipant);
      expect(
        event.toString(),
        'ParticipantDisconnected: { roomModel: $room, disconnectedParticipant: $remoteParticipant }',
      );
    });

    test('Reconnected.toString() should return correct String', () {
      final event = Reconnected(room);
      expect(event.toString(), 'Reconnected: { roomModel: $room }');
    });

    test('Reconnecting.toString() should return correct String', () {
      final event = Reconnecting(room, twilioException);
      expect(
        event.toString(),
        'Reconnecting: { roomModel: $room, exception: $twilioException }',
      );
    });

    test('RecordingStarted.toString() should return correct String', () {
      final event = RecordingStarted(room);
      expect(
        event.toString(),
        'RecordingStarted: { roomModel: $room }',
      );
    });

    test('RecordingStopped.toString() should return correct String', () {
      final event = RecordingStopped(room);
      expect(
        event.toString(),
        'RecordingStopped: { roomModel: $room }',
      );
    });

    test('DominantSpeakerChanged.toString() should return correct String', () {
      final event = DominantSpeakerChanged(room, remoteParticipant);
      expect(
        event.toString(),
        'DominantSpeakerChanged: { roomModel: $room, dominantSpeaker: $remoteParticipant }',
      );
    });

    test('SkipAbleRoomEvent.toString() should return correct String', () {
      final event = SkipAbleRoomEvent();
      expect(event.toString(), 'SkipAbleRoomEvent');
    });
  });
}
