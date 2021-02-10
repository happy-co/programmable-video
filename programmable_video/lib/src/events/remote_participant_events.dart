part of twilio_programmable_video;

/// The base event class for [RemoteParticipant] events.
class RemoteParticipantEvent {
  /// The associated remote participant.
  final RemoteParticipant remoteParticipant;

  RemoteParticipantEvent(this.remoteParticipant) : assert(remoteParticipant != null);
}

//#region AUDIO TRACK EVENTS

class RemoteAudioTrackEvent extends RemoteParticipantEvent {
  /// The audio track publication.
  final RemoteAudioTrackPublication remoteAudioTrackPublication;

  RemoteAudioTrackEvent(
    RemoteParticipant remoteParticipant,
    this.remoteAudioTrackPublication,
  )   : assert(remoteAudioTrackPublication != null),
        super(remoteParticipant);
}

class RemoteAudioTrackSubscriptionEvent extends RemoteAudioTrackEvent {
  /// The audio track
  final RemoteAudioTrack _remoteAudioTrack;

  RemoteAudioTrackSubscriptionEvent(
    RemoteParticipant remoteParticipant,
    RemoteAudioTrackPublication remoteAudioTrackPublication,
    this._remoteAudioTrack,
  )   : assert(_remoteAudioTrack != null),
        super(remoteParticipant, remoteAudioTrackPublication);

  RemoteAudioTrack get remoteAudioTrack => _remoteAudioTrack;
}

class RemoteAudioTrackSubscriptionFailedEvent extends RemoteAudioTrackEvent {
  /// Exception that describes the failure.
  final TwilioException exception;

  RemoteAudioTrackSubscriptionFailedEvent(
    RemoteParticipant remoteParticipant,
    RemoteAudioTrackPublication remoteAudioTrackPublication,
    this.exception,
  ) : super(remoteParticipant, remoteAudioTrackPublication);
}
//#endregion

//#region DATA TRACK EVENTS

class RemoteDataTrackEvent extends RemoteParticipantEvent {
  /// The data track publication
  final RemoteDataTrackPublication remoteDataTrackPublication;

  RemoteDataTrackEvent(
    RemoteParticipant remoteParticipant,
    this.remoteDataTrackPublication,
  )   : assert(remoteDataTrackPublication != null),
        super(remoteParticipant);
}

class RemoteDataTrackSubscriptionEvent extends RemoteDataTrackEvent {
  /// The data track this subscription is associated with
  final RemoteDataTrack remoteDataTrack;

  RemoteDataTrackSubscriptionEvent(
    RemoteParticipant remoteParticipant,
    RemoteDataTrackPublication remoteDataTrackPublication,
    this.remoteDataTrack,
  )   : assert(remoteDataTrack != null),
        super(remoteParticipant, remoteDataTrackPublication);
}

class RemoteDataTrackSubscriptionFailedEvent extends RemoteDataTrackEvent {
  /// Exception that describes the failure.
  final TwilioException exception;

  RemoteDataTrackSubscriptionFailedEvent(
    RemoteParticipant remoteParticipant,
    RemoteDataTrackPublication remoteDataTrackPublication,
    this.exception,
  ) : super(remoteParticipant, remoteDataTrackPublication);
}

//#endregion

class RemoteNetworkQualityLevelChangedEvent implements NetworkQualityLevelChangedEvent {
  /// The local participant
  final RemoteParticipant remoteParticipant;

  /// The new [NetworkQualityLevel]
  @override
  final NetworkQualityLevel networkQualityLevel;

  RemoteNetworkQualityLevelChangedEvent(
    this.remoteParticipant,
    this.networkQualityLevel,
  )   : assert(remoteParticipant != null),
        assert(networkQualityLevel != null);
}

//#region VIDEO TRACK EVENTS

class RemoteVideoTrackEvent extends RemoteParticipantEvent {
  /// The video track publication.
  final RemoteVideoTrackPublication remoteVideoTrackPublication;

  RemoteVideoTrackEvent(
    RemoteParticipant remoteParticipant,
    this.remoteVideoTrackPublication,
  )   : assert(remoteVideoTrackPublication != null),
        super(remoteParticipant);
}

class RemoteVideoTrackSubscriptionEvent extends RemoteVideoTrackEvent {
  /// The video track this event is associated with.
  final RemoteVideoTrack remoteVideoTrack;

  RemoteVideoTrackSubscriptionEvent(
    RemoteParticipant remoteParticipant,
    RemoteVideoTrackPublication remoteVideoTrackPublication,
    this.remoteVideoTrack,
  )   : assert(remoteVideoTrack != null),
        super(remoteParticipant, remoteVideoTrackPublication);
}

class RemoteVideoTrackSubscriptionFailedEvent extends RemoteVideoTrackEvent {
  /// Exception that describes the failure.
  final TwilioException exception;

  RemoteVideoTrackSubscriptionFailedEvent(
    RemoteParticipant remoteParticipant,
    RemoteVideoTrackPublication remoteVideoTrackPublication,
    this.exception,
  ) : super(remoteParticipant, remoteVideoTrackPublication);
}

//#endregion
