import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../../model_instances.dart';

void main() {
  final sid = 'sid';
  final localAudioTrack = ModelInstances.localAudioTrackModel;

  group('LocalAudioTrackPublicationModel()', () {
    test('should not construct without sid', () {
      expect(
        () => LocalAudioTrackPublicationModel(sid: null, localAudioTrack: localAudioTrack),
        throwsAssertionError,
      );
    });

    test('should not construct without localAudioTrack', () {
      expect(
        () => LocalAudioTrackPublicationModel(sid: sid, localAudioTrack: null),
        throwsAssertionError,
      );
    });
  });

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'localAudioTrack': {
          'name': localAudioTrack.name,
          'enabled': localAudioTrack.enabled,
        },
        'sid': sid
      };
      final model = LocalAudioTrackPublicationModel.fromEventChannelMap(map);
      expect(model.sid, sid);
      expect(model.localAudioTrack.enabled, localAudioTrack.enabled);
      expect(model.localAudioTrack.name, localAudioTrack.name);
    });

    test('should not construct from incorrect Map', () {
      final map = {'localAudioTrack': null, 'sid': null};
      expect(() => LocalAudioTrackPublicationModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = LocalAudioTrackPublicationModel(
        sid: sid,
        localAudioTrack: localAudioTrack,
      );
      expect(model.toString(), '{ sid: $sid, localAudioTrack: $localAudioTrack }');
    });
  });
}
