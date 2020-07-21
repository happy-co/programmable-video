import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../../model_instances.dart';

void main() {
  final sid = 'sid';
  final subscribed = false;
  final enabled = false;
  final name = 'name';

  final remoteDataTrack = ModelInstances.remoteDataTrackModel;

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'sid': sid,
        'subscribed': subscribed,
        'enabled': enabled,
        'name': name,
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
      final model = RemoteDataTrackPublicationModel.fromEventChannelMap(map);

      expect(model.sid, sid);
      expect(model.subscribed, enabled);
      expect(model.enabled, enabled);
      expect(model.name, name);

      expect(model.remoteDataTrack.name, remoteDataTrack.name);
      expect(model.remoteDataTrack.enabled, remoteDataTrack.enabled);
      expect(model.remoteDataTrack.sid, remoteDataTrack.sid);
      expect(model.remoteDataTrack.maxRetransmits, remoteDataTrack.maxRetransmits);
      expect(model.remoteDataTrack.maxPacketLifeTime, remoteDataTrack.maxPacketLifeTime);
      expect(model.remoteDataTrack.reliable, remoteDataTrack.reliable);
      expect(model.remoteDataTrack.ordered, remoteDataTrack.ordered);
    });

    test('should not construct from incorrect Map', () {
      final map = {
        'sid': null,
        'subscribed': subscribed,
        'enabled': enabled,
        'name': null,
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
      expect(() => RemoteDataTrackPublicationModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = RemoteDataTrackPublicationModel(
        sid: sid,
        subscribed: subscribed,
        enabled: enabled,
        name: name,
        remoteDataTrack: remoteDataTrack,
      );
      expect(
        model.toString(),
        '{ subscribed: $subscribed, enabled: $enabled, sid: $sid, name: $name, remoteDataTrack: $remoteDataTrack }',
      );
    });
  });
}
