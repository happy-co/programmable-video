import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a Room.
class RoomModel {
  final String sid;
  final String name;
  final RoomState state;
  final Region mediaRegion;

  final LocalParticipantModel localParticipant;
  final List<RemoteParticipantModel> remoteParticipants;

  const RoomModel({
    @required this.sid,
    @required this.name,
    @required this.state,
    @required this.mediaRegion,
    @required this.localParticipant,
    @required this.remoteParticipants,
  })  : assert(sid != null),
        assert(name != null),
        assert(state != null),
        assert(remoteParticipants != null);

  @override
  String toString() {
    var remoteParticipantsString = '';
    for (var remoteParticipant in remoteParticipants) {
      remoteParticipantsString += remoteParticipant.toString() + ',';
    }

    return '{ sid: $sid, name: $name, state: $state, mediaRegion: $mediaRegion, localParticipant: $localParticipant, remoteParticipants: [ $remoteParticipantsString ] }';
  }
}
