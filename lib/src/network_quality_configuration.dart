part of twilio_programmable_video;

class NetworkQualityConfiguration {
  /// The [NetworkQualityVerbosity] for the [LocalParticipant].
  final NetworkQualityVerbosity local;

  /// The [NetworkQualityVerbosity] for the [RemoteParticipant].
  final NetworkQualityVerbosity remote;

  /// Creates a [NetworkQualityConfiguration] object with the provided [NetworkQualityVerbosity] levels.
  NetworkQualityConfiguration({
    this.local = NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_MINIMAL,
    this.remote = NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_NONE,
  })  : assert(local != null && local != NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_NONE),
        assert(remote != null);

  /// Create map from properties.
  Map<String, Object> _toMap() {
    return <String, Object>{
      'local': EnumToString.parse(local),
      'remote': EnumToString.parse(remote),
    };
  }
}
