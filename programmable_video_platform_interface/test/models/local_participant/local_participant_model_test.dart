import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../model_instances.dart';

void main() {
  final publicationSid = 'sid';

  final localAudioTrack = ModelInstances.localAudioTrackModel;
  final localDataTrack = ModelInstances.localDataTrackModel;
  final localVideoTrack = ModelInstances.localVideoTrackModel;

  final localAudioTrackPublicationMap = {
    'localAudioTrack': {
      'name': localAudioTrack.name,
      'enabled': localAudioTrack.enabled,
    },
    'sid': publicationSid
  };

  final localDataTrackPublicationMap = {
    'localDataTrack': {
      'name': localDataTrack.name,
      'enabled': localDataTrack.enabled,
      'maxRetransmits': localDataTrack.maxRetransmits,
      'maxPacketLifeTime': localDataTrack.maxPacketLifeTime,
      'reliable': localDataTrack.reliable,
      'ordered': localDataTrack.ordered,
    },
    'sid': publicationSid
  };

  final localVideoTrackPublicationMap = {
    'localVideoTrack': {
      'name': localVideoTrack.name,
      'enabled': localVideoTrack.enabled,
      'videoCapturer': {
        'cameraSource': EnumToString.parse(localVideoTrack.cameraCapturer.source),
        'type': localVideoTrack.cameraCapturer.type,
      }
    },
    'sid': publicationSid
  };

  final identity = 'identity';
  final sid = 'sid';
  final signalingRegion = 'signalingRegion';

  final networkQualityLevel = NetworkQualityLevel.NETWORK_QUALITY_LEVEL_ONE;

  group('LocalParticipantModel()', () {
    test('should not construct without identity', () {
      expect(
        () => LocalParticipantModel(
          identity: null,
          sid: sid,
          signalingRegion: signalingRegion,
          networkQualityLevel: networkQualityLevel,
          localAudioTrackPublications: [ModelInstances.localAudioTrackPublicationModel],
          localDataTrackPublications: [ModelInstances.localDataTrackPublicationModel],
          localVideoTrackPublications: [ModelInstances.localVideoTrackPublicationModel],
        ),
        throwsAssertionError,
      );
    });

    test('should not construct without sid', () {
      expect(
        () => LocalParticipantModel(
          identity: identity,
          sid: null,
          signalingRegion: signalingRegion,
          networkQualityLevel: networkQualityLevel,
          localAudioTrackPublications: [ModelInstances.localAudioTrackPublicationModel],
          localDataTrackPublications: [ModelInstances.localDataTrackPublicationModel],
          localVideoTrackPublications: [ModelInstances.localVideoTrackPublicationModel],
        ),
        throwsAssertionError,
      );
    });

    test('should not construct without sid', () {
      expect(
        () => LocalParticipantModel(
          identity: identity,
          sid: sid,
          signalingRegion: null,
          networkQualityLevel: networkQualityLevel,
          localAudioTrackPublications: [ModelInstances.localAudioTrackPublicationModel],
          localDataTrackPublications: [ModelInstances.localDataTrackPublicationModel],
          localVideoTrackPublications: [ModelInstances.localVideoTrackPublicationModel],
        ),
        throwsAssertionError,
      );
    });

    test('should not construct without sid', () {
      expect(
        () => LocalParticipantModel(
          identity: identity,
          sid: sid,
          signalingRegion: signalingRegion,
          networkQualityLevel: null,
          localAudioTrackPublications: [ModelInstances.localAudioTrackPublicationModel],
          localDataTrackPublications: [ModelInstances.localDataTrackPublicationModel],
          localVideoTrackPublications: [ModelInstances.localVideoTrackPublicationModel],
        ),
        throwsAssertionError,
      );
    });

    test('should not construct without localAudioTrackPublications', () {
      expect(
        () => LocalParticipantModel(
          identity: identity,
          sid: sid,
          signalingRegion: signalingRegion,
          networkQualityLevel: networkQualityLevel,
          localAudioTrackPublications: null,
          localDataTrackPublications: [ModelInstances.localDataTrackPublicationModel],
          localVideoTrackPublications: [ModelInstances.localVideoTrackPublicationModel],
        ),
        throwsAssertionError,
      );
    });

    test('should not construct without localDataTrackPublications', () {
      expect(
        () => LocalParticipantModel(
          identity: identity,
          sid: sid,
          signalingRegion: signalingRegion,
          networkQualityLevel: networkQualityLevel,
          localAudioTrackPublications: [ModelInstances.localAudioTrackPublicationModel],
          localDataTrackPublications: null,
          localVideoTrackPublications: [ModelInstances.localVideoTrackPublicationModel],
        ),
        throwsAssertionError,
      );
    });

    test('should not construct without localVideoTrackPublications', () {
      expect(
        () => LocalParticipantModel(
          identity: identity,
          sid: sid,
          signalingRegion: signalingRegion,
          networkQualityLevel: networkQualityLevel,
          localAudioTrackPublications: [ModelInstances.localAudioTrackPublicationModel],
          localDataTrackPublications: [ModelInstances.localDataTrackPublicationModel],
          localVideoTrackPublications: null,
        ),
        throwsAssertionError,
      );
    });
  });

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'identity': identity,
        'sid': sid,
        'signalingRegion': signalingRegion,
        'networkQualityLevel': EnumToString.parse(networkQualityLevel),
        'localAudioTrackPublications': [localAudioTrackPublicationMap],
        'localDataTrackPublications': [localDataTrackPublicationMap],
        'localVideoTrackPublications': [localVideoTrackPublicationMap]
      };
      final model = LocalParticipantModel.fromEventChannelMap(map);
      expect(model.identity, identity);
      expect(model.sid, sid);
      expect(model.signalingRegion, signalingRegion);
      expect(model.networkQualityLevel, networkQualityLevel);

      expect(model.localAudioTrackPublications, isA<List<LocalAudioTrackPublicationModel>>());
      expect(model.localDataTrackPublications, isA<List<LocalDataTrackPublicationModel>>());
      expect(model.localVideoTrackPublications, isA<List<LocalVideoTrackPublicationModel>>());

      expect(model.localAudioTrackPublications[0].sid, publicationSid);
      expect(model.localAudioTrackPublications[0].localAudioTrack.enabled, localAudioTrack.enabled);
      expect(model.localAudioTrackPublications[0].localAudioTrack.name, localAudioTrack.name);

      expect(model.localDataTrackPublications[0].sid, publicationSid);
      expect(model.localDataTrackPublications[0].localDataTrack.enabled, localDataTrack.enabled);
      expect(model.localDataTrackPublications[0].localDataTrack.name, localDataTrack.name);
      expect(model.localDataTrackPublications[0].localDataTrack.ordered, localDataTrack.ordered);
      expect(model.localDataTrackPublications[0].localDataTrack.reliable, localDataTrack.reliable);
      expect(model.localDataTrackPublications[0].localDataTrack.maxRetransmits, localDataTrack.maxRetransmits);
      expect(model.localDataTrackPublications[0].localDataTrack.maxPacketLifeTime, localDataTrack.maxPacketLifeTime);

      expect(model.localVideoTrackPublications[0].sid, publicationSid);
      expect(model.localVideoTrackPublications[0].localVideoTrack.enabled, localVideoTrack.enabled);
      expect(model.localVideoTrackPublications[0].localVideoTrack.name, localVideoTrack.name);
      expect(model.localVideoTrackPublications[0].localVideoTrack.cameraCapturer.isScreencast, localVideoTrack.cameraCapturer.isScreencast);
      expect(model.localVideoTrackPublications[0].localVideoTrack.cameraCapturer.source, localVideoTrack.cameraCapturer.source);
    });

    test('should not construct from incorrect Map', () {
      final map = {'identity': null};
      expect(() => LocalParticipantModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = LocalParticipantModel(
        identity: identity,
        sid: sid,
        signalingRegion: signalingRegion,
        networkQualityLevel: networkQualityLevel,
        localAudioTrackPublications: [ModelInstances.localAudioTrackPublicationModel],
        localDataTrackPublications: [ModelInstances.localDataTrackPublicationModel],
        localVideoTrackPublications: [ModelInstances.localVideoTrackPublicationModel],
      );
      expect(model.toString(), '''{ 
      identity: $identity,
      sid: $sid,
      signalingRegion: $signalingRegion,
      localAudioTrackPublications: [ ${ModelInstances.localAudioTrackPublicationModel.toString()}, ],
      localDataTrackPublications: [ ${ModelInstances.localDataTrackPublicationModel.toString()}, ],
      localVideoTrackPublications: [ ${ModelInstances.localVideoTrackPublicationModel.toString()}, ],
      networkQualityLevel: $networkQualityLevel
      }''');
    });
  });
}
