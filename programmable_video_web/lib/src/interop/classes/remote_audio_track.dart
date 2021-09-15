@JS()
library remote_audio_track;

import 'dart:html';

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/audio_track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.RemoteAudioTrack')
class RemoteAudioTrack extends AudioTrack {
  external bool get isSwitchedOff;
  external String get sid;

  external factory RemoteAudioTrack(
    dynamic sid,
    dynamic mediaTrackReceiver,
    dynamic isEnabled,
    dynamic isSwitchedOff,
    dynamic setPriority,
    dynamic options,
  );

  external AudioElement attach();
  external List<dynamic> detach();
}

extension Interop on RemoteAudioTrack {
  RemoteAudioTrackModel toModel() {
    return RemoteAudioTrackModel(
      enabled: isEnabled,
      name: name,
      sid: sid,
    );
  }
}
