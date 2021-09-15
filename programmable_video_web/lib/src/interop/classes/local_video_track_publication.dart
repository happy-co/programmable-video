@JS()
library local_video_track_publication;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_video_track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.LocalVideoTrackPublication')
class LocalVideoTrackPublication extends LocalTrackPublication {
  @override
  external LocalVideoTrack get track;

  external factory LocalVideoTrackPublication(
    dynamic signaling,
    dynamic track,
    dynamic unpublish,
    dynamic options,
  );
}

extension Interop on LocalVideoTrackPublication {
  LocalVideoTrackPublicationModel toModel() {
    return LocalVideoTrackPublicationModel(
      localVideoTrack: track.toModel(),
      sid: trackSid,
    );
  }
}
