part of twilio_programmable_video;

/// A published data track represents an data track that has been shared with a [Room].
abstract class DataTrackPublication extends TrackPublication {
  /// The published data track.
  DataTrack? get dataTrack;
}
