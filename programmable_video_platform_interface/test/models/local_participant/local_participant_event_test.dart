import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../model_instances.dart';

void main() {
  final localParticipant = ModelInstances.localParticipantModel;
  final twilioException = ModelInstances.twilioExceptionModel;
  final localAudioTrack = ModelInstances.localAudioTrackModel;
  final localAudioTrackPublication = ModelInstances.localAudioTrackPublicationModel;
  final localDataTrack = ModelInstances.localDataTrackModel;
  final localDataTrackPublication = ModelInstances.localDataTrackPublicationModel;
  final localVideoTrack = ModelInstances.localVideoTrackModel;
  final localVideoTrackPublication = ModelInstances.localVideoTrackPublicationModel;

  group('.toString()', () {
    test('LocalAudioTrackPublished.toString() should return correct String', () {
      final event = LocalAudioTrackPublished(localParticipant, localAudioTrackPublication);
      expect(
        event.toString(),
        'LocalAudioTrackPublished: { localParticipantModel: $localParticipant, publicationModel: $localAudioTrackPublication }',
      );
    });

    test('LocalAudioTrackPublicationFailed.toString() should return correct String', () {
      final event = LocalAudioTrackPublicationFailed(
        localParticipantModel: localParticipant,
        localAudioTrack: localAudioTrack,
        exception: twilioException,
      );
      expect(
        event.toString(),
        'LocalAudioTrackPublicationFailed: { localParticipantModel: $localParticipant, localAudioTrack: $localAudioTrack, exception: $twilioException }',
      );
    });

    test('LocalDataTrackPublished.toString() should return correct String', () {
      final event = LocalDataTrackPublished(localParticipant, localDataTrackPublication);
      expect(
        event.toString(),
        'LocalDataTrackPublished: { localParticipantModel: $localParticipant, publicationModel: $localDataTrackPublication }',
      );
    });

    test('LocalDataTrackPublicationFailed.toString() should return correct String', () {
      final event = LocalDataTrackPublicationFailed(
        localParticipantModel: localParticipant,
        localDataTrack: localDataTrack,
        exception: twilioException,
      );
      expect(
        event.toString(),
        'LocalDataTrackPublicationFailed: { localParticipantModel: $localParticipant, localDataTrack: $localDataTrack, exception: $twilioException }',
      );
    });

    test('LocalVideoTrackPublished.toString() should return correct String', () {
      final event = LocalVideoTrackPublished(localParticipant, localVideoTrackPublication);
      expect(
        event.toString(),
        'LocalVideoTrackPublished: { localParticipantModel: $localParticipant, publicationModel: $localVideoTrackPublication }',
      );
    });

    test('LocalVideoTrackPublicationFailed.toString() should return correct String', () {
      final event = LocalVideoTrackPublicationFailed(
        localParticipantModel: localParticipant,
        localVideoTrack: localVideoTrack,
        exception: twilioException,
      );
      expect(
        event.toString(),
        'LocalVideoTrackPublicationFailed: { localParticipantModel: $localParticipant, localVideoTrack: $localVideoTrack, exception: $twilioException }',
      );
    });

    test('SkipAbleLocalParticipantEvent.toString() should return correct String', () {
      final event = SkipAbleLocalParticipantEvent();
      expect(event.toString(), 'SkipAbleLocalParticipantEvent');
    });
  });
}
