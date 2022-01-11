import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final name = 'name';
  final enabled = true;
  final ordered = false;
  final reliable = true;
  final maxPacketLifeTime = 10;
  final maxRetransmits = 11;
  final sid = 'sid';

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'name': name,
        'enabled': enabled,
        'ordered': ordered,
        'reliable': reliable,
        'maxPacketLifeTime': maxPacketLifeTime,
        'maxRetransmits': maxRetransmits,
        'sid': sid,
      };
      final model = RemoteDataTrackModel.fromEventChannelMap(map);
      expect(model.name, name);
      expect(model.enabled, enabled);
      expect(model.ordered, ordered);
      expect(model.reliable, reliable);
      expect(model.maxPacketLifeTime, maxPacketLifeTime);
      expect(model.maxRetransmits, maxRetransmits);
      expect(model.sid, sid);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = RemoteDataTrackModel(
        name: name,
        enabled: enabled,
        maxPacketLifeTime: maxPacketLifeTime,
        maxRetransmits: maxRetransmits,
        ordered: ordered,
        reliable: reliable,
        sid: sid,
      );
      expect(
        model.toString(),
        '{ name: $name, enabled: $enabled, ordered: $ordered, reliable: $reliable, maxPacketLifeTime: $maxPacketLifeTime, maxRetransmits: $maxRetransmits, sid: $sid }',
      );
    });
  });
}
