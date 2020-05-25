part of twilio_programmable_video;

/// The [CameraCapturer] is used to provide video frames for a [LocalVideoTrack] from a given [CameraSource].
class CameraCapturer implements VideoCapturer {
  /// Instance for the singleton behaviour.
  static final CameraCapturer _cameraCapturer = CameraCapturer._internal();

  CameraSource _cameraSource;

  /// The current specified camera source.
  CameraSource get cameraSource => _cameraSource;

  /// Indicates that the camera capturer is not a screen cast.
  @override
  bool get isScreenCast => false;

  /// Singleton factory.
  ///
  /// Only one instance is allowed.
  factory CameraCapturer(CameraSource cameraSource) {
    assert(cameraSource != null);
    _cameraCapturer._cameraSource = cameraSource;
    return _cameraCapturer;
  }

  /// Construct from a [CameraCapturerModel].
  factory CameraCapturer._fromModel(CameraCapturerModel model) {
    var cameraCapturer = CameraCapturer(model.source);
    cameraCapturer._updateFromModel(model);
    return cameraCapturer;
  }

  CameraCapturer._internal();

  /// Switch the current [CameraSource].
  ///
  /// This method can be invoked while capturing frames or not.
  Future<void> switchCamera() async {
    _cameraSource = await ProgrammableVideoPlatform.instance.switchCamera();
  }

  /// Update properties from a [VideoCapturerModel].
  @override
  void _updateFromModel(VideoCapturerModel model) {
    if (model is CameraCapturerModel) {
      _cameraSource = model.source;
    }
  }

// TODO(WLFN): Implement event streams.
}
