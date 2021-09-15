@JS()
library local_audio_track_publication;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_audio_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_track_publication.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.LocalAudioTrackPublication')
class LocalAudioTrackPublication extends LocalTrackPublication {
  @override
  external LocalAudioTrack get track;

  external factory LocalAudioTrackPublication(
    dynamic signaling,
    dynamic track,
    dynamic unpublish,
    dynamic options,
  );
}

extension Interop on LocalAudioTrackPublication {
  LocalAudioTrackPublicationModel toModel() {
    return LocalAudioTrackPublicationModel(
      localAudioTrack: track.toModel(),
      sid: trackSid,
    );
  }
}
