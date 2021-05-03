import 'package:flutter/foundation.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

// TODO: Make these events useful
/// The base LocalParticipantEvent that all other LocalParticipantEvent types must extend.
abstract class BaseAudioNotificationEvent {
  // final LocalParticipantModel localParticipantModel;

  const BaseAudioNotificationEvent(
      // this.localParticipantModel,
      );

  @override
  String toString() => 'BaseAudioNotificationEvent: { '
      // 'localParticipantModel: $localParticipantModel'
      '}';
}

/// Use this event if a New Audio Device is available.
class NewDeviceAvailableEvent extends BaseAudioNotificationEvent {
  const NewDeviceAvailableEvent();

  @override
  String toString() => 'NewDeviceAvailableEvent: { '
      // 'localParticipantModel: $localParticipantModel, publicationModel: $publicationModel '
      '}';
}

/// Use this event if a New Audio Device is available.
class OldDeviceUnavailableEvent extends BaseAudioNotificationEvent {
  const OldDeviceUnavailableEvent();

  @override
  String toString() => 'OldDeviceUnavailableEvent: { '
  // 'localParticipantModel: $localParticipantModel, publicationModel: $publicationModel '
      '}';
}

/// Use this event if a New Audio Device is available.
class SkipAbleAudioEvent extends BaseAudioNotificationEvent {
  const SkipAbleAudioEvent();

  @override
  String toString() => 'SkipAbleAudioEvent: { '
  // 'localParticipantModel: $localParticipantModel, publicationModel: $publicationModel '
      '}';
}
