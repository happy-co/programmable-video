part of twilio_unofficial_programmable_video;

/// Interface that represents user in a [Room].
abstract class Participant {
  /// The unique identifier of a participant.
  String get sid;

  /// The identity of a participant.
  String get identity;

  /// The audio track publications of a participant.
  List<AudioTrackPublication> get audioTracks;

//  /// The data track publications of a participant.
//  List<DataTrackPublication> get dataTracks;

  /// The video track publications of a participant.
  List<VideoTrackPublication> get videoTracks;
}
