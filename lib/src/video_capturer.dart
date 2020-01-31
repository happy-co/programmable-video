part of twilio_unofficial_programmable_video;

/// Generic video capturing interface.
abstract class VideoCapturer {
  /// Indicates whether it is a screen cast.
  bool get isScreenCast;

  /// Update properties from a map.
  void _updateFromMap(Map<String, dynamic> map);

  /// Create map from properties.
  Map<String, Object> _toMap();

// TODO(WLFN): onCapturerStarted and onFrameCaptured streams.
}
