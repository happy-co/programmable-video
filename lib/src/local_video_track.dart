part of twilio_unofficial_programmable_video;

/// A local video track that gets video frames from a specified [VideoCapturer].
class LocalVideoTrack extends VideoTrack {
  @override
  bool _enabled;

  Widget _widget;

  final VideoCapturer _videoCapturer;

  /// Check if it is enabled.
  ///
  /// When the value is `false`, blank video frames are sent. When the value is `true`, frames from the [CameraSource] are provided.
  @override
  bool get isEnabled {
    return _enabled;
  }

  /// Retrieves the [VideoCapturer].
  VideoCapturer get videoCapturer {
    return _videoCapturer;
  }

  LocalVideoTrack(this._enabled, this._videoCapturer, {String name = ''})
      : assert(_videoCapturer != null),
        super(_enabled, name);

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
    return const MethodChannel('twilio_unofficial_programmable_video').invokeMethod('LocalVideoTrack#enable', <String, dynamic>{'name': name, 'enable': enabled});
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

    return _widget ??= AndroidView(
      viewType: 'twilio_unofficial_programmable_video/views',
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (int viewId) {
        TwilioUnofficialProgrammableVideo._log('LocalVideoTrack => View created: $viewId, creationParams: ${creationParams}');
      },
    );
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
    return <String, Object>{'enable': isEnabled, 'name': name, 'videoCapturer': _videoCapturer._toMap(),};
  }
}
