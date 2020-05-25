part of twilio_programmable_video;

/// Represents a local audio source.
class LocalAudioTrack extends AudioTrack {
  @override
  bool _enabled;

  /// Check if it is enabled.
  ///
  /// When the value is `false`, the local audio track is muted. When the value is `true` the local audio track is live.
  @override
  bool get isEnabled => _enabled;

  LocalAudioTrack(this._enabled, {String name = ''}) : super(_enabled, name);

  /// Construct from a [TrackModel].
  factory LocalAudioTrack._fromModel(TrackModel model) {
    var localAudioTrack = LocalAudioTrack(model.enabled, name: model.name);
    localAudioTrack._updateFromModel(model);
    return localAudioTrack;
  }

  /// Set the state.
  ///
  /// The results of this operation are signaled to other [Participant]s in the same [Room].
  Future<bool> enable(bool enabled) async {
    _enabled = enabled;
    return ProgrammableVideoPlatform.instance.enableAudioTrack(name: name, enable: enabled);
  }

  /// Create [TrackModel] from properties.
  TrackModel _toModel() {
    return TrackModel(
      enabled: _enabled,
      name: _name,
    );
  }
}
