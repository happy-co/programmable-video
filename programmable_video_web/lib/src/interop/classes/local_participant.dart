@JS()
library local_participant;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/js_map.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_audio_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_audio_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_data_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_data_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_video_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_video_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/participant.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/participant_signaling.dart';
import 'package:twilio_programmable_video_web/src/interop/network_quality_level.dart';

import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS()
@anonymous
class LocalParticipantOptions {
  external factory LocalParticipantOptions({
    LocalAudioTrack LocalAudioTrack,
    LocalVideoTrack LocalVideoTrack,
    LocalDataTrack LocalDataTrack,
    dynamic MediaStreamTrack,
    LocalAudioTrackPublication LocalAudioTrackPublication,
    LocalVideoTrackPublication LocalVideoTrackPublication,
    LocalDataTrackPublication LocalDataTrackPublication,
    bool shouldStopLocalTracks,
    dynamic localTracks,
  });
}

@JS('Twilio.Video.LocalParticipant')
class LocalParticipant extends Participant {
  // Tracks are stored in a javascript Map with the sid as key and the trackPublication as the value.
  @override
  external JSMap<String, LocalAudioTrackPublication> get audioTracks;
  @override
  external JSMap<String, LocalDataTrackPublication> get dataTracks;
  @override
  external JSMap<String, LocalTrackPublication> get tracks;
  @override
  external JSMap<String, LocalVideoTrackPublication> get videoTracks;
  external String get signalingRegion;

  external factory LocalParticipant(
    ParticipantSignaling signaling,
    List<dynamic> localTracks,
    LocalParticipantOptions options,
  );

  /// [localTrack] must be an instance of either: [LocalAudioTrack], [LocalDataTrack] or [LocalVideoTrack]
  external Future<LocalTrackPublication> publishTrack(dynamic localTrack);

  external List<LocalTrackPublication> unpublishTrack(dynamic track);
}

extension Interop on LocalParticipant {
  LocalParticipantModel toModel() {
    return LocalParticipantModel(
      identity: identity,
      localAudioTrackPublications: iteratorToList<LocalAudioTrackPublicationModel, LocalAudioTrackPublication>(
        audioTracks.values(),
        (LocalAudioTrackPublication value) => value.toModel(),
      ),
      localDataTrackPublications: iteratorToList<LocalDataTrackPublicationModel, LocalDataTrackPublication>(
        dataTracks.values(),
        (LocalDataTrackPublication value) => value.toModel(),
      ),
      localVideoTrackPublications: iteratorToList<LocalVideoTrackPublicationModel, LocalVideoTrackPublication>(
        videoTracks.values(),
        (LocalVideoTrackPublication value) => value.toModel(),
      ),
      networkQualityLevel: networkQualityLevelFromInt(networkQualityLevel),
      signalingRegion: signalingRegion,
      sid: sid,
    );
  }
}
