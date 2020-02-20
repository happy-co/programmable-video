part of twilio_unofficial_programmable_video;

/// A local data track publication represents a [LocalDataTrack] that has been shared to a [Room].
class LocalDataTrackPublication implements DataTrackPublication {
  final String _sid;

  LocalDataTrack _localDataTrack;

  /// The base data track of the published local data track.
  @override
  DataTrack get dataTrack => _localDataTrack;

  /// Returns `true` if the published data track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled => _localDataTrack.isEnabled;

  /// The name of the local data track.
  @override
  String get trackName => _localDataTrack.name;

  /// The SID of the local data track.
  @override
  String get trackSid => _sid;

  /// The local data track.
  LocalDataTrack get localDataTrack => _localDataTrack;

  LocalDataTrackPublication(this._sid) : assert(_sid != null);

  /// Construct from a map.
  factory LocalDataTrackPublication._fromMap(Map<String, dynamic> map) {
    var localDataTrackPublication = LocalDataTrackPublication(map['sid']);
    localDataTrackPublication._updateFromMap(map);
    return localDataTrackPublication;
  }

  /// Update properties from a map.
  void _updateFromMap(Map<String, dynamic> map) {
    if (map['localDataTrack'] != null) {
      final localDataTrackMap = Map<String, dynamic>.from(map['localDataTrack']);
      if (_localDataTrack == null) {
        _localDataTrack = LocalDataTrack._fromMap(localDataTrackMap);
      } else {
        _localDataTrack._updateFromMap(localDataTrackMap);
      }
    }
  }
}
