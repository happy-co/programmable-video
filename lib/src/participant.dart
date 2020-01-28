import 'package:twilio_unofficial_programmable_video/src/audio_track_publication.dart';
import 'package:twilio_unofficial_programmable_video/src/video_track_publication.dart';

abstract class Participant {
  /// The unique identifier of a participant.
  String get sid;

  /// The identity of a participant.
  String get identity;

  /// The audio track publications of a participant.
  List<AudioTrackPublication> get audioTracks;

//  /// The data track publications of a participant.
//  List<DataTrackPublication> get dataTracks;

  /// The video track publications of a participant.
  List<VideoTrackPublication> get videoTracks;
}
