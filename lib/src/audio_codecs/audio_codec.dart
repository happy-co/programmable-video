part of twilio_unofficial_programmable_video;

/// Abstract base class for audio codecs.
abstract class AudioCodec {
  String name;

  AudioCodec(this.name) : assert(name != null);

  @override
  String toString() {
    return name;
  }
}
