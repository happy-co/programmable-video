import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../../model_instances.dart';

void main() {
  final sid = 'sid';
  final localDataTrack = ModelInstances.localDataTrackModel;

  group('LocalDataTrackPublicationModel()', () {
    test('should not construct without sid', () {
      expect(
        () => LocalDataTrackPublicationModel(sid: null, localDataTrack: localDataTrack),
        throwsAssertionError,
      );
    });

    test('should not construct without localDataTrack', () {
      expect(
        () => LocalDataTrackPublicationModel(sid: sid, localDataTrack: null),
        throwsAssertionError,
      );
    });
  });

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'localDataTrack': {
          'name': localDataTrack.name,
          'enabled': localDataTrack.enabled,
          'maxRetransmits': localDataTrack.maxRetransmits,
          'maxPacketLifeTime': localDataTrack.maxPacketLifeTime,
          'reliable': localDataTrack.reliable,
          'ordered': localDataTrack.ordered,
        },
        'sid': sid
      };
      final model = LocalDataTrackPublicationModel.fromEventChannelMap(map);
      expect(model.sid, sid);
      expect(model.localDataTrack.enabled, localDataTrack.enabled);
      expect(model.localDataTrack.name, localDataTrack.name);
      expect(model.localDataTrack.maxRetransmits, localDataTrack.maxRetransmits);
      expect(model.localDataTrack.maxPacketLifeTime, localDataTrack.maxPacketLifeTime);
      expect(model.localDataTrack.reliable, localDataTrack.reliable);
      expect(model.localDataTrack.ordered, localDataTrack.ordered);
    });

    test('should not construct from incorrect Map', () {
      final map = {'localDataTrack': null, 'sid': null};
      expect(() => LocalDataTrackPublicationModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = LocalDataTrackPublicationModel(
        sid: sid,
        localDataTrack: localDataTrack,
      );
      expect(model.toString(), '{ sid: $sid, localDataTrack: $localDataTrack }');
    });
  });
}
