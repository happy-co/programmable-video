@JS()
library local_data_track;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS()
@anonymous
class LocalDataTrackOptions {
  external factory LocalDataTrackOptions({
    int? maxPacketLifeTime,
    int? maxRetransmits,
    bool ordered,
  });
}

@JS('Twilio.Video.LocalDataTrack')
class LocalDataTrack extends Track {
  external int? get maxPacketLifeTime;
  external int? get maxRetransmits;
  external bool get ordered;
  external bool get reliable;

  external factory LocalDataTrack(
    LocalDataTrackOptions options,
  );
}

extension Interop on LocalDataTrack {
  LocalDataTrackModel toModel(bool enabled) {
    return LocalDataTrackModel(
      name: name,
      maxPacketLifeTime: maxPacketLifeTime ?? -1,
      maxRetransmits: maxRetransmits ?? -1,
      ordered: ordered,
      reliable: reliable,
      enabled: enabled,
    );
  }
}
