@JS()
library track_publication;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/event_emitter.dart';

@JS()
class TrackPublication extends EventEmitter {
  external String get trackName;
  external String get trackSid;

  external factory TrackPublication(
    dynamic trackName,
    dynamic trackSid,
    dynamic options,
  );
}
