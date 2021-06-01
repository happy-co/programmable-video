part of twilio_programmable_video;

/// Abstract base class for tracks.
abstract class Track {
  final String _name;

  bool _enabled;

  /// Check if it is enabled.
  bool get isEnabled => _enabled;

  /// The track name.
  ///
  /// A pseudo random string is returned if no track name was specified.
  String get name => _name;

  Track(this._enabled, this._name);

  /// Update properties from a [TrackModel].
  void _updateFromModel(TrackModel model) {
    _enabled = model.enabled;
  }
}
