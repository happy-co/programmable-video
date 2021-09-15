@JS()
library local_audio_track;

import 'dart:html';
import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/audio_track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.LocalAudioTrack')
class LocalAudioTrack extends AudioTrack {
  external String get id;
  external bool get isStopped;

  external factory LocalAudioTrack(
    dynamic mediaStreamTrack,
    dynamic options,
  );

  external AudioElement attach();
  external LocalAudioTrack disable();
  external LocalAudioTrack enable();
}

extension Interop on LocalAudioTrack {
  LocalAudioTrackModel toModel() {
    return LocalAudioTrackModel(
      enabled: isEnabled,
      name: name,
    );
  }
}
