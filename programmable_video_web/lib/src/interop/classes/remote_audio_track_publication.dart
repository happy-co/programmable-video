@JS()
library remote_audio_track_publication;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_audio_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_track_publication.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.RemoteAudioTrackPublication')
class RemoteAudioTrackPublication extends RemoteTrackPublication {
  @override
  external String get kind; // "audio"
  @override
  external RemoteAudioTrack? get track;

  external factory RemoteAudioTrackPublication();
}

extension Interop on RemoteAudioTrackPublication {
  RemoteAudioTrackPublicationModel toModel() {
    return RemoteAudioTrackPublicationModel(
      remoteAudioTrack: track?.toModel(),
      subscribed: isSubscribed,
      enabled: isTrackEnabled,
      name: trackName,
      sid: trackSid,
    );
  }
}
