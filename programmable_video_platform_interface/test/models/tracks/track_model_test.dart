import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  var name = 'track';
  var enabled = true;

  group('.toString()', () {
    test('should return correct String', () {
      final model = ExtendsTrackModel(name, enabled);
      expect(model.toString(), '{ name: $name, enabled: $enabled }');
    });
  });

  group('.toMap()', () {
    test('should return correct Map', () {
      final model = ExtendsTrackModel(name, enabled);
      expect(model.toMap(), {'enable': enabled, 'name': name});
    });
  });
}

class ExtendsTrackModel extends TrackModel {
  ExtendsTrackModel(String name, bool enabled) : super(enabled: enabled, name: name);
}
