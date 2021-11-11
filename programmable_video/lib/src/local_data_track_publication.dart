part of twilio_programmable_video;

/// A local data track publication represents a [LocalDataTrack] that has been shared to a [Room].
class LocalDataTrackPublication implements DataTrackPublication {
  final String _sid;

  LocalDataTrack? _localDataTrack;

  /// The base data track of the published local data track.
  @override
  DataTrack? get dataTrack => _localDataTrack;

  /// Returns `true` if the published data track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled => _localDataTrack?.isEnabled ?? false;

  /// The name of the local data track.
  @override
  String get trackName => _localDataTrack?.name ?? '';

  /// The SID of the local data track.
  @override
  String get trackSid => _sid;

  /// The local data track.
  LocalDataTrack? get localDataTrack => _localDataTrack;

  LocalDataTrackPublication(this._sid);

  /// Construct from a [LocalDataTrackPublicationModel].
  factory LocalDataTrackPublication._fromModel(LocalDataTrackPublicationModel model) {
    var localDataTrackPublication = LocalDataTrackPublication(model.sid);
    localDataTrackPublication._updateFromModel(model);
    return localDataTrackPublication;
  }

  /// Update properties from a [LocalDataTrackPublicationModel].
  void _updateFromModel(LocalDataTrackPublicationModel model) {
    if (_localDataTrack == null) {
      _localDataTrack = LocalDataTrack._fromModel(model.localDataTrack);
    } else {
      _localDataTrack!._updateFromModel(model.localDataTrack);
    }
  }
}
