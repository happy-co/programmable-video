import 'dart:async';

import 'package:flutter/services.dart';

class TwilioUnofficialProgrammableVideo {
  static const MethodChannel _channel =
      const MethodChannel('twilio_unofficial_programmable_video');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
