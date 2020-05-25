export 'h264_codec.dart';
export 'vp8_codec.dart';
export 'vp9_codec.dart';

/// Abstract base class for video codecs.
abstract class VideoCodec {
  String name;

  VideoCodec(this.name) : assert(name != null);

  @override
  String toString() {
    return name;
  }
}
