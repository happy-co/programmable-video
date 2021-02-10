part of twilio_programmable_video;

/// Abstract base class for audio tracks.
abstract class AudioTrack extends Track {
  AudioTrack(enabled, name)
      : assert(enabled != null),
        assert(name != null),
        super(enabled, name);
}
