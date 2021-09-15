@JS()
library remote_data_track;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.RemoteDataTrack')
class RemoteDataTrack extends Track {
  external bool get isEnabled;
  external bool get isSubscribed;
  external bool get isSwitchedOff;
  external int get maxPacketLifeTime;
  external int get maxRetransmits;
  external bool get ordered;
  external dynamic get priority;
  external bool get reliable;
  external String get sid;

  external factory RemoteDataTrack(
    dynamic sid,
    dynamic mediaTrackReceiver,
    dynamic isEnabled,
    dynamic isSwitchedOff,
    dynamic setPriority,
    dynamic options,
  );
}

extension Interop on RemoteDataTrack {
  RemoteDataTrackModel toModel() {
    return RemoteDataTrackModel(
      name: name,
      enabled: isEnabled,
      sid: sid,
      ordered: ordered,
      reliable: reliable,
      maxPacketLifeTime: maxPacketLifeTime,
      maxRetransmits: maxRetransmits,
    );
  }
}
