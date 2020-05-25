import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/method_channel_programmable_video.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final instance = MethodChannelProgrammableVideo();
  final methodCalls = <MethodCall>[];
  var nativeDebugIsCalled = false;
  setUpAll(() {
    // ignore: missing_return
    MethodChannel('twilio_programmable_video').setMockMethodCallHandler((MethodCall methodCall) async {
      methodCalls.add(methodCall);
      switch (methodCall.method) {
        case 'debug':
          nativeDebugIsCalled = true;
          break;
      }
    });
  });
  tearDown(() async {
    methodCalls.clear();
  });
  group('.debug()', () {
    test('should enable native debug in dart', () async {
      await instance.setNativeDebug(true);
      expect(nativeDebugIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'debug',
          arguments: {'native': true},
        )
      ]);
    });
  });
}
