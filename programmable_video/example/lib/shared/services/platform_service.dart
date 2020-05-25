import 'dart:io';

import 'package:device_info/device_info.dart';

class PlatformService {
  static Future<String> get deviceId async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return androidInfo.androidId;
    }
    return null;
  }
}
