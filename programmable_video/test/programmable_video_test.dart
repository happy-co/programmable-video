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

  group('.setAudioSettings() & .getAudioSettings()', () {
    final mockInterface = MockInterface();
    final speakerphoneOn = true;
    final bluetoothOn = true;
    setUpAll(() => ProgrammableVideoPlatform.instance = mockInterface);

    test('should call interface code to enable speakerphone', () async {
      await TwilioProgrammableVideo.setAudioSettings(
        speakerphoneEnabled: speakerphoneOn,
        bluetoothPreferred: bluetoothOn,
      );
      expect(mockInterface.setSpeakerPhoneOnWasCalled, false);
      expect(mockInterface.setAudioSettingsWasCalled, true);
    });

    test('should call interface code to check speaker mode', () async {
      await TwilioProgrammableVideo.setAudioSettings(
        speakerphoneEnabled: false,
        bluetoothPreferred: false,
      );

      final result = await TwilioProgrammableVideo.getAudioSettings();
      expect(mockInterface.getSpeakerPhoneOnWasCalled, false);
      expect(mockInterface.getAudioSettingsWasCalled, true);

      expect(result.speakerphoneEnabled, false);
      expect(result.bluetoothPreferred, false);

      await TwilioProgrammableVideo.setAudioSettings(
        speakerphoneEnabled: true,
        bluetoothPreferred: true,
      );

      final result2 = await TwilioProgrammableVideo.getAudioSettings();
      expect(result2.speakerphoneEnabled, true);
      expect(result2.bluetoothPreferred, true);
    });

    test('should call interface code to disable audio settings', () async {
      await TwilioProgrammableVideo.disableAudioSettings();
      expect(mockInterface.disableAudioSettingsWasCalled, true);
    });
  });

  group('.deviceHasReceiver()', () {
    final mockInterface = MockInterface();
    setUpAll(() => ProgrammableVideoPlatform.instance = mockInterface);

    test('should call interface code to check if device has a receiver', () async {
      final result = await TwilioProgrammableVideo.deviceHasReceiver();
      expect(mockInterface.deviceHasReceiverWasCalled, true);
      expect(result, true);
    });
  });

  group('.getStats()', () {
    final mockInterface = MockInterface();
    setUpAll(() => ProgrammableVideoPlatform.instance = mockInterface);

    test('should call interface code to get Stats', () async {
      final result = await TwilioProgrammableVideo.getStats();
      expect(mockInterface.getStatsWasCalled, true);
      expect(result, []);
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

class MockConnectOptions extends Mock implements ConnectOptions {
  @override
  ConnectOptionsModel toModel() {
    return ConnectOptionsModel('accessToken');
  }
}

class MockConnectOptionsModel extends Mock implements ConnectOptionsModel {}
