@JS()
library local_data_track_publication;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_data_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_track_publication.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.LocalDataTrackPublication')
class LocalDataTrackPublication extends LocalTrackPublication {
  @override
  external LocalDataTrack get track;
  external bool get isTrackEnabled;

  external factory LocalDataTrackPublication(
    dynamic options,
  );
}

extension Interop on LocalDataTrackPublication {
  LocalDataTrackPublicationModel toModel() {
    return LocalDataTrackPublicationModel(
      localDataTrack: track.toModel(isTrackEnabled),
      sid: trackSid,
    );
  }
}
