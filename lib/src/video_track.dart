part of twilio_unofficial_programmable_video;

abstract class VideoTrack {
  final String _name;

  bool _enabled;

  /// Check if it is enabled.
  bool get isEnabled {
    return _enabled;
  }

  /// The video track name.
  ///
  /// A pseudo random string is returned if no track name was specified.
  String get name {
    return _name;
  }

  VideoTrack(this._enabled, this._name)
      : assert(_enabled != null),
        assert(_name != null);

  /// Update properties from a map.
  void _updateFromMap(Map<String, dynamic> map) {
    _enabled = map['enabled'];
  }
}
