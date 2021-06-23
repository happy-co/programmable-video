part of twilio_programmable_video;

/// A remote data track publication represents a [RemoteDataTrack] that has been shared to a [Room].
class RemoteDataTrackPublication implements DataTrackPublication {
  final String _sid;
  final String _name;
  RemoteDataTrack? _remoteDataTrack;
  bool _subscribed;
  bool _enabled;

  /// The SID of the published data track.
  @override
  String get trackSid => _sid;

  /// The name of the published data track.
  @override
  String get trackName => _name;

  /// Returns `true` if the published data track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled => _enabled;

  /// Returns `true` if the published data track is subscribed by the local participant or `false` otherwise.
  bool get isTrackSubscribed => _subscribed;

  /// Returns the published remote data track.
  ///
  /// Will return `null` if the track is not subscribed to.
  RemoteDataTrack? get remoteDataTrack => _remoteDataTrack;

  /// The base data track object of the published remote data track.
  ///
  /// Will return `null` if the track is not subscribed to.
  @override
  DataTrack? get dataTrack => _remoteDataTrack;

  RemoteDataTrackPublication(this._subscribed, this._enabled, this._sid, this._name);

  /// Construct from a [RemoteDataTrackPublicationModel].
  factory RemoteDataTrackPublication._fromModel(RemoteDataTrackPublicationModel model) {
    var remoteDataTrackPublication = RemoteDataTrackPublication(model.subscribed, model.enabled, model.sid, model.name);
    remoteDataTrackPublication._updateFromModel(model);
    return remoteDataTrackPublication;
  }

  /// Update properties from a [RemoteDataTrackPublicationModel].
  void _updateFromModel(RemoteDataTrackPublicationModel model) {
    _subscribed = model.subscribed;
    _enabled = model.enabled;

    final remoteDataTrack = model.remoteDataTrack;
    if (remoteDataTrack != null) {
      _remoteDataTrack ??= RemoteDataTrack._fromModel(remoteDataTrack);
      _remoteDataTrack!._updateFromModel(model.remoteDataTrack);
    } else {
      _remoteDataTrack = null;
    }
  }
}
