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
  });

  /// Create [NetworkQualityConfigurationModel] from properties.
  NetworkQualityConfigurationModel _toModel() => NetworkQualityConfigurationModel(local, remote);
}
