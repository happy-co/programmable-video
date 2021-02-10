import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:twilio_programmable_video/src/parts.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'mock_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('.debug()', () {
    test('should call interface code to enable native debug', () async {
      final mockInterface = MockInterface();
      final nativeDebugBool = true;
      ProgrammableVideoPlatform.instance = mockInterface;
      await TwilioProgrammableVideo.debug(native: nativeDebugBool, dart: !nativeDebugBool);

      expect(mockInterface.setNativeDebugWasCalled, true);
      expect(mockInterface.nativeDebug, nativeDebugBool);
    });

    test('should call interface code to disable native debug', () async {
      final mockInterface = MockInterface();
      final nativeDebugBool = false;
      ProgrammableVideoPlatform.instance = mockInterface;
      await TwilioProgrammableVideo.debug(native: nativeDebugBool, dart: !nativeDebugBool);

      expect(mockInterface.setNativeDebugWasCalled, true);
      expect(mockInterface.nativeDebug, nativeDebugBool);
    });
  });

  group('.setSpeakerPhoneOn() & .getSpeakerPhoneOn()', () {
    final mockInterface = MockInterface();
    final on = true;
    setUpAll(() => ProgrammableVideoPlatform.instance = mockInterface);

    test('should call interface code to enable speakerphone', () async {
      await TwilioProgrammableVideo.setSpeakerphoneOn(on);
      expect(mockInterface.setSpeakerPhoneOnWasCalled, true);
    });

    test('should call interface code to check speaker mode', () async {
      final result = await TwilioProgrammableVideo.getSpeakerphoneOn();
      expect(mockInterface.getSpeakerPhoneOnWasCalled, true);
      expect(result, on);
    });
  });

  group('.requestPermissionForCameraAndMicrophone()', () {
    test('should request camera and microphone permission', () async {
      var nativeRequestPermissionsIsCalled = false;
      var nativeCheckPermissionStatusIsCalled = false;

      MethodChannel('flutter.baseflow.com/permissions/methods').setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'requestPermissions':
            nativeRequestPermissionsIsCalled = true;
            return {1: 1, 7: 1}; // {camera: granted, microphone: granted}
          case 'checkPermissionStatus':
            nativeCheckPermissionStatusIsCalled = true;
            return 1; // granted
        }
        return null;
      });

      final result = await TwilioProgrammableVideo.requestPermissionForCameraAndMicrophone();

      expect(result, true);
      expect(nativeRequestPermissionsIsCalled, true);
      expect(nativeCheckPermissionStatusIsCalled, true);
    });

    test('should request camera and microphone permission again when denied', () async {
      var nativeRequestPermissionsIsCalled = false;
      var nativeCheckPermissionStatusIsCalled = false;

      MethodChannel('flutter.baseflow.com/permissions/methods').setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'requestPermissions':
            if (nativeRequestPermissionsIsCalled) {
              return {1: 1, 7: 1}; // {camera: granted, microphone: granted}
            }
            nativeRequestPermissionsIsCalled = true;
            return {1: 0, 7: 0}; // {camera: denied, microphone: denied}
          case 'checkPermissionStatus':
            if (nativeCheckPermissionStatusIsCalled) {
              return 1; // granted
            }
            nativeCheckPermissionStatusIsCalled = true;
            return 0; // denied
        }
        return null;
      });

      final result = await TwilioProgrammableVideo.requestPermissionForCameraAndMicrophone();

      expect(result, true);
      expect(nativeRequestPermissionsIsCalled, true);
      expect(nativeCheckPermissionStatusIsCalled, true);
    });

    test('should open app settings when camera and microphone permission are permanently denied', () async {
      var nativeRequestPermissionsIsCalled = false;
      var nativeCheckPermissionStatusIsCalled = false;
      var nativeOpenAppSettingsIsCalled = false;

      MethodChannel('flutter.baseflow.com/permissions/methods').setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'requestPermissions':
            nativeRequestPermissionsIsCalled = true;
            return {1: 4, 7: 4}; // {camera: denied, microphone: denied}
          case 'checkPermissionStatus':
            nativeCheckPermissionStatusIsCalled = true;
            return 4; // denied
          case 'openAppSettings':
            nativeOpenAppSettingsIsCalled = true;
        }
        return null;
      });

      final result = await TwilioProgrammableVideo.requestPermissionForCameraAndMicrophone();

      expect(result, false);
      expect(nativeRequestPermissionsIsCalled, true);
      expect(nativeCheckPermissionStatusIsCalled, true);
      expect(nativeOpenAppSettingsIsCalled, true);
    });
  });

  group('.connect()', () {
    test('should call interface code to connect to room', () async {
      final mockInterface = MockInterface();
      ProgrammableVideoPlatform.instance = mockInterface;

      MethodChannel('flutter.baseflow.com/permissions/methods').setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'requestPermissions':
            return {1: 1, 7: 1}; // {camera: granted, microphone: granted}
          case 'checkPermissionStatus':
            return 1; // granted
        }
        return null;
      });

      await TwilioProgrammableVideo.connect(MockConnectOptions());

      expect(mockInterface.connectToRoomWasCalled, true);
    });
  });
}

class MockConnectOptions extends Mock implements ConnectOptions {}

class MockConnectOptionsModel extends Mock implements ConnectOptionsModel {}
