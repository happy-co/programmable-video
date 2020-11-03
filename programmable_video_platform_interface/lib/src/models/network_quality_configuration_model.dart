import 'package:enum_to_string/enum_to_string.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/local_participant/local_participant_model.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/remote_participant/remote_participant_model.dart';

/// Model that a plugin implementation can use to construct a CameraCapturer.
class NetworkQualityConfigurationModel {
  /// The [NetworkQualityVerbosity] for the [LocalParticipantModel].
  final NetworkQualityVerbosity local;

  /// The [NetworkQualityVerbosity] for the [RemoteParticipantModel].
  final NetworkQualityVerbosity remote;

  const NetworkQualityConfigurationModel(this.local, this.remote);

  /// Create map from properties.
  Map<String, Object> toMap() {
    return <String, Object>{
      'local': EnumToString.parse(local),
      'remote': EnumToString.parse(remote),
    };
  }

  @override
  String toString() {
    return '{ local: $local, remote: $remote }';
  }
}
