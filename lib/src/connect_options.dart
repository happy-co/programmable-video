part of twilio_programmable_video;

/// Represents options when connecting to a [Room].
class ConnectOptions {
  /// This Access Token is the credential you must use to identify and authenticate your request.
  /// More information about Access Tokens can be found here: https://www.twilio.com/docs/video/tutorials/user-identity-access-tokens
  final String accessToken;

  /// The name of the room.
  final String roomName;

  /// The region of the signaling Server the Client will use.
  final Region region;

  /// Enable detection of the loudest audio track
  final bool enableDominantSpeaker;

  /// Set preferred audio codecs.
  final List<AudioCodec> preferredAudioCodecs;

  /// Set preferred video codecs.
  final List<VideoCodec> preferredVideoCodecs;

  /// Audio tracks that will be published upon connection.
  final List<LocalAudioTrack> audioTracks;

  /// Data tracks that will be published upon connection.
  final List<LocalDataTrack> dataTracks;

  /// Video tracks that will be published upon connection.
  final List<LocalVideoTrack> videoTracks;

  ConnectOptions(
    this.accessToken, {
    this.audioTracks,
    this.dataTracks,
    this.preferredAudioCodecs,
    this.preferredVideoCodecs,
    this.region,
    this.roomName,
    this.videoTracks,
    this.enableDominantSpeaker,
  })  : assert(accessToken != null),
        assert(accessToken.isNotEmpty),
        assert((audioTracks != null && audioTracks.isNotEmpty) || audioTracks == null),
        assert((dataTracks != null && dataTracks.isNotEmpty) || dataTracks == null),
        assert((preferredAudioCodecs != null && preferredAudioCodecs.isNotEmpty) || preferredAudioCodecs == null),
        assert((preferredVideoCodecs != null && preferredVideoCodecs.isNotEmpty) || preferredVideoCodecs == null),
        assert((region != null && region is Region) || region == null),
        assert((videoTracks != null && videoTracks.isNotEmpty) || videoTracks == null);

  /// Create map from properties.
  Map<String, Object> _toMap() {
    return {
      'accessToken': accessToken,
      'roomName': roomName,
      'region': EnumToString.parse(region),
      'preferredAudioCodecs': preferredAudioCodecs != null ? Map<String, String>.fromIterable(preferredAudioCodecs.map<String>((AudioCodec a) => a.name)) : null,
      'preferredVideoCodecs': preferredVideoCodecs != null ? Map<String, String>.fromIterable(preferredVideoCodecs.map<String>((VideoCodec v) => v.name)) : null,
      'audioTracks': audioTracks != null ? Map<Object, Object>.fromIterable(audioTracks.map<Map<String, Object>>((LocalAudioTrack a) => a._toMap())) : null,
      'dataTracks': dataTracks != null ? Map<Object, Object>.fromIterable(dataTracks.map<Map<String, Object>>((LocalDataTrack d) => d._toMap())) : null,
      'videoTracks': videoTracks != null ? Map<Object, Object>.fromIterable(videoTracks.map<Map<String, Object>>((LocalVideoTrack v) => v._toMap())) : null,
      'enableDominantSpeaker': enableDominantSpeaker,
    };
  }
}
