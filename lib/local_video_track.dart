import 'package:flutter/widgets.dart';

enum VideoCapturer { FRONT_CAMERA, BACK_CAMERA }

class LocalVideoTrack {
  final bool _enable;

  final VideoCapturer _videoCapturer;

  LocalVideoTrack(this._enable, this._videoCapturer)
      : assert(_enable != null),
        assert(_videoCapturer != null);

  Widget widget() {
    return const AndroidView(key: ValueKey<String>('??'), viewType: 'twilio_unofficial_programmable_video/views');
  }

  Map<String, Object> toMap() {
    return <String, Object>{'enable': _enable, 'videoCapturer': _videoCapturer.toString().split('.')[1]};
  }
}
