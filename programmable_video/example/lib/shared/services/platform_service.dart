import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:uuid/uuid.dart';

class PlatformService {
  static String? generatedDeviceId;

  static Future<String> get deviceId async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return androidInfo.androidId;
    }

    generatedDeviceId = Uuid().v1();
    return generatedDeviceId!;
  }
}
