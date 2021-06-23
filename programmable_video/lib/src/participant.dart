part of twilio_programmable_video;

/// Interface that represents user in a [Room].
abstract class Participant {
  /// The unique identifier of a participant.
  String? get sid;

  /// The identity of a participant.
  String get identity;

  /// Returns the participant's [NetworkQualityLevel].
  ///
  /// This property represents the quality of a Participant's connection in a [Room].
  /// This value may not be immediately available, and, in some cases, it's impossible
  /// to calculate it. In these instances, [networkQualityLevel] will return
  /// [NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN]. Calling this API in a
  /// Peer-to-Peer [Room] will always return [NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN].
  ///
  /// This is part of the Network Quality API and must be enabled by enabling the
  /// [ConnectOptions.enableNetworkQuality] option.
  NetworkQualityLevel? get networkQualityLevel;

  /// The audio track publications of a participant.
  List<AudioTrackPublication> get audioTracks;

  /// The video track publications of a participant.
  List<VideoTrackPublication> get videoTracks;
}
