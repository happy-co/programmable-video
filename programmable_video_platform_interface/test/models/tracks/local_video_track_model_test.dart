import 'package:flutter_test/flutter_test.dart';
import 'package:enum_to_string/enum_to_string.dart';

import 'package:twilio_programmable_video_platform_interface/src/enums/camera_source.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final name = 'name';
  final enabled = true;
  final cameraSource = CameraSource.FRONT_CAMERA;
  final type = 'CameraCapturer';

  group('LocalVideoTrackModel', () {
    test('should not construct without name', () {
      expect(
          () => LocalVideoTrackModel(
                name: null,
                enabled: enabled,
                cameraCapturer: CameraCapturerModel(cameraSource, type),
              ),
          throwsAssertionError);
    });
    test('should not construct without enabled', () {
      expect(
          () => LocalVideoTrackModel(
                name: name,
                enabled: null,
                cameraCapturer: CameraCapturerModel(cameraSource, type),
              ),
          throwsAssertionError);
    });
    test('should not construct without cameraCapturer', () {
      expect(
          () => LocalVideoTrackModel(
                name: name,
                enabled: enabled,
                cameraCapturer: null,
              ),
          throwsAssertionError);
    });
  });

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'name': name,
        'enabled': enabled,
        'videoCapturer': {'cameraSource': EnumToString.parse(cameraSource), 'type': type}
      };
      final model = LocalVideoTrackModel.fromEventChannelMap(map);
      expect(model.name, name);
      expect(model.enabled, enabled);
      expect(model.cameraCapturer.source, cameraSource);
      expect(model.cameraCapturer.type, type);
    });

    test('should not construct from incorrect Map', () {
      final map = {'name': null, 'enabled': null, 'videoCapturer': null};
      expect(() => LocalVideoTrackModel.fromEventChannelMap(map), throwsAssertionError);
    });
  });

  group('.toString()', () {
    test('should return correct String', () {
      final model = LocalVideoTrackModel(
        name: name,
        enabled: enabled,
        cameraCapturer: CameraCapturerModel(cameraSource, type),
      );
      expect(
        model.toString(),
        '{ name: $name, enabled: $enabled, cameraCapturer: { source: $cameraSource, type: $type, isScreencast: false } }',
      );
    });
  });

  group('.toMap()', () {
    test('should return correct Map', () {
      final cameraCapturer = CameraCapturerModel(cameraSource, type);
      final model = LocalVideoTrackModel(
        name: name,
        enabled: enabled,
        cameraCapturer: cameraCapturer,
      );
      expect(model.toMap(), {
        'enable': enabled,
        'name': name,
        'videoCapturer': {
          'cameraSource': EnumToString.parse(cameraCapturer.source),
          'type': cameraCapturer.type,
        },
      });
    });
  });
}
