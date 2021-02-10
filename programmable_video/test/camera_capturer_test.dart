import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'mock_platform_interface.dart';

void main() {
  group('.switchCamera()', () {
    test('should call interface code to enable the track', () async {
      final mockInterface = MockInterface();
      ProgrammableVideoPlatform.instance = mockInterface;
      final cameraCapturer = CameraCapturer(CameraSource.BACK_CAMERA);
      await cameraCapturer.switchCamera();

      expect(mockInterface.switchCameraWasCalled, true);
      expect(cameraCapturer.cameraSource, CameraSource.FRONT_CAMERA);
    });
  });

  group('.hasTorch()', () {
    test('should call interface code to check for presence of torch', () async {
      final mockInterface = MockInterface();
      ProgrammableVideoPlatform.instance = mockInterface;
      final cameraCapturer = CameraCapturer(CameraSource.BACK_CAMERA);
      var hasTorch = await cameraCapturer.hasTorch();

      expect(mockInterface.hasTorchWasCalled, true);
      expect(hasTorch, true);
    });
  });

  group('.setTorch(bool enable)', () {
    test('should call interface code to set torch enable state', () async {
      final mockInterface = MockInterface();
      ProgrammableVideoPlatform.instance = mockInterface;
      final cameraCapturer = CameraCapturer(CameraSource.BACK_CAMERA);
      expect(mockInterface.torchEnabled, false);
      await cameraCapturer.setTorch(true);

      expect(mockInterface.torchEnabled, true);
    });
  });

  group('CameraCapturer()', () {
    test('CameraCapturer should be a singleton', () async {
      final firstInstance = CameraCapturer(CameraSource.BACK_CAMERA);
      expect(firstInstance.cameraSource, CameraSource.BACK_CAMERA);
      final secondInstance = CameraCapturer(CameraSource.FRONT_CAMERA);
      expect(firstInstance.cameraSource, CameraSource.FRONT_CAMERA);

      expect(firstInstance, secondInstance);
    });

    test('should not construct without a `CameraSource`', () async {
      expect(() => CameraCapturer(null), throwsAssertionError);
    });
  });
}
