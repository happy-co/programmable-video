@JS()
library local_track_publication;

import 'package:js/js.dart';
import 'package:programmable_video_web/src/interop/classes/event_emitter.dart';

@JS()
class LocalTrackPublication extends EventEmitter {
  external String get kind;
  external String get trackSid;

  external factory LocalTrackPublication(
    dynamic options,
  );
}
