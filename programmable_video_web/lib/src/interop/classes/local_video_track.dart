@JS()
library local_video_track;

import 'dart:html';
import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/video_track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.LocalVideoTrack')
class LocalVideoTrack extends VideoTrack {
  external String get id;
  external bool get isStopped;

  external factory LocalVideoTrack(
    dynamic mediaStreamTrack,
    dynamic options,
  );
  external VideoElement attach();

  external LocalVideoTrack disable();
  external LocalVideoTrack enable();
}

extension Interop on LocalVideoTrack {
  LocalVideoTrackModel toModel() {
    return LocalVideoTrackModel(
      cameraCapturer: CameraCapturerModel(
        CameraSource('FRONT_CAMERA', true, false, false),
        'CameraCapturer',
      ),
      enabled: isEnabled,
      name: name,
    );
  }
}
