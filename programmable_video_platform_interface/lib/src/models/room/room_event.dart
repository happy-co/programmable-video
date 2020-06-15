import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// The base RoomEvent that all other RoomEvent types must extend.
abstract class BaseRoomEvent {
  final RoomModel roomModel;

  const BaseRoomEvent(this.roomModel);

  @override
  String toString() => 'BaseRoomEvent: { roomModel: $roomModel }';
}

/// Use this event if connecting to a Room failed.
class ConnectFailure extends BaseRoomEvent {
  final TwilioExceptionModel exception;

  const ConnectFailure(
    RoomModel roomModel,
    this.exception,
  ) : super(roomModel);

  @override
  String toString() => 'ConnectFailure: { roomModel: $roomModel, exception: $exception }';
}

/// Use this event when the LocalParticipant is connected to the Room.
class Connected extends BaseRoomEvent {
  const Connected(RoomModel roomModel) : super(roomModel);

  @override
  String toString() => 'Connected: { roomModel: $roomModel }';
}

/// Use this event when the LocalParticipant disconnects from the Room.
class Disconnected extends BaseRoomEvent {
  final TwilioExceptionModel exception;

  const Disconnected(
    RoomModel roomModel,
    this.exception,
  ) : super(roomModel);

  @override
  String toString() => 'Disconnected: { roomModel: $roomModel, exception: $exception }';
}

/// Use this event when a new RemoteParticipant connects to the Room.
class ParticipantConnected extends BaseRoomEvent {
  final RemoteParticipantModel connectedParticipant;

  const ParticipantConnected(
    RoomModel roomModel,
    this.connectedParticipant,
  ) : super(roomModel);

  @override
  String toString() => 'ParticipantConnected: { roomModel: $roomModel, connectedParticipant: $connectedParticipant }';
}

/// Use this event when a RemoteParticipant disconnects from the Room.
class ParticipantDisconnected extends BaseRoomEvent {
  final RemoteParticipantModel disconnectedParticipant;

  const ParticipantDisconnected(
    RoomModel roomModel,
    this.disconnectedParticipant,
  ) : super(roomModel);

  @override
  String toString() => 'ParticipantDisconnected: { roomModel: $roomModel, disconnectedParticipant: $disconnectedParticipant }';
}

/// Use this event when the LocalParticipant reconnects to the Room.
class Reconnected extends BaseRoomEvent {
  const Reconnected(RoomModel roomModel) : super(roomModel);

  @override
  String toString() => 'Reconnected: { roomModel: $roomModel }';
}

/// Use this event when the LocalParticipant is reconnecting to the Room.
class Reconnecting extends BaseRoomEvent {
  final TwilioExceptionModel exception;

  const Reconnecting(
    RoomModel roomModel,
    this.exception,
  ) : super(roomModel);

  @override
  String toString() => 'Reconnecting: { roomModel: $roomModel, exception: $exception }';
}

///Use this event when recording of the LocalParticipant has started.
class RecordingStarted extends BaseRoomEvent {
  const RecordingStarted(RoomModel roomModel) : super(roomModel);

  @override
  String toString() => 'RecordingStarted: { roomModel: $roomModel }';
}

///Use this event when recording of the LocalParticipant has stopped.
class RecordingStopped extends BaseRoomEvent {
  const RecordingStopped(RoomModel roomModel) : super(roomModel);

  @override
  String toString() => 'RecordingStopped: { roomModel: $roomModel }';
}

/// Use this event when a new RemoteParticipant becomes the dominant speaker.
class DominantSpeakerChanged extends BaseRoomEvent {
  final RemoteParticipantModel dominantSpeaker;

  const DominantSpeakerChanged(
    RoomModel roomModel,
    this.dominantSpeaker,
  ) : super(roomModel);

  @override
  String toString() => 'DominantSpeakerChanged: { roomModel: $roomModel, dominantSpeaker: $dominantSpeaker }';
}

/// Use this event if an invalid RoomEvent is received from native code which should be skipped.
class SkipAbleRoomEvent extends BaseRoomEvent {
  const SkipAbleRoomEvent() : super(null);

  @override
  String toString() => 'SkipAbleRoomEvent';
}
