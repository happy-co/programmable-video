part of twilio_programmable_video;

/// A remote audio track publication represents a [RemoteAudioTrack] that has been shared to a [Room].
class RemoteAudioTrackPublication implements AudioTrackPublication {
  final String _sid;

  final String _name;

  RemoteAudioTrack? _remoteAudioTrack;

  bool _subscribed;

  bool _enabled;

  /// The SID of the published audio track.
  @override
  String get trackSid => _sid;

  /// The name of the published audio track.
  @override
  String get trackName => _name;

  /// Returns `true` if the published audio track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled => _enabled;

  /// Returns `true` if the published audio track is subscribed by the local participant or `false` otherwise.
  bool get isTrackSubscribed => _subscribed;

  /// Returns the published remote audio track.
  ///
  /// Will return `null` if the track is not subscribed to.
  RemoteAudioTrack? get remoteAudioTrack => _remoteAudioTrack;

  /// The base audio track object of the published remote audio track.
  ///
  /// Will return `null` if the track is not subscribed to.
  @override
  AudioTrack? get audioTrack => _remoteAudioTrack;

  RemoteAudioTrackPublication(
    this._subscribed,
    this._enabled,
    this._sid,
    this._name,
  );

  /// Construct from a [RemoteAudioTrackPublicationModel].
  factory RemoteAudioTrackPublication._fromModel(RemoteAudioTrackPublicationModel model) {
    var remoteAudioTrackPublication = RemoteAudioTrackPublication(model.subscribed, model.enabled, model.sid, model.name);
    remoteAudioTrackPublication._updateFromModel(model);
    return remoteAudioTrackPublication;
  }

  /// Update properties from a [RemoteAudioTrackPublicationModel].
  void _updateFromModel(RemoteAudioTrackPublicationModel model) {
    _subscribed = model.subscribed;
    _enabled = model.enabled;

    final remoteAudioTrack = model.remoteAudioTrack;
    if (remoteAudioTrack != null) {
      _remoteAudioTrack ??= RemoteAudioTrack._fromModel(remoteAudioTrack);
      _remoteAudioTrack!._updateFromModel(remoteAudioTrack);
    } else {
      _remoteAudioTrack = null;
    }
  }
}
