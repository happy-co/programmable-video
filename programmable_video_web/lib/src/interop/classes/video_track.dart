@JS()
library video_track;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/track.dart';

@JS('Twilio.Video.AudioTrack')
class VideoTrack extends Track {
  external bool get isStarted;
  external bool get isEnabled;

  external factory VideoTrack(
    dynamic isEnabled,
    dynamic isStarted,
    dynamic options,
  );
}
