import 'package:twilio_unofficial_programmable_video/src/audio_track.dart';
import 'package:twilio_unofficial_programmable_video/src/track_publication.dart';

abstract class AudioTrackPublication extends TrackPublication {
  /// The published audio track.
  AudioTrack get audioTrack;
}
