part of twilio_unofficial_programmable_video;

/// A local video track publication represents a [LocalVideoTrack] that has been shared to a [Room].
class LocalVideoTrackPublication implements VideoTrackPublication {
  final String _sid;

  LocalVideoTrack _localVideoTrack;

  /// The SID of the local video track.
  @override
  String get trackSid {
    return _sid;
  }

  /// The name of the local video track.
  @override
  String get trackName {
    return _localVideoTrack.name;
  }

  /// Returns `true` if the published video track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled {
    return _localVideoTrack.isEnabled;
  }

  /// The local video track.
  LocalVideoTrack get localVideoTrack {
    return _localVideoTrack;
  }

  /// The base video track of the published local video track.
  @override
  VideoTrack get videoTrack {
    return _localVideoTrack;
  }

  LocalVideoTrackPublication(this._sid) : assert(_sid != null);

  /// Construct from a map.
  factory LocalVideoTrackPublication._fromMap(Map<String, dynamic> map) {
    var localVideoTrackPublication = LocalVideoTrackPublication(map['sid']);
    localVideoTrackPublication._updateFromMap(map);
    return localVideoTrackPublication;
  }

  /// Update properties from a map.
  void _updateFromMap(Map<String, dynamic> map) {
    if (map['localVideoTrack'] != null) {
      final localVideoTrackMap = Map<String, dynamic>.from(map['localVideoTrack']);
      if (_localVideoTrack == null) {
        _localVideoTrack = LocalVideoTrack._fromMap(localVideoTrackMap);
      } else {
        _localVideoTrack._updateFromMap(localVideoTrackMap);
      }
    }
  }
}
