import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../../model_instances.dart';

void main() {
  final sid = 'sid';
  final subscribed = false;
  final enabled = false;
  final name = 'name';

  final remoteAudioTrack = ModelInstances.remoteAudioTrackModel;

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'sid': sid,
        'subscribed': subscribed,
        'enabled': enabled,
        'name': name,
        'remoteAudioTrack': {
          'name': remoteAudioTrack.name,
          'enabled': remoteAudioTrack.enabled,
          'sid': remoteAudioTrack.sid,
        },
      };
      final model = RemoteAudioTrackPublicationModel.fromEventChannelMap(map);

      expect(model.sid, sid);
      expect(model.subscribed, enabled);
      expect(model.enabled, enabled);
      expect(model.name, name);

      expect(model.remoteAudioTrack.name, remoteAudioTrack.name);
      expect(model.remoteAudioTrack.enabled, remoteAudioTrack.enabled);
      expect(model.remoteAudioTrack.sid, remoteAudioTrack.sid);
    });

    test('should not construct from incorrect Map', () {
      final map = {
        'sid': null,
        'subscribed': subscribed,
        'enabled': enabled,
        'name': null,
        'remoteAudioTrack': {
          'name': remoteAudioTrack.name,
          'enabled': remoteAudioTrack.enabled,
          'sid': remoteAudioTrack.sid,
        },
      };
      expect(() => RemoteAudioTrackPublicationModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = RemoteAudioTrackPublicationModel(
        sid: sid,
        subscribed: subscribed,
        enabled: enabled,
        name: name,
        remoteAudioTrack: remoteAudioTrack,
      );
      expect(
        model.toString(),
        '{ subscribed: $subscribed, enabled: $enabled, sid: $sid, name: $name, remoteAudioTrack: $remoteAudioTrack }',
      );
    });
  });
}
