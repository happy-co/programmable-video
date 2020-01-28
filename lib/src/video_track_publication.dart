import 'package:twilio_unofficial_programmable_video/src/track_publication.dart';
import 'package:twilio_unofficial_programmable_video/src/video_track.dart';

abstract class VideoTrackPublication extends TrackPublication {
  /// The published video track.
  VideoTrack get videoTrack;
}
