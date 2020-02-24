part of twilio_programmable_video;

/// A local video track that gets video frames from a specified [VideoCapturer].
class LocalVideoTrack extends VideoTrack {
  Widget _widget;

  final VideoCapturer _videoCapturer;

  /// Check if it is enabled.
  ///
  /// When the value is `false`, blank video frames are sent. When the value is `true`, frames from the [CameraSource] are provided.
  @override
  bool get isEnabled => super._enabled;

  /// Retrieves the [VideoCapturer].
  VideoCapturer get videoCapturer => _videoCapturer;

  LocalVideoTrack(enabled, this._videoCapturer, {String name = ''})
      : assert(_videoCapturer != null),
        super(enabled, name);

  /// Construct from a map.
  factory LocalVideoTrack._fromMap(Map<String, dynamic> map) {
    var videoCapturerMap = Map<String, dynamic>.from(map['videoCapturer'] as Map<dynamic, dynamic>);
    var videoCapturer = videoCapturerMap['type'] == 'CameraCapturer' ? CameraCapturer._fromMap(videoCapturerMap) : throw Exception('Received unknown VideoCapturer');
    var localVideoTrack = LocalVideoTrack(map['enabled'], videoCapturer, name: map['name']);
    localVideoTrack._updateFromMap(map);
    return localVideoTrack;
  }

  /// Set the state of the local video track.
  ///
  /// The results of this operation are signaled to other [Participant]s in the same [Room].
  /// When a video track is disabled, blank frames are sent in place of video frames from a video capturer.
  Future<bool> enable(bool enabled) async {
    _enabled = enabled;
    return const MethodChannel('twilio_programmable_video').invokeMethod('LocalVideoTrack#enable', <String, dynamic>{'name': name, 'enable': enabled});
  }

  /// Returns a native widget.
  ///
  /// By default the widget will be mirrored, to change that set [mirror] to false.
  /// If you provide a [key] make sure it is unique among all [VideoTrack]s otherwise Flutter might send the wrong creation params to the native side.
  Widget widget({bool mirror = true, Key key}) {
    key ??= ValueKey('Twilio_LocalParticipant');

    var creationParams = {
      'isLocal': true,
      'mirror': mirror,
    };

    if (Platform.isAndroid) {
      return _widget ??= AndroidView(
        viewType: 'twilio_programmable_video/views',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int viewId) {
          TwilioProgrammableVideo._log('LocalVideoTrack => View created: $viewId, creationParams: $creationParams');
        },
      );
    }

    if (Platform.isIOS) {
      return _widget ??= UiKitView(
        viewType: 'twilio_programmable_video/views',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int viewId) {
          TwilioProgrammableVideo._log('LocalVideoTrack => View created: $viewId, creationParams: $creationParams');
        },
      );
    }

    throw Exception('No widget implementation found for platform \'${Platform.operatingSystem}\'');
  }

  /// Update properties from a map.
  @override
  void _updateFromMap(Map<String, dynamic> map) {
    var videoCapturerMap = Map<String, dynamic>.from(map['videoCapturer'] as Map<dynamic, dynamic>);
    _videoCapturer._updateFromMap(videoCapturerMap);
    return super._updateFromMap(map);
  }

  /// Create map from properties.
  Map<String, Object> _toMap() {
    return <String, Object>{
      'enable': isEnabled,
      'name': name,
      'videoCapturer': _videoCapturer._toMap(),
    };
  }
}
