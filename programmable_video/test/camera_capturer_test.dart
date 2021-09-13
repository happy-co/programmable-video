import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

import 'mock_platform_interface.dart';

void main() {
  group('.switchCamera()', () {
    test('should call interface code to enable the track', () async {
      final mockInterface = MockInterface();
      ProgrammableVideoPlatform.instance = mockInterface;
      final cameraCapturer = CameraCapturer(CameraSource('BACK_CAMERA', false, false, false));
      await cameraCapturer.switchCamera(CameraSource('FRONT_CAMERA', false, false, false));

      expect(mockInterface.switchCameraWasCalled, true);
      expect(cameraCapturer.source?.cameraId, 'FRONT_CAMERA');
    });
  });

  group('.setTorch(bool enable)', () {
    test('should call interface code to set torch enable state', () async {
      final mockInterface = MockInterface();
      ProgrammableVideoPlatform.instance = mockInterface;
      final cameraCapturer = CameraCapturer(CameraSource('BACK_CAMERA', false, false, false));
      expect(mockInterface.torchEnabled, false);
      await cameraCapturer.setTorch(true);

      expect(mockInterface.torchEnabled, true);
    });
  });

  group('CameraCapturer()', () {
    test('CameraCapturer should be a singleton', () async {
      final firstInstance = CameraCapturer(CameraSource('BACK_CAMERA', false, false, false));
      expect(firstInstance.source?.cameraId, 'BACK_CAMERA');
      final secondInstance = CameraCapturer(CameraSource('FRONT_CAMERA', false, false, false));
      expect(firstInstance.source?.cameraId, 'FRONT_CAMERA');

      expect(firstInstance, secondInstance);
    });
  });
}
