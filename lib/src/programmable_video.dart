part of twilio_unofficial_programmable_video;

class TwilioUnofficialProgrammableVideo {
  static const MethodChannel _methodChannel = MethodChannel('twilio_unofficial_programmable_video');

  static const EventChannel _roomChannel = EventChannel('twilio_unofficial_programmable_video/room');

  static const EventChannel _remoteParticipantChannel = EventChannel('twilio_unofficial_programmable_video/remote');

  static const EventChannel _loggingChannel = EventChannel('twilio_unofficial_programmable_video/logging');

  static StreamSubscription _loggingStream;

  static var _dartDebug = false;

  static void _log(String msg) {
    if (_dartDebug) {
      print('[  DART  ] $msg');
    }
  }

  /// Enable debug logging, Either natively or in Dart (or both).
  static Future<void> debug({bool dart = false, bool native = false}) async {
    assert(dart != null);
    assert(native != null);
    _dartDebug = dart;
    await _methodChannel.invokeMethod('debug', {'native': native});
    if (native && _loggingStream == null) {
      _loggingStream = _loggingChannel.receiveBroadcastStream().listen((dynamic event) {
        if (native) {
          print('[ NATIVE ] $event');
        }
      });
    }
  }

  /// Set the speaker mode on or off.
  static Future<bool> setSpeakerphoneOn(bool on) async {
    assert(on != null);
    return await _methodChannel.invokeMethod('setSpeakerphoneOn', {'on': on});
  }

  /// Request permission for camera and microphone.
  ///
  /// Uses the PermissionHandler plugin. Returns the granted result.
  static Future<bool> requestPermissionForCameraAndMicrophone() async {
    final permissions = await PermissionHandler().requestPermissions(<PermissionGroup>[PermissionGroup.microphone, PermissionGroup.camera]);

    var cameraAndMicPermissionGranted = true;
    permissions.forEach((PermissionGroup permissionGroup, PermissionStatus permissionStatus) {
      return cameraAndMicPermissionGranted = cameraAndMicPermissionGranted ? permissionStatus == PermissionStatus.granted : false;
    });

    return cameraAndMicPermissionGranted;
  }

  /// Connect to a [Room].
  ///
  /// Will request camera and microphone permissions.
  static Future<Room> connect(ConnectOptions connectOptions) async {
    assert(connectOptions != null);

    if (await requestPermissionForCameraAndMicrophone()) {
      final roomId = await _methodChannel.invokeMethod('connect', <String, Object>{'connectOptions': connectOptions.toMap()});

      return Room(roomId, _roomChannel, _remoteParticipantChannel);
    }
    throw Exception('Permissions not granted');
  }
}
