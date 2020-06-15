import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final name = 'name';
  final enabled = true;
  final ordered = false;
  final reliable = true;
  final maxPacketLifeTime = 10;
  final maxRetransmits = 11;

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'name': name,
        'enabled': enabled,
        'ordered': ordered,
        'reliable': reliable,
        'maxPacketLifeTime': maxPacketLifeTime,
        'maxRetransmits': maxRetransmits,
      };
      final model = LocalDataTrackModel.fromEventChannelMap(map);
      expect(model.name, name);
      expect(model.enabled, enabled);
      expect(model.ordered, ordered);
      expect(model.reliable, reliable);
      expect(model.maxPacketLifeTime, maxPacketLifeTime);
      expect(model.maxRetransmits, maxRetransmits);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = LocalDataTrackModel(
        name: name,
        enabled: enabled,
        maxPacketLifeTime: maxPacketLifeTime,
        maxRetransmits: maxRetransmits,
        ordered: ordered,
        reliable: reliable,
      );
      expect(
        model.toString(),
        '{ name: $name, enabled: $enabled, ordered: $ordered, reliable: $reliable, maxPacketLifeTime: $maxPacketLifeTime, maxRetransmits: $maxRetransmits }',
      );
    });
  });

  group('.toMap()', () {
    test('should return correct Map', () {
      final model = LocalDataTrackModel(
        name: name,
        maxPacketLifeTime: maxPacketLifeTime,
        maxRetransmits: maxRetransmits,
        ordered: ordered,
      );
      expect(model.toMap(), {
        'dataTrackOptions': {
          'ordered': ordered,
          'maxPacketLifeTime': maxPacketLifeTime,
          'maxRetransmits': maxRetransmits,
          'name': name,
        }
      });
    });
  });
}
