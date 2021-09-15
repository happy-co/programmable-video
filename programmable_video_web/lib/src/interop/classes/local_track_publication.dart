@JS()
library local_track_publication;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/track_publication.dart';

@JS()
class LocalTrackPublication extends TrackPublication {
  external String get kind;
  external dynamic get priority;

  /// Track will return either [null] or an instance of: [LocalAudioTrack], [LocalDataTrack] or [LocalVideoTrack].
  external dynamic get track;

  external factory LocalTrackPublication(
    dynamic options,
  );
}
