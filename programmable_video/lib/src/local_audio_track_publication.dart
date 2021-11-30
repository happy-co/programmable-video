part of twilio_programmable_video;

/// A local audio track publication represents a [LocalAudioTrack] that has been shared to a [Room].
class LocalAudioTrackPublication implements AudioTrackPublication {
  final String _sid;

  LocalAudioTrack? _localAudioTrack;

  /// The SID of the local audio track.
  @override
  String get trackSid => _sid;

  /// The name of the local audio track.
  @override
  String get trackName => _localAudioTrack?.name ?? '';

  /// Returns `true` if the published audio track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled => _localAudioTrack?.isEnabled ?? false;

  /// The local audio track.
  LocalAudioTrack? get localAudioTrack => _localAudioTrack;

  /// The base audio track of the published local audio track.
  @override
  AudioTrack? get audioTrack => _localAudioTrack;

  LocalAudioTrackPublication(this._sid);

  /// Construct from a [LocalAudioTrackPublicationModel].
  factory LocalAudioTrackPublication._fromModel(LocalAudioTrackPublicationModel model) {
    var localAudioTrackPublication = LocalAudioTrackPublication(model.sid);
    localAudioTrackPublication._updateFromModel(model);
    return localAudioTrackPublication;
  }

  /// Update properties from a [LocalAudioTrackPublicationModel].
  void _updateFromModel(LocalAudioTrackPublicationModel model) {
    if (_localAudioTrack == null) {
      _localAudioTrack = LocalAudioTrack._fromModel(model.localAudioTrack);
    } else {
      _localAudioTrack!._updateFromModel(model.localAudioTrack);
    }
  }
}
