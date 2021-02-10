import 'package:flutter_test/flutter_test.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final modelName = 'name';
  final modelBool = true;

  group('LocalAudioTrackModel()', () {
    test('should not construct without name', () {
      expect(
          () => LocalAudioTrackModel(
                name: null,
                enabled: modelBool,
              ),
          throwsAssertionError);
    });

    test('should not construct without enabled', () {
      expect(
          () => LocalAudioTrackModel(
                name: modelName,
                enabled: null,
              ),
          throwsAssertionError);
    });
  });

  group('.toMap()', () {
    test('should return correct Map', () {
      final model = LocalAudioTrackModel(
        name: modelName,
        enabled: modelBool,
      );
      expect(model.toMap(), {'enable': modelBool, 'name': modelName});
    });
  });

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {'name': modelName, 'enabled': modelBool};
      final model = LocalAudioTrackModel.fromEventChannelMap(map);
      expect(model.name, modelName);
      expect(model.enabled, modelBool);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = LocalAudioTrackModel(name: modelName, enabled: modelBool);
      expect(model.toString(), '{ name: $modelName, enabled: $modelBool }');
    });
  });
}
