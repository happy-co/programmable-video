part of twilio_unofficial_programmable_video;

/// Abstract base class for video codecs.
abstract class VideoCodec {
  String name;

  VideoCodec(this.name) : assert(name != null);

  @override
  String toString() {
    return name;
  }
}
