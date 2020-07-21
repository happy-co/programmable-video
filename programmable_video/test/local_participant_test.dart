import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'mock_platform_interface.dart';
import 'model_instances.dart';

void main() {
  final roomModel = ModelInstances.roomModel;
  final localParticipantModel = ModelInstances.localParticipantModel;

  MockInterface mockInterface;
  Room room;
  LocalParticipant localParticipant;

  setUpAll(() async {
    mockInterface = MockInterface();
    ProgrammableVideoPlatform.instance = mockInterface;
    room = Room(0);

    mockInterface.addRoomEvent(Connected(roomModel));
    await room.onConnected.first;
    localParticipant = room.localParticipant;
  });

  group('LocalParticipant', () {
    test('should update properties correctly from an interface event', () async {
      const updateModel = LocalParticipantModel(
        identity: 'updateModel',
        sid: 'updateModel',
        signalingRegion: 'updateModel',
        networkQualityLevel: NetworkQualityLevel.NETWORK_QUALITY_LEVEL_FIVE,
        localAudioTrackPublications: <LocalAudioTrackPublicationModel>[],
        localDataTrackPublications: <LocalDataTrackPublicationModel>[],
        localVideoTrackPublications: <LocalVideoTrackPublicationModel>[],
      );

      mockInterface.addLocalParticipantEvent(LocalAudioTrackPublished(
        updateModel,
        ModelInstances.localAudioTrackPublicationModel,
      )); // a LocalAudioTrackPublished event is added here so that it can subsequently awaited
      await localParticipant.onAudioTrackPublished.first;
      expect(localParticipant.networkQualityLevel, updateModel.networkQualityLevel);
    });
  });

  group('.onAudioTrackPublished', () {
    test('should process `LocalAudioTrackPublished` correctly', () async {
      mockInterface.addLocalParticipantEvent(LocalAudioTrackPublished(
        localParticipantModel,
        ModelInstances.localAudioTrackPublicationModel,
      ));
      final event = await localParticipant.onAudioTrackPublished.first;
      expect(event, isA<LocalAudioTrackPublishedEvent>());
      expect(event.localParticipant, localParticipant);
      expect(
        event.localAudioTrackPublication.localAudioTrack.name,
        ModelInstances.localAudioTrackPublicationModel.localAudioTrack.name,
      );
    });
  });

  group('.onAudioTrackPublicationFailed', () {
    test('should process `LocalAudioTrackPublicationFailed` correctly', () async {
      mockInterface.addLocalParticipantEvent(LocalAudioTrackPublicationFailed(
        localParticipantModel: localParticipantModel,
        localAudioTrack: ModelInstances.localAudioTrackModel,
        exception: ModelInstances.twilioExceptionModel,
      ));
      final event = await localParticipant.onAudioTrackPublicationFailed.first;
      expect(event, isA<LocalAudioTrackPublicationFailedEvent>());
      expect(event.localParticipant, localParticipant);
      expect(
        event.localAudioTrack.name,
        ModelInstances.localAudioTrackModel.name,
      );
    });
  });

  group('.onDataTrackPublished', () {
    test('should process `LocalDataTrackPublished` correctly', () async {
      final interfaceEvent = LocalDataTrackPublished(
        localParticipantModel,
        ModelInstances.localDataTrackPublicationModel,
      );
      mockInterface.addLocalParticipantEvent(interfaceEvent);
      final event = await localParticipant.onDataTrackPublished.first;
      expect(event, isA<LocalDataTrackPublishedEvent>());
      expect(event.localParticipant, localParticipant);
      expect(
        event.localDataTrackPublication.localDataTrack.name,
        ModelInstances.localDataTrackPublicationModel.localDataTrack.name,
      );
    });
  });

  group('.onDataTrackPublicationFailed', () {
    test('should process `LocalDataTrackPublicationFailed` correctly', () async {
      mockInterface.addLocalParticipantEvent(LocalDataTrackPublicationFailed(
        localParticipantModel: localParticipantModel,
        localDataTrack: ModelInstances.localDataTrackModel,
        exception: ModelInstances.twilioExceptionModel,
      ));
      final event = await localParticipant.onDataTrackPublicationFailed.first;
      expect(event, isA<LocalDataTrackPublicationFailedEvent>());
      expect(event.localParticipant, localParticipant);
      expect(
        event.localDataTrack.name,
        ModelInstances.localDataTrackModel.name,
      );
    });
  });

  group('.onVideoTrackPublished', () {
    test('should process `LocalVideoTrackPublished` correctly', () async {
      mockInterface.addLocalParticipantEvent(LocalVideoTrackPublished(
        localParticipantModel,
        ModelInstances.localVideoTrackPublicationModel,
      ));
      final event = await localParticipant.onVideoTrackPublished.first;
      expect(event, isA<LocalVideoTrackPublishedEvent>());
      expect(event.localParticipant, localParticipant);
      expect(
        event.localVideoTrackPublication.localVideoTrack.name,
        ModelInstances.localVideoTrackPublicationModel.localVideoTrack.name,
      );
    });
  });

  group('.onVideoTrackPublicationFailed', () {
    test('should process `LocalVideoTrackPublicationFailed` correctly', () async {
      mockInterface.addLocalParticipantEvent(LocalVideoTrackPublicationFailed(
        localParticipantModel: localParticipantModel,
        localVideoTrack: ModelInstances.localVideoTrackModel,
        exception: ModelInstances.twilioExceptionModel,
      ));
      final event = await localParticipant.onVideoTrackPublicationFailed.first;
      expect(event, isA<LocalVideoTrackPublicationFailedEvent>());
      expect(event.localParticipant, localParticipant);
      expect(
        event.localVideoTrack.name,
        ModelInstances.localVideoTrackModel.name,
      );
    });
  });
}
