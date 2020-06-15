/// Model that a plugin implementation can use to construct an implementation of VideoCapturer.
class VideoCapturerModel {
  final bool isScreencast;

  const VideoCapturerModel(
    this.isScreencast,
  );

  @override
  String toString() {
    return '{ isScreencast: $isScreencast }';
  }
}
