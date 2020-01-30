part of twilio_unofficial_programmable_video;

abstract class VideoCodec {
  String name;

  VideoCodec(this.name) : assert(name != null);

  @override
  String toString() {
    return name;
  }
}
