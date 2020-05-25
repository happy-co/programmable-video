//import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final methodCalls = <MethodCall>[];
  var nativeDebugIsCalled = false;
  var nativeSpeakerphoneOnIsCalled = false;
  var nativeConnectIsCalled = false; // ignore: unused_local_variable

  setUpAll(() {
    // ignore: missing_return
    MethodChannel('twilio_programmable_video').setMockMethodCallHandler((MethodCall methodCall) async {
      methodCalls.add(methodCall);
      switch (methodCall.method) {
        case 'debug':
          nativeDebugIsCalled = true;
          break;
        case 'setSpeakerphoneOn':
          nativeSpeakerphoneOnIsCalled = true;
          break;
        case 'connect':
          nativeConnectIsCalled = true;
          return 1;
      }
    });
  });

  tearDown(() async {
    methodCalls.clear();
  });

  group('.debug()', () {
    test('should enable debug in dart', () async {
      await TwilioProgrammableVideo.debug(dart: true);

      expect(nativeDebugIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'debug',
          arguments: <String, bool>{'native': false},
        )
      ]);
    });

    test('should disable debug in dart', () async {
      await TwilioProgrammableVideo.debug(dart: false);

      expect(nativeDebugIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'debug',
          arguments: <String, bool>{'native': false},
        )
      ]);
    });

// TODO(WLFN): No idea how to mock EventChannels.
//    test('it should enable debug natively', () async {
//      await TwilioProgrammableVideo.debug(native: true);
//
//      expect(nativeDebugIsCalled, true);
//      expect(methodCalls, <Matcher>[
//        isMethodCall(
//          'debug',
//          arguments: <String, bool>{'native': true},
//        )
//      ]);
//    });
  });

  group('.setSpeakerPhoneOn()', () {
    test('should enable the speakerphone', () async {
      await TwilioProgrammableVideo.setSpeakerphoneOn(true);

      expect(nativeSpeakerphoneOnIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'setSpeakerphoneOn',
          arguments: <String, bool>{'on': true},
        )
      ]);
    });

    test('should disable the speakerphone', () async {
      await TwilioProgrammableVideo.setSpeakerphoneOn(false);

      expect(nativeSpeakerphoneOnIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'setSpeakerphoneOn',
          arguments: <String, bool>{'on': false},
        )
      ]);
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

  // TODO(WOLFEN): currently not working.
  // group('.connect()', () {
  //   test('should request camera and microphone permission', () async {
  //     MethodChannel('flutter.baseflow.com/permissions/methods').setMockMethodCallHandler((MethodCall methodCall) async {
  //       switch (methodCall.method) {
  //         case 'requestPermissions':
  //           return {1: 1, 7: 1}; // {camera: granted, microphone: granted}
  //         case 'checkPermissionStatus':
  //           return 1; // granted
  //       }
  //       return null;
  //     });

  //     final accessToken = 'theAccessToken';
  //     final roomName = 'theRoomName';
  //     final region = Region.de1;
  //     await TwilioProgrammableVideo.connect(ConnectOptions(
  //       accessToken,
  //       roomName: roomName,
  //       region: region,
  //     ));

  //     expect(nativeConnectIsCalled, true);
  //     expect(methodCalls, <Matcher>[
  //       isMethodCall(
  //         'connect',
  //         arguments: <String, Object>{
  //           'connectOptions': {
  //             'accessToken': accessToken,
  //             'roomName': roomName,
  //             'region': EnumToString.parse(region),
  //             'preferredAudioCodecs': null,
  //             'preferredVideoCodecs': null,
  //             'audioTracks': null,
  //             'dataTracks': null,
  //             'videoTracks': null,
  //           }
  //         },
  //       )
  //     ]);
  //   });
  // });
}
