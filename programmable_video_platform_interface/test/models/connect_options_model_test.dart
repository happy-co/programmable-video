import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/audio_codecs/audio_codec.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/camera_source.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/region.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/video_codecs/video_codec.dart';
import 'package:collection/collection.dart';

void main() {
  final accessToken = 'token';
  final audioTracks = <LocalAudioTrackModel>[
    LocalAudioTrackModel(
      name: 'audio',
      enabled: false,
    ),
  ];
  final dataTracks = <LocalDataTrackModel>[
    LocalDataTrackModel(
      name: 'data',
      enabled: true,
      ordered: true,
      reliable: true,
      maxPacketLifeTime: 10,
      maxRetransmits: 10,
    ),
  ];
  final videoTracks = <LocalVideoTrackModel>[
    LocalVideoTrackModel(
      name: 'video',
      enabled: true,
      cameraCapturer: CameraCapturerModel(CameraSource.FRONT_CAMERA, 'type'),
    ),
  ];
  final enableAutomaticSubscription = true;
  final enableDominantSpeaker = true;
  final preferredAudioCodecs = <AudioCodec>[OpusCodec()];
  final preferredVideoCodecs = <VideoCodec>[H264Codec()];
  final region = Region.br1;
  final roomName = 'roomName';

  group('.toMap()', () {
    test('should return correct Map', () {
      final model = ConnectOptionsModel(
        accessToken,
        audioTracks: audioTracks,
        dataTracks: dataTracks,
        videoTracks: videoTracks,
        enableAutomaticSubscription: enableAutomaticSubscription,
        enableDominantSpeaker: enableDominantSpeaker,
        preferredAudioCodecs: preferredAudioCodecs,
        preferredVideoCodecs: preferredVideoCodecs,
        region: region,
        roomName: roomName,
      );

      expect(
        true,
        DeepCollectionEquality().equals(model.toMap(), {
          'connectOptions': {
            'accessToken': accessToken,
            'roomName': roomName,
            'region': EnumToString.parse(region),
            'preferredAudioCodecs': Map<String, String>.fromIterable(preferredAudioCodecs.map<String>((AudioCodec a) => a.name)),
            'preferredVideoCodecs': Map<String, String>.fromIterable(preferredVideoCodecs.map<String>((VideoCodec v) => v.name)),
            'audioTracks': Map<Object, Object>.fromIterable(audioTracks.map<Map<String, Object>>((TrackModel a) => a.toMap())),
            'dataTracks': Map<Object, Object>.fromIterable(dataTracks.map<Map<String, Object>>((LocalDataTrackModel d) => d.toMap())),
            'videoTracks': Map<Object, Object>.fromIterable(videoTracks.map<Map<String, Object>>((LocalVideoTrackModel v) => v.toMap())),
            'enableDominantSpeaker': enableDominantSpeaker,
            'enableAutomaticSubscription': enableAutomaticSubscription
          },
        }),
      );
    });
  });

  group('ConnectOptionsModel()', () {
    test('should not construct without accessToken', () {
      expect(() => ConnectOptionsModel(null), throwsAssertionError);
      expect(() => ConnectOptionsModel(''), throwsAssertionError);
    });

    test('should not construct with an empty audioTracks list', () {
      // TODO: We need to check if this is true
      expect(
        () => ConnectOptionsModel(
          accessToken,
          audioTracks: [],
        ),
        throwsAssertionError,
      );
    });

    test('should not construct with an empty videoTracks list', () {
      // TODO: We need to check if this is true
      expect(
        () => ConnectOptionsModel(
          accessToken,
          videoTracks: [],
        ),
        throwsAssertionError,
      );
    });

    test('should not construct with an empty dataTracks list', () {
      // TODO: We need to check if this is true
      expect(
        () => ConnectOptionsModel(
          accessToken,
          dataTracks: [],
        ),
        throwsAssertionError,
      );
    });
  });
}
