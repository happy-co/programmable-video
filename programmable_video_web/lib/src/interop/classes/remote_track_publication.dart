@JS()
library remote_track_publication;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/track_publication.dart';

@JS()
class RemoteTrackPublication extends TrackPublication {
  external bool get isSubscribed;
  external bool get isTrackEnabled;
  external String get kind;
  external dynamic get publishPriority;

  /// Track will return either [null] or an instance of: [RemoteAudioTrack], [RemoteDataTrack] or [RemoteVideoTrack].
  external dynamic get track;

  external factory RemoteTrackPublication(
    dynamic options,
  );
}
