import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:twilio_unofficial_programmable_video/src/video_track.dart';

enum VideoCapturer { FRONT_CAMERA, BACK_CAMERA }

class LocalVideoTrack extends VideoTrack {
  final VideoCapturer _videoCapturer;

  Widget _widget;

  /// Check if it is enabled.
  ///
  /// When the value is false, blank video frames are sent. When this value is true, frames from the [videoCapturer] are provided.
  bool get isEnabled {
    return super.isEnabled;
  }

  /// Retrieve the [VideoCapturer].
  VideoCapturer get videoCapturer {
    return _videoCapturer;
  }

  LocalVideoTrack(_enabled, this._videoCapturer)
      : assert(_videoCapturer != null),
        super(_enabled);

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

  Map<String, Object> toMap() {
    return <String, Object>{'enable': isEnabled, 'videoCapturer': _videoCapturer.toString().split('.')[1]};
  }
}
