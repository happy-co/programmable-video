part of twilio_programmable_video;

/// The [CameraCapturer] is used to provide video frames for a [LocalVideoTrack] from a given [CameraSource].
class CameraCapturer implements VideoCapturer {
  /// Instance for the singleton behaviour.
  static CameraCapturer _cameraCapturer;

  /// Stream for native camera events
  StreamSubscription<BaseCameraEvent> _cameraStream;

  final StreamController<CameraSwitchedEvent> _onCameraSwitched = StreamController<CameraSwitchedEvent>.broadcast();

  /// Called when the camera has switched
  Stream<CameraSwitchedEvent> onCameraSwitched;

  final StreamController<FirstFrameAvailableEvent> _onFirstFrameAvailable = StreamController<FirstFrameAvailableEvent>.broadcast();

  /// Called when the first frame is available from the camera
  Stream<FirstFrameAvailableEvent> onFirstFrameAvailable;

  final StreamController<CameraErrorEvent> _onCameraError = StreamController<CameraErrorEvent>.broadcast();

  /// Called when the camera has thrown an error
  Stream<CameraErrorEvent> onCameraError;

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
    _cameraCapturer ??= CameraCapturer._internal();
    _cameraCapturer._cameraSource = cameraSource;
    _cameraCapturer._cameraStream ??= ProgrammableVideoPlatform.instance.cameraStream().listen(_cameraCapturer._parseCameraEvents);
    _cameraCapturer.onCameraSwitched ??= _cameraCapturer._onCameraSwitched.stream;
    _cameraCapturer.onFirstFrameAvailable ??= _cameraCapturer._onFirstFrameAvailable.stream;
    _cameraCapturer.onCameraError ??= _cameraCapturer._onCameraError.stream;
    return _cameraCapturer;
  }

  /// Construct from a [CameraCapturerModel].
  factory CameraCapturer._fromModel(CameraCapturerModel model) {
    var cameraCapturer = CameraCapturer(model.source);
    cameraCapturer._updateFromModel(model);
    return cameraCapturer;
  }

  CameraCapturer._internal();

  /// Dispose the LocalParticipant
  @override
  void _dispose() {
    _closeStreams();
    _cameraCapturer = null;
  }

  /// Dispose the event streams.
  Future<void> _closeStreams() async {
    await _cameraStream?.cancel();
    _cameraStream = null;
    await _onFirstFrameAvailable?.close();
    onFirstFrameAvailable = null;
    await _onCameraSwitched?.close();
    onCameraSwitched = null;
    await _onCameraError?.close();
    onCameraError = null;
  }

  /// Switch the current [CameraSource].
  ///
  /// This method can be invoked while capturing frames or not.
  /// Throws a [FormatException] if the result could not be parsed to a [CameraSource].
  /// Throws a [MissingCameraException] if no camera is found for the [CameraSource]
  /// that is not presently in use.
  /// Throws a [NotFoundException] when the [CameraCapturer] was not provided at time of connection.
  Future<void> switchCamera() async {
    try {
      _cameraSource = await ProgrammableVideoPlatform.instance.switchCamera();
    } on PlatformException catch (err) {
      throw TwilioProgrammableVideo._convertException(err);
    }
  }

  /// Get availability of torch on active [CameraSource].
  ///
  /// This method can be invoked while capturing frames or not.
  /// Returns false if there is no active camera.
  Future<bool> hasTorch() async {
    return ProgrammableVideoPlatform.instance.hasTorch();
  }

  /// Set state of torch on active [CameraSource].
  ///
  /// This method can be invoked while capturing frames or not.
  /// Throws [MissingParameterException] if [enabled] is not provided.
  /// Throws an exception if the active [CameraSource] does not have a torch.
  /// Throws a [PlatformException] if the attempt to set torch state fails.
  ///
  /// Torch will be deactivated when camera is switched as it is considered to
  /// be an asset of the camera in use.
  Future<void> setTorch(bool enabled) async {
    try {
      await ProgrammableVideoPlatform.instance.setTorch(enabled);
    } on PlatformException catch (err) {
      throw TwilioProgrammableVideo._convertException(err);
    }
  }

  /// Update properties from a [VideoCapturerModel].
  @override
  void _updateFromModel(VideoCapturerModel model) {
    if (model is CameraCapturerModel) {
      _cameraSource = model.source;
    }
  }

  void _parseCameraEvents(BaseCameraEvent event) {
    TwilioProgrammableVideo._log("Camera => Event '$event'");
    _updateFromModel(event.model);

    if (event is CameraSwitched) {
      _onCameraSwitched.add(CameraSwitchedEvent(this));
    } else if (event is FirstFrameAvailable) {
      _onFirstFrameAvailable.add(FirstFrameAvailableEvent(this));
    } else if (event is CameraError) {
      _onCameraError.add(CameraErrorEvent(this, TwilioException._fromModel(event.exception)));
    }
  }
}
