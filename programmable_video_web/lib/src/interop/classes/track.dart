@JS()
library track;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/event_emitter.dart';

@JS()
class Track extends EventEmitter {
  external String get name;
  external String get kind;

  external factory Track(
    dynamic id,
    dynamic kind,
    dynamic options,
  );
}
