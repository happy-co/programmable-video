part of twilio_unofficial_programmable_video;

/// A local audio track publication represents a [LocalAudioTrack] that has been shared to a [Room].
class LocalAudioTrackPublication implements AudioTrackPublication {
  final String _sid;

  LocalAudioTrack _localAudioTrack;

  /// The SID of the local audio track.
  @override
  String get trackSid {
    return _sid;
  }

  /// The name of the local audio track.
  @override
  String get trackName {
    return _localAudioTrack.name;
  }

  /// Returns `true` if the published audio track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled {
    return _localAudioTrack.isEnabled;
  }

  /// The local audio track.
  LocalAudioTrack get localAudioTrack {
    return _localAudioTrack;
  }

  /// The base audio track of the published local audio track.
  @override
  AudioTrack get audioTrack {
    return _localAudioTrack;
  }

  /// Construct from a map.
  LocalAudioTrackPublication(this._sid) : assert(_sid != null);

  /// Construct from a map.
  factory LocalAudioTrackPublication._fromMap(Map<String, dynamic> map) {
    var localAudioTrackPublication = LocalAudioTrackPublication(map['sid']);
    localAudioTrackPublication._updateFromMap(map);
    return localAudioTrackPublication;
  }

  /// Update properties from a map.
  void _updateFromMap(Map<String, dynamic> map) {
    if (map['localAudioTrack'] != null) {
      final localAudioTrackMap = Map<String, dynamic>.from(map['localAudioTrack']);
      if (_localAudioTrack == null) {
        _localAudioTrack = LocalAudioTrack._fromMap(localAudioTrackMap);
      } else {
        _localAudioTrack._updateFromMap(localAudioTrackMap);
      }
    }
  }
}
