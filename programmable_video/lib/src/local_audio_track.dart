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

  /// Construct from a [LocalAudioTrackModel].
  factory LocalAudioTrack._fromModel(LocalAudioTrackModel model) {
    var localAudioTrack = LocalAudioTrack(model.enabled, name: model.name);
    localAudioTrack._updateFromModel(model);
    return localAudioTrack;
  }

  /// Set the state.
  ///
  /// The results of this operation are signaled to other [Participant]s in the same [Room].
  /// Throws [MissingParameterException] if [enabled] is not provided.
  /// Throws [NotFoundException] if no track is found by the name provided (probably means you haven't connected).
  Future<void> enable(bool enabled) async {
    try {
      await ProgrammableVideoPlatform.instance.enableAudioTrack(name: name, enable: enabled);
      _enabled = enabled;
    } on PlatformException catch (err) {
      throw TwilioProgrammableVideo._convertException(err);
    }
  }

  /// Create [TrackModel] from properties.
  TrackModel _toModel() {
    return LocalAudioTrackModel(
      enabled: _enabled,
      name: _name,
    );
  }
}
