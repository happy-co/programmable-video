import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../model_instances.dart';

void main() {
  final publicationSid = 'sid';
  final publicationSubscribed = false;
  final publicationEnabled = false;
  final publicationName = 'name';

  final remoteAudioTrack = ModelInstances.remoteAudioTrackModel;
  final remoteDataTrack = ModelInstances.remoteDataTrackModel;
  final remoteVideoTrack = ModelInstances.remoteVideoTrackModel;

  final remoteAudioTrackPublicationMap = {
    'sid': publicationSid,
    'subscribed': publicationSubscribed,
    'enabled': publicationEnabled,
    'name': publicationName,
    'remoteAudioTrack': {
      'name': remoteAudioTrack.name,
      'enabled': remoteAudioTrack.enabled,
      'sid': remoteAudioTrack.sid,
    },
  };

  final remoteDataTrackPublicationMap = {
    'sid': publicationSid,
    'subscribed': publicationSubscribed,
    'enabled': publicationEnabled,
    'name': publicationName,
    'remoteDataTrack': {
      'name': remoteDataTrack.name,
      'enabled': remoteDataTrack.enabled,
      'sid': remoteDataTrack.sid,
      'maxRetransmits': remoteDataTrack.maxRetransmits,
      'maxPacketLifeTime': remoteDataTrack.maxPacketLifeTime,
      'reliable': remoteDataTrack.reliable,
      'ordered': remoteDataTrack.ordered,
    }
  };

  final remoteVideoTrackPublicationMap = {
    'sid': publicationSid,
    'subscribed': publicationSubscribed,
    'enabled': publicationEnabled,
    'name': publicationName,
    'remoteVideoTrack': {
      'name': remoteVideoTrack.name,
      'enabled': remoteVideoTrack.enabled,
      'sid': remoteVideoTrack.sid,
    }
  };

  final identity = 'identity';
  final sid = 'sid';
  final networkQualityLevel = NetworkQualityLevel.NETWORK_QUALITY_LEVEL_ONE;

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'identity': identity,
        'sid': sid,
        'remoteAudioTrackPublications': [remoteAudioTrackPublicationMap],
        'remoteDataTrackPublications': [remoteDataTrackPublicationMap],
        'remoteVideoTrackPublications': [remoteVideoTrackPublicationMap],
      };
      final model = RemoteParticipantModel.fromEventChannelMap(map);
      expect(model.identity, identity);
      expect(model.sid, sid);
      expect(model.remoteAudioTrackPublications, isA<List<RemoteAudioTrackPublicationModel>>());
      expect(model.remoteDataTrackPublications, isA<List<RemoteDataTrackPublicationModel>>());
      expect(model.remoteVideoTrackPublications, isA<List<RemoteVideoTrackPublicationModel>>());

      expect(model.remoteAudioTrackPublications[0].enabled, publicationEnabled);
      expect(model.remoteAudioTrackPublications[0].subscribed, publicationSubscribed);
      expect(model.remoteAudioTrackPublications[0].sid, publicationSid);
      expect(model.remoteAudioTrackPublications[0].name, publicationName);
      expect(model.remoteAudioTrackPublications[0].remoteAudioTrack.name, remoteAudioTrack.name);
      expect(model.remoteAudioTrackPublications[0].remoteAudioTrack.sid, remoteAudioTrack.sid);
      expect(model.remoteAudioTrackPublications[0].remoteAudioTrack.enabled, remoteAudioTrack.enabled);

      expect(model.remoteDataTrackPublications[0].enabled, publicationEnabled);
      expect(model.remoteDataTrackPublications[0].subscribed, publicationSubscribed);
      expect(model.remoteDataTrackPublications[0].sid, publicationSid);
      expect(model.remoteDataTrackPublications[0].name, publicationName);
      expect(model.remoteDataTrackPublications[0].remoteDataTrack.enabled, remoteDataTrack.enabled);
      expect(model.remoteDataTrackPublications[0].remoteDataTrack.sid, remoteDataTrack.sid);
      expect(model.remoteDataTrackPublications[0].remoteDataTrack.name, remoteDataTrack.name);
      expect(model.remoteDataTrackPublications[0].remoteDataTrack.maxPacketLifeTime, remoteDataTrack.maxPacketLifeTime);
      expect(model.remoteDataTrackPublications[0].remoteDataTrack.maxRetransmits, remoteDataTrack.maxRetransmits);
      expect(model.remoteDataTrackPublications[0].remoteDataTrack.reliable, remoteDataTrack.reliable);
      expect(model.remoteDataTrackPublications[0].remoteDataTrack.ordered, remoteDataTrack.ordered);

      expect(model.remoteVideoTrackPublications[0].enabled, publicationEnabled);
      expect(model.remoteVideoTrackPublications[0].subscribed, publicationSubscribed);
      expect(model.remoteVideoTrackPublications[0].sid, publicationSid);
      expect(model.remoteVideoTrackPublications[0].name, publicationName);
      expect(model.remoteVideoTrackPublications[0].remoteVideoTrack.sid, remoteVideoTrack.sid);
      expect(model.remoteVideoTrackPublications[0].remoteVideoTrack.name, remoteVideoTrack.name);
      expect(model.remoteVideoTrackPublications[0].remoteVideoTrack.enabled, remoteVideoTrack.enabled);
    });

    test('should not construct from incorrect Map', () {
      final map = {'identity': null, 'sid': null};
      expect(() => RemoteParticipantModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = RemoteParticipantModel(
        identity: identity,
        sid: sid,
        remoteAudioTrackPublications: [ModelInstances.remoteAudioTrackPublicationModel],
        remoteDataTrackPublications: [ModelInstances.remoteDataTrackPublicationModel],
        remoteVideoTrackPublications: [ModelInstances.remoteVideoTrackPublicationModel],
        networkQualityLevel: networkQualityLevel,
      );
      expect(model.toString(), '''{ 
      identity: $identity,
      sid: $sid,
      remoteAudioTrackPublications: [ ${ModelInstances.remoteAudioTrackPublicationModel.toString()}, ],
      remoteDataTrackPublications: [ ${ModelInstances.remoteDataTrackPublicationModel.toString()}, ],
      remoteVideoTrackPublications: [ ${ModelInstances.remoteVideoTrackPublicationModel.toString()}, ],
      networkQualityLevel: $networkQualityLevel
      }''');
    });
  });
}
