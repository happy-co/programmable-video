abstract class VideoTrack {
  bool _enabled;

  /// Check if it is enabled.
  bool get isEnabled {
    return _enabled;
  }

  VideoTrack(this._enabled) : assert(_enabled != null);

  void updateFromMap(Map<String, dynamic> map) {
    _enabled = map['enabled'];
  }
}