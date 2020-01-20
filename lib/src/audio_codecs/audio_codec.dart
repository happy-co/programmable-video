abstract class AudioCodec {
  String name;

  AudioCodec(this.name) : assert(name != null);

  @override
  String toString() {
    return name;
  }
}
