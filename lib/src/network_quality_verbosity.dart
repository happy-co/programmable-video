part of twilio_programmable_video;

enum NetworkQualityVerbosity {
  /// Nothing is reported for the [Participant]. This is not a valid option for the [LocalParticipant].
  NETWORK_QUALITY_VERBOSITY_NONE,

  /// Reports only the [NetworkQualityLevel] for the [Participant].
  NETWORK_QUALITY_VERBOSITY_MINIMAL
}
