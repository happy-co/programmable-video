part of twilio_programmable_video;

/// Generic video capturing interface.
abstract class VideoCapturer {
  /// Indicates whether it is a screen cast.
  bool get isScreenCast;

  /// Update properties from a [VideoCapturerModel].
  void _updateFromModel(VideoCapturerModel model); // ignore: unused_element

// TODO(WLFN): onCapturerStarted and onFrameCaptured streams.
}
