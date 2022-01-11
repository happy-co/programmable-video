part of twilio_programmable_video;

//#region AUDIO TRACK EVENTS
class LocalAudioTrackPublicationFailedEvent {
  /// The local participant that failed to publish the audio track.
  final LocalParticipant localParticipant;

  /// The local audio track that could not be published.
  final LocalAudioTrack localAudioTrack;

  /// An exception explaining why the local participant failed to publish the local audio track.
  final TwilioException twilioException;

  LocalAudioTrackPublicationFailedEvent(
    this.localParticipant,
    this.localAudioTrack,
    this.twilioException,
  );
}

class LocalAudioTrackPublishedEvent {
  /// The local participant that published the audio track.
  final LocalParticipant localParticipant;

  /// The published local audio track.
  final LocalAudioTrackPublication localAudioTrackPublication;

  LocalAudioTrackPublishedEvent(
    this.localParticipant,
    this.localAudioTrackPublication,
  );
}
//#endregion

//#region DATA TRACK EVENTS
class LocalDataTrackPublicationFailedEvent {
  /// The local participant that failed to publish the data track.
  final LocalParticipant localParticipant;

  /// The local data track that could not be published.
  final LocalDataTrack localDataTrack;

  /// An exception explaining why the local participant failed to publish the local data track.
  final TwilioException twilioException;

  LocalDataTrackPublicationFailedEvent(
    this.localParticipant,
    this.localDataTrack,
    this.twilioException,
  );
}

class LocalDataTrackPublishedEvent {
  /// The local participant that published the data track.
  final LocalParticipant localParticipant;

  /// The published local data track.
  final LocalDataTrackPublication localDataTrackPublication;

  LocalDataTrackPublishedEvent(
    this.localParticipant,
    this.localDataTrackPublication,
  );
}
//#endregion

class LocalNetworkQualityLevelChangedEvent implements NetworkQualityLevelChangedEvent {
  /// The local participant
  final LocalParticipant localParticipant;

  /// The new [NetworkQualityLevel]
  @override
  final NetworkQualityLevel networkQualityLevel;

  LocalNetworkQualityLevelChangedEvent(
    this.localParticipant,
    this.networkQualityLevel,
  );
}

//#region VIDEO TRACK EVENTS
class LocalVideoTrackPublicationFailedEvent {
  /// The local participant that failed to publish the video track.
  final LocalParticipant localParticipant;

  /// The local video track that could not be published.
  final LocalVideoTrack localVideoTrack;

  /// An exception explaining why the local participant failed to publish the local video track.
  final TwilioException twilioException;

  LocalVideoTrackPublicationFailedEvent(
    this.localParticipant,
    this.localVideoTrack,
    this.twilioException,
  );
}

class LocalVideoTrackPublishedEvent {
  /// The local participant that published the video track.
  final LocalParticipant localParticipant;

  /// The published local video track.
  final LocalVideoTrackPublication localVideoTrackPublication;

  LocalVideoTrackPublishedEvent(
    this.localParticipant,
    this.localVideoTrackPublication,
  );
}
//#endregion
