/// Generic video capturing interface.
abstract class VideoCapturer {
  /// Indicates whether the capturer is a screen cast.
  bool get isScreenCast;

  void updateFromMap(Map<String, dynamic> map);

  Map<String, Object> toMap();

// TODO(WLFN): onCapturerStarted and onFrameCaptured streams.
}
