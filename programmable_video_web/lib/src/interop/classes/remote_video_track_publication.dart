@JS()
library remote_video_track_publication;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_video_track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.RemoteVideoTrackPublication')
class RemoteVideoTrackPublication extends RemoteTrackPublication {
  @override
  external String get kind; // "video"
  @override
  external RemoteVideoTrack? get track;

  external factory RemoteVideoTrackPublication();
}

extension Interop on RemoteVideoTrackPublication {
  RemoteVideoTrackPublicationModel toModel() {
    return RemoteVideoTrackPublicationModel(
      remoteVideoTrack: track?.toModel(),
      subscribed: isSubscribed,
      enabled: isTrackEnabled,
      name: trackName,
      sid: trackSid,
    );
  }
}
