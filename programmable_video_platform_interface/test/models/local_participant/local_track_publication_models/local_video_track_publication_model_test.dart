import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../../model_instances.dart';

void main() {
  final sid = 'sid';
  final localVideoTrack = ModelInstances.localVideoTrackModel;

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'localVideoTrack': {
          'name': localVideoTrack.name,
          'enabled': localVideoTrack.enabled,
          'videoCapturer': {
            'source': localVideoTrack.cameraCapturer.source?.toMap(),
            'type': localVideoTrack.cameraCapturer.type,
          }
        },
        'sid': sid
      };
      final model = LocalVideoTrackPublicationModel.fromEventChannelMap(map);
      expect(model.sid, sid);
      expect(model.localVideoTrack.enabled, localVideoTrack.enabled);
      expect(model.localVideoTrack.name, localVideoTrack.name);
      expect(model.localVideoTrack.cameraCapturer.source?.cameraId, localVideoTrack.cameraCapturer.source?.cameraId);
      expect(model.localVideoTrack.cameraCapturer.source?.isFrontFacing, localVideoTrack.cameraCapturer.source?.isBackFacing);
      expect(model.localVideoTrack.cameraCapturer.source?.isBackFacing, localVideoTrack.cameraCapturer.source?.isBackFacing);
      expect(model.localVideoTrack.cameraCapturer.type, localVideoTrack.cameraCapturer.type);
    });

    test('should not construct from incorrect Map', () {
      final map = {'localVideoTrack': null, 'sid': null};
      expect(() => LocalVideoTrackPublicationModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = LocalVideoTrackPublicationModel(
        sid: sid,
        localVideoTrack: localVideoTrack,
      );
      expect(model.toString(), '{ sid: $sid, localVideoTrack: $localVideoTrack }');
    });
  });
}
