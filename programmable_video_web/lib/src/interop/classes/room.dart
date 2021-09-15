@JS()
library room;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/event_emitter.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/js_map.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_participant.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_participant.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'package:enum_to_string/enum_to_string.dart';

@JS('Twilio.Video.Room')
class Room extends EventEmitter {
  external String get mediaRegion;
  external String get state;
  external String get sid;
  external JSMap<String, RemoteParticipant> get participants;
  external String get name;
  external LocalParticipant get localParticipant;
  external bool get isRecording;
  external RemoteParticipant? get dominantSpeaker;

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
          ) ??
          RoomState.DISCONNECTED,
      mediaRegion: EnumToString.fromString<Region>(
        Region.values,
        mediaRegion,
      ),
      localParticipant: localParticipant.toModel(),
      remoteParticipants: iteratorToList<RemoteParticipantModel, RemoteParticipant>(
        participants.values(),
        (RemoteParticipant value) => value.toModel(),
      ),
    );
  }
}
