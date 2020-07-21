part of twilio_programmable_video;

abstract class VideoTrack extends Track {
  VideoTrack(enabled, name)
      : assert(enabled != null),
        assert(name != null),
        super(enabled, name);
}
