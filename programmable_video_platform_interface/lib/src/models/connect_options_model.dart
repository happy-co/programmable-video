import 'package:enum_to_string/enum_to_string.dart';
import 'package:twilio_programmable_video_platform_interface/src/audio_codecs/audio_codec.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/video_codecs/video_codec.dart';

import 'model_exports.dart';

class ConnectOptionsModel {
  /// This Access Token is the credential you must use to identify and authenticate your request.
  /// More information about Access Tokens can be found here: https://www.twilio.com/docs/video/tutorials/user-identity-access-tokens
  final String accessToken;

  /// The name of the room.
  final String roomName;

  /// The region of the signaling Server the Client will use.
  final Region region;

  /// Enable detection of the loudest audio track
  final bool enableDominantSpeaker;

  /// Set preferred audio codecs.
  final List<AudioCodec> preferredAudioCodecs;

  /// Set preferred video codecs.
  final List<VideoCodec> preferredVideoCodecs;

  /// Audio tracks that will be published upon connection.
  final List<LocalAudioTrackModel> audioTracks;

  /// Data tracks that will be published upon connection.
  final List<LocalDataTrackModel> dataTracks;

  /// Video tracks that will be published upon connection.
  final List<LocalVideoTrackModel> videoTracks;

  /// Choosing between `subscribe-to-all` or `subscribe-to-none` subscription rule
  final bool enableAutomaticSubscription;

  /// Enable or disable the Network Quality API.
  /// Set this to true to enable the Network Quality API when using Group Rooms.
  final bool enableNetworkQuality;

  /// Sets the verbosity level for network quality information returned by the
  /// Network Quality API.
  final NetworkQualityConfigurationModel networkQualityConfiguration;

  ConnectOptionsModel(
    this.accessToken, {
    this.audioTracks,
    this.dataTracks,
    this.preferredAudioCodecs,
    this.preferredVideoCodecs,
    this.region,
    this.roomName,
    this.videoTracks,
    this.enableDominantSpeaker,
    this.enableAutomaticSubscription,
    this.enableNetworkQuality,
    this.networkQualityConfiguration,
  })  : assert(accessToken != null),
        assert(accessToken.isNotEmpty),
        assert((audioTracks != null && audioTracks.isNotEmpty) || audioTracks == null),
        assert((dataTracks != null && dataTracks.isNotEmpty) || dataTracks == null),
        assert((preferredAudioCodecs != null && preferredAudioCodecs.isNotEmpty) || preferredAudioCodecs == null),
        assert((preferredVideoCodecs != null && preferredVideoCodecs.isNotEmpty) || preferredVideoCodecs == null),
        assert((region != null && region is Region) || region == null),
        assert((videoTracks != null && videoTracks.isNotEmpty) || videoTracks == null),
        assert((networkQualityConfiguration != null && networkQualityConfiguration is NetworkQualityConfigurationModel) || networkQualityConfiguration == null);

  /// Create map from properties.
  Map<String, Object> toMap() {
    return {
      'connectOptions': {
        'accessToken': accessToken,
        'roomName': roomName,
        'region': EnumToString.parse(region),
        'preferredAudioCodecs': preferredAudioCodecs != null ? Map<String, String>.fromIterable(preferredAudioCodecs.map<String>((AudioCodec a) => a.name)) : null,
        'preferredVideoCodecs': preferredVideoCodecs != null ? Map<String, String>.fromIterable(preferredVideoCodecs.map<String>((VideoCodec v) => v.name)) : null,
        'audioTracks': audioTracks != null ? Map<Object, Object>.fromIterable(audioTracks.map<Map<String, Object>>((TrackModel a) => a.toMap())) : null,
        'dataTracks': dataTracks != null ? Map<Object, Object>.fromIterable(dataTracks.map<Map<String, Object>>((LocalDataTrackModel d) => d.toMap())) : null,
        'videoTracks': videoTracks != null ? Map<Object, Object>.fromIterable(videoTracks.map<Map<String, Object>>((LocalVideoTrackModel v) => v.toMap())) : null,
        'enableDominantSpeaker': enableDominantSpeaker,
        'enableAutomaticSubscription': enableAutomaticSubscription,
        'enableNetworkQuality': enableNetworkQuality,
        'networkQualityConfiguration': networkQualityConfiguration != null ? networkQualityConfiguration.toMap() : null
      },
    };
  }
}
