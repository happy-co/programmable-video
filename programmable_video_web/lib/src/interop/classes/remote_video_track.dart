@JS()
library remote_video_track;

import 'dart:html';

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/video_track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.RemoteAudioTrack')
class RemoteVideoTrack extends VideoTrack {
  external String get sid;
  external bool get isSwitchedOff;

  external factory RemoteVideoTrack(
    dynamic sid,
    dynamic mediaTrackReceiver,
    dynamic isEnabled,
    dynamic isSwitchedOff,
    dynamic setPriority,
    dynamic options,
  );

  external VideoElement attach();
}

extension Interop on RemoteVideoTrack {
  RemoteVideoTrackModel toModel() {
    return RemoteVideoTrackModel(
      enabled: isEnabled,
      name: name,
      sid: sid,
    );
  }
}
