@JS()
library interop;

import 'package:enum_to_string/enum_to_string.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:programmable_video_web/src/interop/classes/local_data_track.dart';
import 'package:programmable_video_web/src/interop/classes/room.dart';
import 'package:programmable_video_web/src/interop/classes/track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.connect')
external Future<Room> connect(
  String token, [
  ConnectOptions options,
]);

@JS()
@anonymous
class NetworkQualityConfiguration {
  external factory NetworkQualityConfiguration({
    int local,
    int remote,
  });
}

//dynamic types might still need to be implemented with custom classes
@JS()
@anonymous
class ConnectOptions {
  external factory ConnectOptions({
    bool audio,
    bool? automaticSubscription = true,
    dynamic bandwidthProfile,
    bool? dominantSpeaker,
    bool dscpTagging,
    bool enableDscp,
    dynamic iceServers,
    dynamic iceTransportPolicy,
    bool insights,
    int maxAudioBitrate,
    int maxVideoBitrate,
    String? name,
    dynamic networkQuality = false,
    String region,
    List<dynamic> preferredAudioCodecs,
    List<dynamic> preferredVideoCodecs,
    dynamic logLevel,
    String loggerName,
    List<Track> tracks,
    dynamic video,
  });
}

/// Calls twilio-video.js connect method with values from the [ConnectOptionsModel]
///
/// Setting custom track names is not yet supported.
Future<Room> connectWithModel(ConnectOptionsModel model) {
  // In the future tracks should be created manually before calling connect.
  // This would make it possible to use custom track names that might be in the provided model.
  //
  // See:
  // https://media.twiliocdn.com/sdk/js/video/releases/2.13.1/docs/global.html#ConnectOptions__anchor
  // https://media.twiliocdn.com/sdk/js/video/releases/2.13.1/docs/global.html#LocalTrackOptions
  final networkQualityConfiguration = model.networkQualityConfiguration;

  return promiseToFuture<Room>(
    connect(
      model.accessToken,
      // Some named parameters are assigned their default values with the ?? operator.
      // This is because those paramaters are optional non nullable parameters in js.
      ConnectOptions(
        audio: model.audioTracks != null,
        automaticSubscription: model.enableAutomaticSubscription,
        dominantSpeaker: model.enableDominantSpeaker,
        name: model.roomName,
        networkQuality: networkQualityConfiguration != null && model.enableNetworkQuality
            ? NetworkQualityConfiguration(
                local: networkQualityConfiguration.local.index,
                remote: networkQualityConfiguration.remote.index,
              )
            : model.enableNetworkQuality,
        region: model.region != null ? EnumToString.convertToString(model.region) : 'gll',
        preferredAudioCodecs: model.preferredAudioCodecs?.map((e) => e.name)?.toList() ?? [],
        preferredVideoCodecs: model.preferredVideoCodecs?.map((e) => e.name)?.toList() ?? [],
        video: model.videoTracks != null,
      ),
    ),
  )..then((room) {
      final audioTracksIterator = room.localParticipant.audioTracks.values();
      model.audioTracks?.forEach((audioTrack) {
        final jsTrack = audioTracksIterator.next().value.track;
        audioTrack.enabled ? jsTrack.enable() : jsTrack.disable();
      });

      // DataTracks are published here manually because they don't need a mediaStream from getUserMedia()
      model.dataTracks?.forEach((dataTrack) {
        final jsTrack = LocalDataTrack(
          LocalDataTrackOptions(
            maxPacketLifeTime: dataTrack.maxPacketLifeTime,
            maxRetransmits: dataTrack.maxRetransmits,
            ordered: dataTrack.ordered,
          ),
        );

        room.localParticipant.publishTrack(jsTrack);
      });

      //TODO: handle multiple cameras using the CameraCapturer enum from the platform interface
      final videoTracksIterator = room.localParticipant.videoTracks.values();
      model.videoTracks?.forEach((videoTrack) {
        final jsTrack = videoTracksIterator.next().value.track;
        videoTrack.enabled ? jsTrack.enable() : jsTrack.disable();
      });
    });
}
