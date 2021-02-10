part of twilio_programmable_video;

/// A published track represents a track that has been shared with a [Room].
abstract class TrackPublication {
  /// The SID of a track.
  ///
  /// This value uniquely identifies the track within the scope of a [Room].
  String get trackSid;

  /// The name of the published track.
  String get trackName;

  /// Returns `true` if the track is enabled or `false` otherwise.
  bool get isTrackEnabled;
}
