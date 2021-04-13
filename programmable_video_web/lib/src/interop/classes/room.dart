@JS()
library room;

import 'package:js/js.dart';
import 'package:programmable_video_web/src/interop/classes/event_emitter.dart';
import 'package:programmable_video_web/src/interop/classes/local_participant.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'package:enum_to_string/enum_to_string.dart';

@JS('Twilio.Video.Room')
class Room extends EventEmitter {
  external String get mediaRegion;
  external String get state;
  external String get sid;
  external dynamic get participants;
  external String get name;
  external LocalParticipant get localParticipant;
  external bool get isRecording;
  external dynamic get dominantSpeaker;

  external factory Room(
    dynamic localParticipant,
    dynamic signaling,
    dynamic options,
  );

  external Room disconnect();
}

extension Interop on Room {
  RoomModel toModel() {
    return RoomModel(
      sid: sid,
      name: name,
      state: EnumToString.fromString<RoomState>(
        RoomState.values,
        state.toUpperCase(),
      ),
      mediaRegion: EnumToString.fromString<Region>(
        Region.values,
        mediaRegion,
      ),
      localParticipant: localParticipant.toModel(),
      remoteParticipants: [],
    );
  }
}
