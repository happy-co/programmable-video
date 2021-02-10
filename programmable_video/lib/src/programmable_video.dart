part of twilio_programmable_video;

/// Entry point for the Twilio Programmable Video.
class TwilioProgrammableVideo {
  static StreamSubscription _loggingStream;

  static var _dartDebug = false;

  /// Internal logging method for dart.
  static void _log(dynamic msg) {
    if (_dartDebug) {
      print('[   DART   ] $msg');
    }
  }

  static Exception _convertException(PlatformException err) {
    var code = int.tryParse(err.code);
    // If code is an integer, then it is a Twilio ErrorInfo exception.
    if (code != null) {
      return TwilioException(int.parse(err.code), err.message);
    } else if (err.code == 'MISSING_CAMERA') {
      return MissingCameraException(
        code: err.code,
        message: err.message,
        details: err.details,
      );
    } else if (err.code == 'MISSING_PARAMS') {
      return MissingParameterException(
        code: err.code,
        message: err.message,
        details: err.details,
      );
    } else if (err.code == 'INIT_ERROR') {
      return InitializationException(
        code: err.code,
        message: err.message,
        details: err.details,
      );
    } else if (err.code == 'NOT_FOUND') {
      return NotFoundException(
        code: err.code,
        message: err.message,
        details: err.details,
      );
    }
    return err;
  }

  /// Enable debug logging.
  ///
  /// For native logging set [native] to `true` and for dart set [dart] to `true`.
  static Future<void> debug({bool dart = false, bool native = false}) async {
    assert(dart != null);
    assert(native != null);
    _dartDebug = dart;
    await ProgrammableVideoPlatform.instance.setNativeDebug(native);
    if (native && _loggingStream == null) {
      _loggingStream = ProgrammableVideoPlatform.instance.loggingStream().listen((dynamic event) {
        if (native) {
          print('[  NATIVE  ] $event');
        }
      });
    } else if (!native && _loggingStream != null) {
      await _loggingStream.cancel();
      _loggingStream = null;
    }
  }

  /// Set the speaker mode on or off.
  ///
  /// Note: Call this method after the [Room.onConnected] event on iOS. Calling it before will not result in a audio routing change.
  static Future<bool> setSpeakerphoneOn(bool on) async {
    assert(on != null);
    return await ProgrammableVideoPlatform.instance.setSpeakerphoneOn(on);
  }

  /// Check if speaker mode is enabled.
  static Future<bool> getSpeakerphoneOn() async {
    return await ProgrammableVideoPlatform.instance.getSpeakerphoneOn();
  }

  /// Request permission for camera and microphone.
  ///
  /// Uses the PermissionHandler plugin. Returns the granted result.
  static Future<bool> requestPermissionForCameraAndMicrophone() async {
    await [Permission.camera, Permission.microphone].request();
    final micPermission = await Permission.microphone.status;
    final camPermission = await Permission.camera.status;
    _log('Permissions => Microphone: $micPermission, Camera: $camPermission');

    if (micPermission == PermissionStatus.granted && camPermission == PermissionStatus.granted) {
      return true;
    }

    if (micPermission == PermissionStatus.denied || camPermission == PermissionStatus.denied) {
      return requestPermissionForCameraAndMicrophone();
    }

    if (micPermission == PermissionStatus.permanentlyDenied || camPermission == PermissionStatus.permanentlyDenied) {
      _log('Permissions => Opening App Settings');
      await openAppSettings();
    }

    return false;
  }

  /// Connect to a [Room].
  ///
  /// Will request camera and microphone permissions.
  /// Throws [MissingParameterException] if [ConnectOptions] are not provided.
  /// Throws [MissingCameraException] if no camera is found for the specified [CameraSource]
  /// Throws [InitializationException] if an error is caught when attempting to connect.
  static Future<Room> connect(ConnectOptions connectOptions) async {
    assert(connectOptions != null);
    if (await requestPermissionForCameraAndMicrophone()) {
      try {
        final roomId = await ProgrammableVideoPlatform.instance.connectToRoom(connectOptions._toModel());
        return Room(roomId);
      } on PlatformException catch (err) {
        throw TwilioProgrammableVideo._convertException(err);
      }
    }
    throw Exception('Permissions not granted');
  }
}
