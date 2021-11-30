part of twilio_programmable_video;

/// Entry point for the Twilio Programmable Video.
class TwilioProgrammableVideo {
  // ignore: cancel_subscriptions
  static StreamSubscription? _loggingStream;

  static final StreamController _onAudioNotification = StreamController.broadcast(onListen: () {
    _audioNotificationStream = ProgrammableVideoPlatform.instance.audioNotificationStream().listen(_parseAudioNotificationEvents);
  }, onCancel: () {
    _audioNotificationStream?.cancel();
  });

  static Stream onAudioNotification = _onAudioNotification.stream;

  static StreamSubscription<BaseAudioNotificationEvent>? _audioNotificationStream;

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
    } else if (err.code == 'ACTIVE_CALL') {
      return ActiveCallException(
        code: err.code,
        message: err.message,
        details: err.details,
      );
    }
    return err;
  }

  /// Parse native audio notification events.
  /// Or at least, issue them to observers.
  static void _parseAudioNotificationEvents(BaseAudioNotificationEvent event) {
    _log("AudioNotificationEvent => Event '$event'");

    if (event is SkippableAudioEvent) {
      return;
    }

    _onAudioNotification.add(event);
  }

  /// Enable debug logging.
  ///
  /// For native logging set [native] to `true` and for dart set [dart] to `true`.
  static Future<void> debug({bool dart = false, bool native = false, bool audio = false}) async {
    _dartDebug = dart;
    await ProgrammableVideoPlatform.instance.setNativeDebug(native, audio);
    if ((native || audio) && _loggingStream == null) {
      _loggingStream = ProgrammableVideoPlatform.instance.loggingStream().listen((dynamic event) {
        if (native || audio) {
          print('[  NATIVE  ] $event');
        }
      });
    } else if (!(native || audio) && _loggingStream != null) {
      await _loggingStream?.cancel();
      _loggingStream = null;
    }
  }

  /// Set the speaker mode on or off.
  ///
  /// Note: Call this method after the [Room.onConnected] event on iOS. Calling it before will not result in a audio routing change.
  @Deprecated('Use setAudioSettings for more reliable audio output management.')
  static Future<bool?> setSpeakerphoneOn(bool on) async {
    return await ProgrammableVideoPlatform.instance.setSpeakerphoneOn(on);
  }

  /// Set audio settings to be applied by the native layer.
  ///
  /// Calling this method will cause the native layer (iOS and Android) to watch
  /// for route changes, and changes in available bluetooth devices, and update routing
  /// based upon the specified settings.
  ///
  /// Bluetooth takes precedence over speaker phone, speaker phone over receiver.
  static Future setAudioSettings({
    required bool speakerphoneEnabled,
    required bool bluetoothPreferred,
  }) async {
    return await ProgrammableVideoPlatform.instance.setAudioSettings(
      speakerphoneEnabled,
      bluetoothPreferred,
    );
  }

  /// Resets audio settings at the native layer. Defaults are:
  /// speakerphoneEnabled = true
  /// bluetoothPreferred = true
  ///
  /// Native layer will stop listening for route changes.
  static Future disableAudioSettings() async {
    return ProgrammableVideoPlatform.instance.disableAudioSettings();
  }

  /// Check if speaker mode is enabled.
  @Deprecated('Use getAudioSettings for more reliable audio output management.')
  static Future<bool?> getSpeakerphoneOn() async {
    return await ProgrammableVideoPlatform.instance.getSpeakerphoneOn();
  }

  static Future<AudioSettings> getAudioSettings() async {
    final result = await ProgrammableVideoPlatform.instance.getAudioSettings();
    final settings = AudioSettings._fromMap(Map<String, dynamic>.from(result));
    return settings;
  }

  /// This check is extraneous to the plugin itself, and its reliability and implementation varies by platform
  /// as follows:
  ///
  /// **Android SDK >=23:** Queries audio output devices and returns true if one is found with type `TYPE_BUILTIN_EARPIECE`
  /// **Android SDK <23:** Returns true since there is officially no method of querying
  ///     available audio devices on earlier SDKs. See: https://github.com/google/oboe/issues/67
  ///
  /// **iOS:**  Since iOS only allows querying of audio output devices that are currently in usage, we:
  ///     1. Set the `AVAudioSession` mode to `voiceChat`, storing the current mode
  ///     2. Query the outputs for the `currentRoute`
  ///     3. Check if any of the outputs are of type `AVAudioSession.Port.builtInReceiver`
  ///     4. Set the `AVAudioSession` mode to whatever it was before 1.
  ///
  /// Given the implementation for iOS, it is recommended to perform this check once at startup
  /// rather than at a later time when you might have an active audio session.
  static Future<bool> deviceHasReceiver() async {
    return await ProgrammableVideoPlatform.instance.deviceHasReceiver();
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
  /// Throws [MissingCameraException] if no camera is found for the specified [CameraSource].
  /// Throws [InitializationException] if an error is caught when attempting to connect.
  /// Throws [ActiveCallException] if it fails to get AudioFocus on Android, or activate its AVAudioSession on iOS.
  static Future<Room> connect(ConnectOptions connectOptions) async {
    if (await requestPermissionForCameraAndMicrophone()) {
      try {
        final roomId = await ProgrammableVideoPlatform.instance.connectToRoom(connectOptions.toModel());
        if (roomId == null) {
          throw Exception('RoomId is null');
        }

        return Room(roomId);
      } on PlatformException catch (err) {
        throw TwilioProgrammableVideo._convertException(err);
      }
    }
    throw Exception('Permissions not granted');
  }

  static Future<List<StatsReport>?> getStats() async {
    final statsMap = await ProgrammableVideoPlatform.instance.getStats();
    if (statsMap == null) {
      return null;
    }

    return statsMap.entries.map((entry) {
      final statReport = StatsReport(entry.key);
      final values = entry.value;
      values['localAudioTrackStats'].forEach((localAudioTrackStat) {
        statReport.addLocalAudioTrackStats(LocalAudioTrackStats(
          localAudioTrackStat['trackSid'],
          localAudioTrackStat['packetsLost'],
          localAudioTrackStat['codec'],
          localAudioTrackStat['ssrc'],
          localAudioTrackStat['timestamp'],
          localAudioTrackStat['bytesSent'],
          localAudioTrackStat['packetsSent'],
          localAudioTrackStat['roundTripTime'],
          localAudioTrackStat['audioLevel'],
          localAudioTrackStat['jitter'],
        ));
      });

      values['remoteAudioTrackStats'].forEach((remoteAudioTrackStat) {
        statReport.addAudioTrackStats(RemoteAudioTrackStats(
          remoteAudioTrackStat['trackSid'],
          remoteAudioTrackStat['packetsLost'],
          remoteAudioTrackStat['codec'],
          remoteAudioTrackStat['ssrc'],
          remoteAudioTrackStat['timestamp'],
          remoteAudioTrackStat['bytesReceived'],
          remoteAudioTrackStat['packetsReceived'],
          remoteAudioTrackStat['audioLevel'],
          remoteAudioTrackStat['jitter'],
        ));
      });

      values['remoteVideoTrackStats'].forEach((remoteVideoTrackStat) {
        statReport.addVideoTrackStats(RemoteVideoTrackStats(
          remoteVideoTrackStat['trackSid'],
          remoteVideoTrackStat['packetsLost'],
          remoteVideoTrackStat['codec'],
          remoteVideoTrackStat['ssrc'],
          remoteVideoTrackStat['timestamp'],
          remoteVideoTrackStat['bytesReceived'],
          remoteVideoTrackStat['packetsReceived'],
          VideoDimensions(
            remoteVideoTrackStat['dimensionsHeight'],
            remoteVideoTrackStat['dimensionsWidth'],
          ),
          remoteVideoTrackStat['frameRate'],
        ));
      });

      values['localVideoTrackStats'].forEach((localVideoTrackStat) {
        statReport.addLocalVideoTrackStats(LocalVideoTrackStats(
          localVideoTrackStat['trackSid'],
          localVideoTrackStat['packetsLost'],
          localVideoTrackStat['codec'],
          localVideoTrackStat['ssrc'],
          localVideoTrackStat['timestamp'],
          localVideoTrackStat['bytesSent'],
          localVideoTrackStat['packetsSent'],
          localVideoTrackStat['roundTripTime'],
          VideoDimensions(
            localVideoTrackStat['captureDimensionsHeight'],
            localVideoTrackStat['captureDimensionsWidth'],
          ),
          VideoDimensions(
            localVideoTrackStat['dimensionsHeight'],
            localVideoTrackStat['dimensionsWidth'],
          ),
          localVideoTrackStat['capturedFrameRate'],
          localVideoTrackStat['frameRate'],
        ));
      });

      return statReport;
    }).toList();
  }
}
