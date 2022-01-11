part of twilio_programmable_video;

/// A remote video track publication represents a [RemoteVideoTrack] that has been shared to a [Room].
class RemoteVideoTrackPublication implements VideoTrackPublication {
  final String _sid;

  final String _name;

  RemoteVideoTrack? _remoteVideoTrack;

  bool _subscribed;

  bool _enabled;

  /// Reference to the [RemoteParticipant].
  RemoteParticipant _remoteParticipant;

  /// The SID of the published video track.
  @override
  String get trackSid => _sid;

  /// The name of the published video track.
  @override
  String get trackName => _name;

  /// Returns `true` if the published video track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled => _enabled;

  /// Returns `true` if the published video track is subscribed by the local participant or `false` otherwise.
  bool get isTrackSubscribed => _subscribed;

  /// Returns the published remote video track.
  ///
  /// Will return `null` if the track is not subscribed to.
  RemoteVideoTrack? get remoteVideoTrack => _remoteVideoTrack;

  /// The base video track object of the published remote video track.
  ///
  /// Will return `null` if the track is not subscribed to.
  @override
  VideoTrack? get videoTrack => _remoteVideoTrack;

  RemoteVideoTrackPublication(
    this._subscribed,
    this._enabled,
    this._sid,
    this._name,
    this._remoteParticipant,
  );

  /// Create a [RemoteParticipant] from a [RemoteVideoTrackPublicationModel].
  factory RemoteVideoTrackPublication._fromModel(RemoteVideoTrackPublicationModel model, RemoteParticipant remoteParticipant) {
    var remoteVideoTrackPublication = RemoteVideoTrackPublication(model.subscribed, model.enabled, model.sid, model.name, remoteParticipant);
    remoteVideoTrackPublication._updateFromModel(model);
    return remoteVideoTrackPublication;
  }

  /// Update properties from a [RemoteVideoTrackPublicationModel].
  void _updateFromModel(RemoteVideoTrackPublicationModel model) {
    _subscribed = model.subscribed;
    _enabled = model.enabled;

    final remoteVideoTrack = model.remoteVideoTrack;
    if (remoteVideoTrack != null) {
      _remoteVideoTrack ??= RemoteVideoTrack._fromModel(remoteVideoTrack, _remoteParticipant);
      _remoteVideoTrack!._updateFromModel(model.remoteVideoTrack!);
    } else {
      _remoteVideoTrack = null;
    }
  }
}
