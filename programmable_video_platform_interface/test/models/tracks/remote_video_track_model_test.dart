import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final name = 'name';
  final enabled = true;
  final sid = 'sid';
  group('RemoteDataTrackModel()', () {
    test('should not construct without name', () {
      expect(
          () => RemoteVideoTrackModel(
                name: null,
                enabled: enabled,
                sid: sid,
              ),
          throwsAssertionError);
    });

    test('should not construct without enabled', () {
      expect(
          () => RemoteVideoTrackModel(
                name: name,
                enabled: null,
                sid: sid,
              ),
          throwsAssertionError);
    });

    test('should not construct without sid', () {
      expect(
          () => RemoteVideoTrackModel(
                name: name,
                enabled: enabled,
                sid: null,
              ),
          throwsAssertionError);
    });
  });

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'name': name,
        'enabled': enabled,
        'sid': sid,
      };
      final model = RemoteVideoTrackModel.fromEventChannelMap(map);
      expect(model.name, name);
      expect(model.enabled, enabled);
      expect(model.sid, sid);
    });
    test('should not construct from incorrect Map', () {
      final map = {
        'name': null,
        'enabled': null,
        'sid': null,
      };
      expect(() => RemoteVideoTrackModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = RemoteVideoTrackModel(
        name: name,
        enabled: enabled,
        sid: sid,
      );
      expect(
        model.toString(),
        '{ name: $name, enabled: $enabled, sid: $sid }',
      );
    });
  });
}
