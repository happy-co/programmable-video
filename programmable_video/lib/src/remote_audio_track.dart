part of twilio_programmable_video;

/// A remote audio track represents a remote audio source.
class RemoteAudioTrack extends AudioTrack {
  final String _sid;

  /// Returns the server identifier. This value uniquely identifies the remote audio track within the scope of a [Room].
  String get sid => _sid;

  RemoteAudioTrack(this._sid, _enabled, _name)
      : assert(_sid != null),
        super(_enabled, _name);

  /// Construct from a [RemoteAudioTrackModel].
  factory RemoteAudioTrack._fromModel(RemoteAudioTrackModel model) {
    return model != null ? RemoteAudioTrack(model.sid, model.enabled, model.name) : null;
  }
}
