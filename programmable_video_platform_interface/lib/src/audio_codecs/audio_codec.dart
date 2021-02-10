export 'g722_codec.dart';
export 'isac_codec.dart';
export 'opus_codec.dart';
export 'pcma_codec.dart';
export 'pcmu_codec.dart';

/// Abstract base class for audio codecs.
abstract class AudioCodec {
  String name;

  AudioCodec(this.name) : assert(name != null);

  @override
  String toString() {
    return name;
  }
}
