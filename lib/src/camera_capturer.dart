part of twilio_unofficial_programmable_video;

/// The [CameraCapturer] is used to provide video frames for a [LocalVideoTrack] from a given [CameraSource].
class CameraCapturer implements VideoCapturer {
  /// Instance for the singleton behaviour.
  static final CameraCapturer _cameraCapturer = CameraCapturer._internal();

  CameraSource _cameraSource;

  /// The current specified camera source.
  CameraSource get cameraSource {
    return _cameraSource;
  }

  /// Indicates that the camera capturer is not a screen cast.
  @override
  bool get isScreenCast {
    return false;
  }

  /// Singleton factory.
  ///
  /// Only one instance is allowed.
  factory CameraCapturer(CameraSource cameraSource) {
    assert(cameraSource != null);
    _cameraCapturer._updateFromMap({'cameraSource': EnumToString.parse(cameraSource)});
    return _cameraCapturer;
  }

  /// Construct from a map.
  factory CameraCapturer._fromMap(Map<String, dynamic> map) {
    var cameraCapturer = CameraCapturer(EnumToString.fromString(CameraSource.values, map['cameraSource']));
    cameraCapturer._updateFromMap(map);
    return cameraCapturer;
  }

  CameraCapturer._internal();

  /// Switch the current [CameraSource].
  ///
  /// This method can be invoked while capturing frames or not.
  Future<void> switchCamera() {
    return const MethodChannel('twilio_unofficial_programmable_video').invokeMethod('CameraCapturer#switchCamera');
  }

  /// Update properties from a map.
  @override
  void _updateFromMap(Map<String, dynamic> map) {
    _cameraSource = EnumToString.fromString(CameraSource.values, map['cameraSource']);
  }

  /// Create map from properties.
  @override
  Map<String, Object> _toMap() {
    return <String, Object>{'cameraSource': EnumToString.parse(_cameraSource), 'type': 'CameraCapturer'};
  }

// TODO(WLFN): Implement event streams.
}
