import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:twilio_unofficial_programmable_video/src/camera_capturer.dart';
import 'package:twilio_unofficial_programmable_video/src/video_capturer.dart';
import 'package:twilio_unofficial_programmable_video/src/video_track.dart';

class LocalVideoTrack extends VideoTrack {
  bool _enabled;

  Widget _widget;

  final VideoCapturer _videoCapturer;

  /// Check if it is enabled.
  ///
  /// When the value is `false`, blank video frames are sent. When the value is `true`, frames from the [cameraSource] are provided.
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

  factory LocalVideoTrack.fromMap(Map<String, dynamic> map) {
    var videoCapturerMap = Map<String, dynamic>.from(map['videoCapturer'] as Map<dynamic, dynamic>);
    var videoCapturer = videoCapturerMap['type'] == 'CameraCapturer' ? CameraCapturer.fromMap(videoCapturerMap) : throw Exception('Received unknown VideoCapturer');
    var localVideoTrack = LocalVideoTrack(map['enabled'], videoCapturer, name: map['name']);
    localVideoTrack.updateFromMap(map);
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
  Widget widget({bool mirror = true}) {
    return _widget ??= AndroidView(
      viewType: 'twilio_unofficial_programmable_video/views',
      creationParams: <String, dynamic>{'isLocal': true, 'mirror': mirror},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  @override
  void updateFromMap(Map<String, dynamic> map) {
    var videoCapturerMap = Map<String, dynamic>.from(map['videoCapturer'] as Map<dynamic, dynamic>);
    _videoCapturer.updateFromMap(videoCapturerMap);

    return super.updateFromMap(map);
  }

  Map<String, Object> toMap() {
    return <String, Object>{'enable': isEnabled, 'name': name, 'videoCapturer': _videoCapturer.toMap(),};
  }
}
