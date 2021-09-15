@JS()
library remote_participant;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/js_map.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/participant.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/participant_signaling.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_audio_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_data_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_video_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/network_quality_level.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.RemoteParticipant')
class RemoteParticipant extends Participant {
  // Tracks are stored in a JSMap with the sid as key and the trackPublication as the value.
  @override
  external JSMap<String, RemoteAudioTrackPublication> get audioTracks;
  @override
  external JSMap<String, RemoteDataTrackPublication> get dataTracks;
  @override
  external JSMap<String, dynamic> get tracks;
  @override
  external JSMap<String, RemoteVideoTrackPublication> get videoTracks;

  external factory RemoteParticipant(
    ParticipantSignaling signaling,
    dynamic options,
  );
}

extension Interop on RemoteParticipant {
  RemoteParticipantModel toModel() {
    return RemoteParticipantModel(
      remoteAudioTrackPublications: iteratorToList<RemoteAudioTrackPublicationModel, RemoteAudioTrackPublication>(
        audioTracks.values(),
        (RemoteAudioTrackPublication value) => value.toModel(),
      ),
      remoteDataTrackPublications: iteratorToList<RemoteDataTrackPublicationModel, RemoteDataTrackPublication>(
        dataTracks.values(),
        (RemoteDataTrackPublication value) => value.toModel(),
      ),
      remoteVideoTrackPublications: iteratorToList<RemoteVideoTrackPublicationModel, RemoteVideoTrackPublication>(
        videoTracks.values(),
        (RemoteVideoTrackPublication value) => value.toModel(),
      ),
      networkQualityLevel: networkQualityLevelFromInt(networkQualityLevel),
      identity: identity,
      sid: sid,
    );
  }
}
