@JS()
library audio_track;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/track.dart';

@JS('Twilio.Video.AudioTrack')
class AudioTrack extends Track {
  external bool get isStarted;
  external bool get isEnabled;

  external factory AudioTrack(
    dynamic isEnabled,
    dynamic isStarted,
    dynamic options,
  );
}
