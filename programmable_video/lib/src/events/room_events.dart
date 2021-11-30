part of twilio_programmable_video;

class RoomConnectFailureEvent {
  /// The room that failed to be connected to.
  final Room room;

  /// An exception describing why connect failed.
  final TwilioException? exception;

  RoomConnectFailureEvent(
    this.room,
    this.exception,
  );
}

class RoomReconnectingEvent {
  /// The room the [LocalParticipant] is attempting to reconnect to.
  final Room room;

  /// An error explaining why the [LocalParticipant] is reconnecting to a room.
  /// Errors are limited to [TwilioException.signalingConnectionDisconnectedException]
  /// and [TwilioException.mediaConnectionErrorException].
  final TwilioException? exception;

  RoomReconnectingEvent(
    this.room,
    this.exception,
  );
}

class RoomDisconnectedEvent {
  /// The room that was disconnected from.
  final Room room;

  /// An exception if there was a problem that caused the room to be disconnected from.
  /// This value will be null is there were no problems disconnecting from the room.
  final TwilioException? exception;

  RoomDisconnectedEvent(
    this.room,
    this.exception,
  );
}

class RoomParticipantConnectedEvent {
  /// The newly connected participant.
  final Room room;

  /// The room the participant connected to.
  final RemoteParticipant remoteParticipant;

  RoomParticipantConnectedEvent(
    this.room,
    this.remoteParticipant,
  );
}

class RoomParticipantDisconnectedEvent {
  /// The room the participant disconnected from.
  final Room room;

  /// The disconnected participant.
  final RemoteParticipant remoteParticipant;

  RoomParticipantDisconnectedEvent(
    this.room,
    this.remoteParticipant,
  );
}

class DominantSpeakerChangedEvent {
  /// The room in which the dominant speaker changed
  final Room room;

  /// The remote participant with the loudest audio track
  final RemoteParticipant? remoteParticipant;

  DominantSpeakerChangedEvent(
    this.room,
    this.remoteParticipant,
  );
}
