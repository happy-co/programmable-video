part of twilio_unofficial_programmable_video;

/// Represents options when connecting to a [Room].
class ConnectOptions {
  final String _accessToken;

  String _roomName;

  String _region;

  List<AudioCodec> _preferredAudioCodecs;

  List<VideoCodec> _preferredVideoCodecs;

  List<LocalAudioTrack> _audioTracks;

  List<LocalVideoTrack> _videoTracks;

  ConnectOptions(this._accessToken)
      : assert(_accessToken != null),
        assert(_accessToken != '');

  void roomName(String roomName) {
    assert(roomName != null);
    _roomName = roomName;
  }

  void region(String region) {
    assert(region != null);
    _region = region;
  }

  void preferAudioCodecs(List<AudioCodec> preferredAudioCodecs) {
    assert(preferredAudioCodecs != null);
    assert(preferredAudioCodecs.isNotEmpty);
    _preferredAudioCodecs = preferredAudioCodecs;
  }

  void preferVideoCodecs(List<VideoCodec> preferredVideoCodecs) {
    assert(preferredVideoCodecs != null);
    assert(preferredVideoCodecs.isNotEmpty);
    _preferredVideoCodecs = preferredVideoCodecs;
  }

  void audioTracks(List<LocalAudioTrack> audioTracks) {
    assert(audioTracks != null);
    assert(audioTracks.isNotEmpty);
    _audioTracks = audioTracks;
  }

  void videoTracks(List<LocalVideoTrack> videoTracks) {
    assert(videoTracks != null);
    assert(videoTracks.isNotEmpty);
    _videoTracks = videoTracks;
  }

  /// Create map from properties.
  Map<String, Object> _toMap() {
    return {
      'accessToken': _accessToken,
      'roomName': _roomName,
      'region': _region,
      'preferredAudioCodecs': _preferredAudioCodecs != null ? Map<String, String>.fromIterable(_preferredAudioCodecs.map<String>((AudioCodec a) => a.name)) : null,
      'preferredVideoCodecs': _preferredVideoCodecs != null ? Map<String, String>.fromIterable(_preferredVideoCodecs.map<String>((VideoCodec v) => v.name)) : null,
      'audioTracks': _audioTracks != null ? Map<Object, Object>.fromIterable(_audioTracks.map<Map<String, Object>>((LocalAudioTrack a) => a._toMap())) : null,
      'videoTracks': _videoTracks != null ? Map<Object, Object>.fromIterable(_videoTracks.map<Map<String, Object>>((LocalVideoTrack v) => v._toMap())) : null
    };
  }
}
