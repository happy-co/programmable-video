@JS()
library remote_data_track_publication;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_data_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_track_publication.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.RemoteDataTrackPublication')
class RemoteDataTrackPublication extends RemoteTrackPublication {
  @override
  external String get kind;
  @override
  external RemoteDataTrack? get track;

  external factory RemoteDataTrackPublication();
}

extension Interop on RemoteDataTrackPublication {
  RemoteDataTrackPublicationModel toModel() {
    return RemoteDataTrackPublicationModel(
      remoteDataTrack: track?.toModel(),
      subscribed: isSubscribed,
      enabled: isTrackEnabled,
      name: trackName,
      sid: trackSid,
    );
  }
}
