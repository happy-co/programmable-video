@JS()
library participant;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/event_emitter.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/js_map.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/participant_signaling.dart';

@JS('Twilio.Video.Participant')
class Participant extends EventEmitter {
  // Tracks are stored in a javascript Map with the sid as key and the trackPublication as the value.
  external JSMap<String, dynamic> get audioTracks;
  external JSMap<String, dynamic> get dataTracks;
  external String get identity;
  external int get networkQualityLevel;
  external int get networkQualityStats;
  external String get sid;
  external String get state;
  external JSMap<String, dynamic> get tracks;
  external JSMap<String, dynamic> get videoTracks;

  external factory Participant(
    ParticipantSignaling signaling,
    dynamic options,
  );
}
