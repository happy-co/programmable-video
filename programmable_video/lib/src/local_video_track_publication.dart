part of twilio_programmable_video;

/// A local video track publication represents a [LocalVideoTrack] that has been shared to a [Room].
class LocalVideoTrackPublication implements VideoTrackPublication {
  final String _sid;

  LocalVideoTrack? _localVideoTrack;

  /// The SID of the local video track.
  @override
  String get trackSid => _sid;

  /// The name of the local video track.
  @override
  String get trackName => localVideoTrack.name;

  /// Returns `true` if the published video track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled => localVideoTrack.isEnabled;

  /// The local video track.
  LocalVideoTrack get localVideoTrack => _localVideoTrack!;

  /// The base video track of the published local video track.
  @override
  VideoTrack get videoTrack => localVideoTrack;

  LocalVideoTrackPublication(this._sid);

  /// Construct from a [LocalVideoTrackPublicationModel].
  factory LocalVideoTrackPublication._fromModel(LocalVideoTrackPublicationModel model) {
    var localVideoTrackPublication = LocalVideoTrackPublication(model.sid);
    localVideoTrackPublication._updateFromModel(model);
    return localVideoTrackPublication;
  }

  /// Update properties from a [LocalVideoTrackPublicationModel].
  void _updateFromModel(LocalVideoTrackPublicationModel model) {
    final localVideoTrack = _localVideoTrack;
    if (localVideoTrack == null) {
      _localVideoTrack = LocalVideoTrack._fromModel(model.localVideoTrack);
    } else {
      localVideoTrack._updateFromModel(model.localVideoTrack);
      _localVideoTrack = localVideoTrack;
    }
  }
}
