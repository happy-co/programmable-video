part of twilio_programmable_video;

/// Represents options when connecting to a [Room].
class ConnectOptions {
  /// This Access Token is the credential you must use to identify and authenticate your request.
  /// More information about Access Tokens can be found here: https://www.twilio.com/docs/video/tutorials/user-identity-access-tokens
  final String accessToken;

  /// The name of the room.
  final String? roomName;

  /// The region of the signaling Server the Client will use.
  final Region? region;

  /// Enable detection of the loudest audio track
  final bool? enableDominantSpeaker;

  /// Set preferred audio codecs.
  final List<AudioCodec>? preferredAudioCodecs;

  /// Set preferred video codecs.
  final List<VideoCodec>? preferredVideoCodecs;

  /// Audio tracks that will be published upon connection.
  final List<LocalAudioTrack>? audioTracks;

  /// Data tracks that will be published upon connection.
  final List<LocalDataTrack>? dataTracks;

  /// Video tracks that will be published upon connection.
  final List<LocalVideoTrack>? videoTracks;

  /// Enable or disable the Network Quality API.
  /// Set this to true to enable the Network Quality API when using Group Rooms.
  /// This option has no effect in Peer-to-Peer Rooms. The default value is false.
  final bool enableNetworkQuality;

  /// Sets the verbosity level for network quality information returned by the
  /// Network Quality API.
  ///
  /// If a [NetworkQualityConfiguration] is not provided, the default
  /// configuration is used: [NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_MINIMAL]
  /// for the [LocalParticipant] and [NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_NONE]
  /// for the [RemoteParticipant]s.
  final NetworkQualityConfiguration? networkQualityConfiguration;

  /// Choosing between `subscribe-to-all` or `subscribe-to-none` subscription rule
  final bool? enableAutomaticSubscription;

  ConnectOptions(
    this.accessToken, {
    this.audioTracks,
    this.dataTracks,
    this.preferredAudioCodecs,
    this.preferredVideoCodecs,
    this.region,
    this.roomName,
    this.videoTracks,
    this.enableNetworkQuality = false,
    this.networkQualityConfiguration,
    this.enableDominantSpeaker,
    this.enableAutomaticSubscription,
  }) : assert(accessToken.isNotEmpty);

  /// Create a [ConnectOptionsModel] from properties.
  ConnectOptionsModel toModel() {
    final audioTracks = this.audioTracks;
    final audioTrackModels = audioTracks == null
        ? null
        : List<LocalAudioTrackModel>.from(
            audioTracks.map<LocalAudioTrackModel>(
              (e) => e._toModel() as LocalAudioTrackModel,
            ),
          );

    final dataTracks = this.dataTracks;
    final dataTrackModels = dataTracks == null
        ? null
        : List<LocalDataTrackModel>.from(
            dataTracks.map<LocalDataTrackModel>(
              (e) => e._toModel(),
            ),
          );

    final videoTracks = this.videoTracks;
    final videoTrackModels = videoTracks == null
        ? null
        : List<LocalVideoTrackModel>.from(
            videoTracks.map<LocalVideoTrackModel>(
              (e) => e._toModel() as LocalVideoTrackModel,
            ),
          );

    return ConnectOptionsModel(
      accessToken,
      audioTracks: audioTrackModels,
      dataTracks: dataTrackModels,
      videoTracks: videoTrackModels,
      enableAutomaticSubscription: enableAutomaticSubscription,
      enableDominantSpeaker: enableDominantSpeaker,
      preferredAudioCodecs: preferredAudioCodecs,
      preferredVideoCodecs: preferredVideoCodecs,
      region: region,
      roomName: roomName,
      enableNetworkQuality: enableNetworkQuality,
      networkQualityConfiguration: networkQualityConfiguration?._toModel(),
    );
  }
}
