part of twilio_programmable_video;

/// Entry point for the Twilio Programmable Video.
class TwilioProgrammableVideo {
  static const MethodChannel _methodChannel = MethodChannel('twilio_programmable_video');

  static const EventChannel _roomChannel = EventChannel('twilio_programmable_video/room');

  static const EventChannel _remoteParticipantChannel = EventChannel('twilio_programmable_video/remote');

  static const EventChannel _localParticipantChannel = EventChannel('twilio_programmable_video/local');

  static const EventChannel _loggingChannel = EventChannel('twilio_programmable_video/logging');

  static const EventChannel _remoteDataTrackChannel = EventChannel('twilio_programmable_video/remote_data_track');

  static StreamSubscription _loggingStream;

  static var _dartDebug = false;

  /// Internal logging method for dart.
  static void _log(dynamic msg) {
    if (_dartDebug) {
      print('[   DART   ] $msg');
    }
  }

  /// Enable debug logging.
  ///
  /// For native logging set [native] to `true` and for dart set [dart] to `true`.
  static Future<void> debug({bool dart = false, bool native = false}) async {
    assert(dart != null);
    assert(native != null);
    _dartDebug = dart;
    await _methodChannel.invokeMethod('debug', {'native': native});
    if (native && _loggingStream == null) {
      _loggingStream = _loggingChannel.receiveBroadcastStream().listen((dynamic event) {
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
    return await _methodChannel.invokeMethod('setSpeakerphoneOn', {'on': on});
  }

  /// Check if speaker mode is enabled.
  static Future<bool> getSpeakerphoneOn() async {
    return _methodChannel.invokeMethod('getSpeakerphoneOn');
  }

  /// Takes a photo from the camera capturer.
  static Future<dynamic> takePhoto(int imageCompression) async {
    return _methodChannel.invokeMethod('takePhoto', {'imageCompressions': imageCompression});
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
  static Future<Room> connect(ConnectOptions connectOptions) async {
    assert(connectOptions != null);

    if (await requestPermissionForCameraAndMicrophone()) {
      final roomId =
          await _methodChannel.invokeMethod('connect', <String, Object>{'connectOptions': connectOptions._toMap()});

      return Room(roomId);
    }
    throw Exception('Permissions not granted');
  }
}
