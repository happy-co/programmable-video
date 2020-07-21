import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../model_instances.dart';

void main() {
  final remoteParticipant = ModelInstances.remoteParticipantModel;
  final remoteAudioTrack = ModelInstances.remoteAudioTrackModel;
  final remoteAudioTrackPublication = ModelInstances.remoteAudioTrackPublicationModel;
  final remoteVideoTrack = ModelInstances.remoteVideoTrackModel;
  final remoteVideoTrackPublication = ModelInstances.remoteVideoTrackPublicationModel;
  final remoteDataTrack = ModelInstances.remoteDataTrackModel;
  final remoteDataTrackPublication = ModelInstances.remoteDataTrackPublicationModel;
  final twilioException = ModelInstances.twilioExceptionModel;

  group('.toString()', () {
    test('RemoteAudioTrackDisabled.toString() should return correct String', () {
      final event = RemoteAudioTrackDisabled(remoteParticipant, remoteAudioTrackPublication);
      expect(
        event.toString(),
        'RemoteAudioTrackDisabled: { remoteParticipantModel: $remoteParticipant, remoteAudioTrackPublicationModel: $remoteAudioTrackPublication }',
      );
    });

    test('RemoteAudioTrackEnabled.toString() should return correct String', () {
      final event = RemoteAudioTrackEnabled(remoteParticipant, remoteAudioTrackPublication);
      expect(
        event.toString(),
        'RemoteAudioTrackEnabled: { remoteParticipantModel: $remoteParticipant, remoteAudioTrackPublicationModel: $remoteAudioTrackPublication }',
      );
    });

    test('RemoteAudioTrackPublished.toString() should return correct String', () {
      final event = RemoteAudioTrackPublished(remoteParticipant, remoteAudioTrackPublication);
      expect(
        event.toString(),
        'RemoteAudioTrackPublished: { remoteParticipantModel: $remoteParticipant, remoteAudioTrackPublicationModel: $remoteAudioTrackPublication }',
      );
    });

    test('RemoteAudioTrackSubscribed.toString() should return correct String', () {
      final event = RemoteAudioTrackSubscribed(
        remoteAudioTrackModel: remoteAudioTrack,
        remoteAudioTrackPublicationModel: remoteAudioTrackPublication,
        remoteParticipantModel: remoteParticipant,
      );
      expect(event.toString(), '''RemoteAudioTrackSubscribed: { 
    remoteParticipantModel: $remoteParticipant, remoteAudioTrackPublicationModel: $remoteAudioTrackPublication, remoteAudioTrackModel: $remoteAudioTrack
  }''');
    });

    test('RemoteAudioTrackSubscriptionFailed.toString() should return correct String', () {
      final event = RemoteAudioTrackSubscriptionFailed(
        exception: twilioException,
        remoteAudioTrackPublicationModel: remoteAudioTrackPublication,
        remoteParticipantModel: remoteParticipant,
      );
      expect(event.toString(), '''RemoteAudioTrackSubscriptionFailed: { 
    remoteParticipantModel: $remoteParticipant, remoteAudioTrackPublicationModel: $remoteAudioTrackPublication, exception: $twilioException
  }''');
    });

    test('RemoteAudioTrackUnpublished.toString() should return correct String', () {
      final event = RemoteAudioTrackUnpublished(remoteParticipant, remoteAudioTrackPublication);
      expect(
        event.toString(),
        'RemoteAudioTrackUnpublished: { remoteParticipantModel: $remoteParticipant, remoteAudioTrackPublicationModel: $remoteAudioTrackPublication }',
      );
    });

    test('RemoteAudioTrackUnsubscribed.toString() should return correct String', () {
      final event = RemoteAudioTrackUnsubscribed(
        remoteAudioTrackModel: remoteAudioTrack,
        remoteAudioTrackPublicationModel: remoteAudioTrackPublication,
        remoteParticipantModel: remoteParticipant,
      );
      expect(event.toString(), '''RemoteAudioTrackUnsubscribed: { 
    remoteParticipantModel: $remoteParticipant, remoteAudioTrackPublicationModel: $remoteAudioTrackPublication, remoteAudioTrackModel: $remoteAudioTrack
  }''');
    });

    test('RemoteDataTrackPublished.toString() should return correct String', () {
      final event = RemoteDataTrackPublished(remoteParticipant, remoteDataTrackPublication);
      expect(
        event.toString(),
        'RemoteDataTrackPublished: { remoteParticipantModel: $remoteParticipant, remoteDataTrackPublicationModel: $remoteDataTrackPublication }',
      );
    });

    test('RemoteDataTrackSubscribed.toString() should return correct String', () {
      final event = RemoteDataTrackSubscribed(
        remoteDataTrackModel: remoteDataTrack,
        remoteDataTrackPublicationModel: remoteDataTrackPublication,
        remoteParticipantModel: remoteParticipant,
      );
      expect(event.toString(), '''RemoteDataTrackSubscribed: { 
    remoteParticipantModel: $remoteParticipant, remoteDataTrackPublicationModel: $remoteDataTrackPublication, remoteDataTrackModel: $remoteDataTrack
  }''');
    });

    test('RemoteDataTrackSubscriptionFailed.toString() should return correct String', () {
      final event = RemoteDataTrackSubscriptionFailed(
        exception: twilioException,
        remoteDataTrackPublicationModel: remoteDataTrackPublication,
        remoteParticipantModel: remoteParticipant,
      );
      expect(event.toString(), '''RemoteDataTrackSubscriptionFailed: { 
    remoteParticipantModel: $remoteParticipant, remoteDataTrackPublicationModel: $remoteDataTrackPublication, exception: $twilioException
  }''');
    });

    test('RemoteDataTrackUnpublished.toString() should return correct String', () {
      final event = RemoteDataTrackUnpublished(remoteParticipant, remoteDataTrackPublication);
      expect(
        event.toString(),
        'RemoteDataTrackUnpublished: { remoteParticipantModel: $remoteParticipant, remoteDataTrackPublicationModel: $remoteDataTrackPublication }',
      );
    });

    test('RemoteDataTrackUnsubscribed.toString() should return correct String', () {
      final event = RemoteDataTrackUnsubscribed(
        remoteDataTrackModel: remoteDataTrack,
        remoteDataTrackPublicationModel: remoteDataTrackPublication,
        remoteParticipantModel: remoteParticipant,
      );
      expect(event.toString(), '''RemoteDataTrackUnsubscribed: { 
    remoteParticipantModel: $remoteParticipant, remoteDataTrackPublicationModel: $remoteDataTrackPublication, remoteDataTrackModel: $remoteDataTrack
  }''');
    });

    test('RemoteVideoTrackDisabled.toString() should return correct String', () {
      final event = RemoteVideoTrackDisabled(remoteParticipant, remoteVideoTrackPublication);
      expect(
        event.toString(),
        'RemoteVideoTrackDisabled: { remoteParticipantModel: $remoteParticipant, remoteVideoTrackPublicationModel: $remoteVideoTrackPublication }',
      );
    });

    test('RemoteVideoTrackEnabled.toString() should return correct String', () {
      final event = RemoteVideoTrackEnabled(remoteParticipant, remoteVideoTrackPublication);
      expect(
        event.toString(),
        'RemoteVideoTrackEnabled: { remoteParticipantModel: $remoteParticipant, remoteVideoTrackPublicationModel: $remoteVideoTrackPublication }',
      );
    });

    test('RemoteVideoTrackPublished.toString() should return correct String', () {
      final event = RemoteVideoTrackPublished(remoteParticipant, remoteVideoTrackPublication);
      expect(
        event.toString(),
        'RemoteVideoTrackPublished: { remoteParticipantModel: $remoteParticipant, remoteVideoTrackPublicationModel: $remoteVideoTrackPublication }',
      );
    });

    test('RemoteVideoTrackSubscribed.toString() should return correct String', () {
      final event = RemoteVideoTrackSubscribed(
        remoteVideoTrackModel: remoteVideoTrack,
        remoteVideoTrackPublicationModel: remoteVideoTrackPublication,
        remoteParticipantModel: remoteParticipant,
      );
      expect(event.toString(), '''RemoteVideoTrackSubscribed: { 
    remoteParticipantModel: $remoteParticipant, remoteVideoTrackPublicationModel: $remoteVideoTrackPublication, remoteVideoTrackModel: $remoteVideoTrack
  }''');
    });

    test('RemoteVideoTrackSubscriptionFailed.toString() should return correct String', () {
      final event = RemoteVideoTrackSubscriptionFailed(
        exception: twilioException,
        remoteVideoTrackPublicationModel: remoteVideoTrackPublication,
        remoteParticipantModel: remoteParticipant,
      );
      expect(event.toString(), '''RemoteVideoTrackSubscriptionFailed: { 
    remoteParticipantModel: $remoteParticipant, remoteVideoTrackPublicationModel: $remoteVideoTrackPublication, exception: $twilioException
  }''');
    });

    test('RemoteVideoTrackUnpublished.toString() should return correct String', () {
      final event = RemoteVideoTrackUnpublished(remoteParticipant, remoteVideoTrackPublication);
      expect(
        event.toString(),
        'RemoteVideoTrackUnpublished: { remoteParticipantModel: $remoteParticipant, remoteVideoTrackPublicationModel: $remoteVideoTrackPublication }',
      );
    });

    test('RemoteVideoTrackUnsubscribed.toString() should return correct String', () {
      final event = RemoteVideoTrackUnsubscribed(
        remoteVideoTrackModel: remoteVideoTrack,
        remoteVideoTrackPublicationModel: remoteVideoTrackPublication,
        remoteParticipantModel: remoteParticipant,
      );
      expect(event.toString(), '''RemoteVideoTrackUnsubscribed: { 
    remoteParticipantModel: $remoteParticipant, remoteVideoTrackPublicationModel: $remoteVideoTrackPublication, remoteVideoTrackModel: $remoteVideoTrack
  }''');
    });

    test('SkipAbleRemoteParticipantEvent.toString() should return correct String', () {
      final event = SkipAbleRemoteParticipantEvent();
      expect(event.toString(), 'SkipAbleRemoteParticipantEvent');
    });
  });
}
