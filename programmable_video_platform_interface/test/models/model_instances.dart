import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

class ModelInstances {
  ModelInstances._();

  static const roomModel = RoomModel(
    name: 'name',
    sid: 'sid',
    mediaRegion: Region.br1,
    state: RoomState.CONNECTING,
    localParticipant: localParticipantModel,
    remoteParticipants: <RemoteParticipantModel>[],
  );

  static const localParticipantModel = LocalParticipantModel(
    identity: 'identity',
    sid: 'sid',
    signalingRegion: 'signalingRegion',
    networkQualityLevel: NetworkQualityLevel.NETWORK_QUALITY_LEVEL_ONE,
    localAudioTrackPublications: <LocalAudioTrackPublicationModel>[],
    localDataTrackPublications: <LocalDataTrackPublicationModel>[],
    localVideoTrackPublications: <LocalVideoTrackPublicationModel>[],
  );

  static const remoteParticipantModel = RemoteParticipantModel(
    identity: 'identity',
    sid: 'sid',
    remoteAudioTrackPublications: <RemoteAudioTrackPublicationModel>[],
    remoteDataTrackPublications: <RemoteDataTrackPublicationModel>[],
    remoteVideoTrackPublications: <RemoteVideoTrackPublicationModel>[],
    networkQualityLevel: NetworkQualityLevel.NETWORK_QUALITY_LEVEL_ONE,
  );

  static const twilioExceptionModel = TwilioExceptionModel(1, 'test');

  static const localAudioTrackModel = LocalAudioTrackModel(name: 'name', enabled: true);
  static const localAudioTrackPublicationModel = LocalAudioTrackPublicationModel(
    sid: 'sid',
    localAudioTrack: localAudioTrackModel,
  );

  static const localDataTrackModel = LocalDataTrackModel(
    name: 'name',
    enabled: true,
    maxRetransmits: 1,
    maxPacketLifeTime: 0,
    reliable: true,
    ordered: true,
  );

  static const localDataTrackPublicationModel = LocalDataTrackPublicationModel(
    sid: 'sid',
    localDataTrack: localDataTrackModel,
  );

  static const localVideoTrackModel = LocalVideoTrackModel(
    name: 'name',
    enabled: true,
    cameraCapturer: CameraCapturerModel(CameraSource.FRONT_CAMERA, 'CameraCapturer'),
  );

  static const localVideoTrackPublicationModel = LocalVideoTrackPublicationModel(
    sid: 'sid',
    localVideoTrack: localVideoTrackModel,
  );

  static const remoteAudioTrackModel = RemoteAudioTrackModel(
    name: 'name',
    enabled: true,
    sid: 'sid',
  );

  static const remoteAudioTrackPublicationModel = RemoteAudioTrackPublicationModel(
    subscribed: false,
    enabled: false,
    sid: 'sid',
    name: 'name',
    remoteAudioTrack: remoteAudioTrackModel,
  );

  static const remoteDataTrackModel = RemoteDataTrackModel(
    name: 'name',
    enabled: true,
    maxPacketLifeTime: 11,
    maxRetransmits: 10,
    ordered: false,
    reliable: false,
    sid: 'sid',
  );

  static const remoteDataTrackPublicationModel = RemoteDataTrackPublicationModel(
    subscribed: true,
    enabled: false,
    name: 'name',
    sid: 'sid',
    remoteDataTrack: remoteDataTrackModel,
  );

  static const remoteVideoTrackModel = RemoteVideoTrackModel(
    name: 'name',
    enabled: true,
    sid: 'sid',
  );

  static const remoteVideoTrackPublicationModel = RemoteVideoTrackPublicationModel(
    sid: 'sid',
    name: 'name',
    enabled: true,
    remoteVideoTrack: remoteVideoTrackModel,
    subscribed: false,
  );
}
