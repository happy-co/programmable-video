import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class PlatformService {
  static String? generatedDeviceId;

  static Future<String> get deviceId async {
    var deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      generatedDeviceId ??= Uuid().v1();
    } else if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return androidInfo.androidId;
    }

    return generatedDeviceId!;
  }
}
