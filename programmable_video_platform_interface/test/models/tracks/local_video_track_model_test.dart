import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/camera_source.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

void main() {
  final name = 'name';
  final enabled = true;
  final source = CameraSource('FRONT_CAMERA', true, false, true);
  final type = 'CameraCapturer';

  group('.fromEventChannelMap()', () {
    test('should correctly construct from Map', () {
      final map = {
        'name': name,
        'enabled': enabled,
        'videoCapturer': {'source': source.toMap(), 'type': type}
      };
      final model = LocalVideoTrackModel.fromEventChannelMap(map);
      expect(model.name, name);
      expect(model.enabled, enabled);
      expect(model.cameraCapturer.source?.cameraId, source.cameraId);
      expect(model.cameraCapturer.source?.isFrontFacing, source.isFrontFacing);
      expect(model.cameraCapturer.source?.isBackFacing, source.isBackFacing);
      expect(model.cameraCapturer.source?.hasTorch, source.hasTorch);
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
        cameraCapturer: CameraCapturerModel(source, type),
      );
      expect(
        model.toString(),
        '{ name: $name, enabled: $enabled, cameraCapturer: { source: $source, type: $type, isScreencast: false } }',
      );
    });
  });

  group('.toMap()', () {
    test('should return correct Map', () {
      final cameraCapturer = CameraCapturerModel(source, type);
      final model = LocalVideoTrackModel(
        name: name,
        enabled: enabled,
        cameraCapturer: cameraCapturer,
      );
      expect(model.toMap(), {
        'enable': enabled,
        'name': name,
        'videoCapturer': {
          'source': source.toMap(),
          'type': cameraCapturer.type,
        },
      });
    });
  });
}
