import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../../model_instances.dart';

void main() {
  final sid = 'sid';
  final subscribed = false;
  final enabled = false;
  final name = 'name';

  final remoteVideoTrack = ModelInstances.remoteVideoTrackModel;

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'sid': sid,
        'subscribed': subscribed,
        'enabled': enabled,
        'name': name,
        'remoteVideoTrack': {
          'name': remoteVideoTrack.name,
          'enabled': remoteVideoTrack.enabled,
          'sid': remoteVideoTrack.sid,
        }
      };
      final model = RemoteVideoTrackPublicationModel.fromEventChannelMap(map);

      expect(model.sid, sid);
      expect(model.subscribed, subscribed);
      expect(model.enabled, enabled);
      expect(model.name, name);

      expect(model.remoteVideoTrack.name, remoteVideoTrack.name);
      expect(model.remoteVideoTrack.enabled, remoteVideoTrack.enabled);
      expect(model.remoteVideoTrack.sid, remoteVideoTrack.sid);
    });

    test('should not construct from incorrect Map', () {
      final map = {
        'sid': null,
        'subscribed': subscribed,
        'enabled': enabled,
        'name': null,
        'remoteVideoTrack': {
          'name': remoteVideoTrack.name,
          'enabled': remoteVideoTrack.enabled,
          'sid': remoteVideoTrack.sid,
        }
      };
      expect(() => RemoteVideoTrackPublicationModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = RemoteVideoTrackPublicationModel(
        sid: sid,
        subscribed: subscribed,
        enabled: enabled,
        name: name,
        remoteVideoTrack: remoteVideoTrack,
      );
      expect(
        model.toString(),
        '{ subscribed: $subscribed, enabled: $enabled, sid: $sid, name: $name, remoteVideoTrack: $remoteVideoTrack }',
      );
    });
  });
}
