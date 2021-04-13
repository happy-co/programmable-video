@JS()
library local_audio_track;

import 'dart:html';
import 'package:js/js.dart';
import 'package:programmable_video_web/src/interop/classes/track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.LocalAudioTrack')
class LocalAudioTrack extends Track {
  external String get id;
  external bool get isEnabled;

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
