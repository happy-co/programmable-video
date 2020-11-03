import 'package:twilio_programmable_video_platform_interface/src/enums/network_quality_level.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/local_participant/local_participant_model.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/remote_participant/remote_participant_model.dart';

enum NetworkQualityVerbosity {
  /// Nothing is reported for the [LocalParticipantModel] and [RemoteParticipantModel].
  /// This is not a valid option for the [LocalParticipantModel].
  NETWORK_QUALITY_VERBOSITY_NONE,

  /// Reports only the [NetworkQualityLevel] for the [LocalParticipantModel] and [RemoteParticipantModel].
  NETWORK_QUALITY_VERBOSITY_MINIMAL
}
