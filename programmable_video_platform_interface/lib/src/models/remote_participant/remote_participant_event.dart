import 'package:flutter/foundation.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// The base remoteParticipantEvent that all other RemoteParticipantEvent types must extend.
abstract class BaseRemoteParticipantEvent {
  final RemoteParticipantModel remoteParticipantModel;

  const BaseRemoteParticipantEvent(this.remoteParticipantModel);

  @override
  String toString() => 'BaseRemoteParticipantEvent: { remoteParticipantModel: $remoteParticipantModel }';
}

/// Use this event if a RemoteAudioTrack was disabled.
class RemoteAudioTrackDisabled extends BaseRemoteParticipantEvent {
  final RemoteAudioTrackPublicationModel remoteAudioTrackPublicationModel;

  const RemoteAudioTrackDisabled(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteAudioTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteAudioTrackDisabled: { remoteParticipantModel: $remoteParticipantModel, remoteAudioTrackPublicationModel: $remoteAudioTrackPublicationModel }';
}

/// Use this event if a RemoteAudioTrack was enabled.
class RemoteAudioTrackEnabled extends BaseRemoteParticipantEvent {
  final RemoteAudioTrackPublicationModel remoteAudioTrackPublicationModel;

  const RemoteAudioTrackEnabled(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteAudioTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteAudioTrackEnabled: { remoteParticipantModel: $remoteParticipantModel, remoteAudioTrackPublicationModel: $remoteAudioTrackPublicationModel }';
}

/// Use this event if a RemoteAudioTrack was enabled.
class RemoteAudioTrackPublished extends BaseRemoteParticipantEvent {
  final RemoteAudioTrackPublicationModel remoteAudioTrackPublicationModel;

  const RemoteAudioTrackPublished(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteAudioTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteAudioTrackPublished: { remoteParticipantModel: $remoteParticipantModel, remoteAudioTrackPublicationModel: $remoteAudioTrackPublicationModel }';
}

/// Use this event if a RemoteAudioTrack was subscribed to.
class RemoteAudioTrackSubscribed extends BaseRemoteParticipantEvent {
  final RemoteAudioTrackPublicationModel remoteAudioTrackPublicationModel;
  final RemoteAudioTrackModel remoteAudioTrackModel;

  const RemoteAudioTrackSubscribed({
    @required RemoteParticipantModel remoteParticipantModel,
    @required this.remoteAudioTrackPublicationModel,
    @required this.remoteAudioTrackModel,
  })  : assert(remoteParticipantModel != null),
        assert(remoteAudioTrackPublicationModel != null),
        assert(remoteAudioTrackModel != null),
        super(remoteParticipantModel);

  @override
  String toString() => '''RemoteAudioTrackSubscribed: { 
    remoteParticipantModel: $remoteParticipantModel, remoteAudioTrackPublicationModel: $remoteAudioTrackPublicationModel, remoteAudioTrackModel: $remoteAudioTrackModel
  }''';
}

/// Use this event if subscribing to a RemoteAudioTrack failed.
class RemoteAudioTrackSubscriptionFailed extends BaseRemoteParticipantEvent {
  final RemoteAudioTrackPublicationModel remoteAudioTrackPublicationModel;
  final TwilioExceptionModel exception;

  const RemoteAudioTrackSubscriptionFailed({
    @required RemoteParticipantModel remoteParticipantModel,
    @required this.remoteAudioTrackPublicationModel,
    @required this.exception,
  })  : assert(remoteParticipantModel != null),
        assert(remoteAudioTrackPublicationModel != null),
        assert(exception != null),
        super(remoteParticipantModel);

  @override
  String toString() => '''RemoteAudioTrackSubscriptionFailed: { 
    remoteParticipantModel: $remoteParticipantModel, remoteAudioTrackPublicationModel: $remoteAudioTrackPublicationModel, exception: $exception
  }''';
}

/// Use this event if a RemoteAudioTrack was unpublished.
class RemoteAudioTrackUnpublished extends BaseRemoteParticipantEvent {
  final RemoteAudioTrackPublicationModel remoteAudioTrackPublicationModel;

  const RemoteAudioTrackUnpublished(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteAudioTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteAudioTrackUnpublished: { remoteParticipantModel: $remoteParticipantModel, remoteAudioTrackPublicationModel: $remoteAudioTrackPublicationModel }';
}

/// Use this event if a RemoteAudioTrack was unsubscribed to.
class RemoteAudioTrackUnsubscribed extends BaseRemoteParticipantEvent {
  final RemoteAudioTrackPublicationModel remoteAudioTrackPublicationModel;
  final RemoteAudioTrackModel remoteAudioTrackModel;

  const RemoteAudioTrackUnsubscribed({
    @required RemoteParticipantModel remoteParticipantModel,
    @required this.remoteAudioTrackPublicationModel,
    @required this.remoteAudioTrackModel,
  })  : assert(remoteParticipantModel != null),
        assert(remoteAudioTrackPublicationModel != null),
        assert(remoteAudioTrackModel != null),
        super(remoteParticipantModel);

  @override
  String toString() => '''RemoteAudioTrackUnsubscribed: { 
    remoteParticipantModel: $remoteParticipantModel, remoteAudioTrackPublicationModel: $remoteAudioTrackPublicationModel, remoteAudioTrackModel: $remoteAudioTrackModel
  }''';
}

/// Use this event if a RemoteDataTrack was published.
class RemoteDataTrackPublished extends BaseRemoteParticipantEvent {
  final RemoteDataTrackPublicationModel remoteDataTrackPublicationModel;

  const RemoteDataTrackPublished(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteDataTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteDataTrackPublished: { remoteParticipantModel: $remoteParticipantModel, remoteDataTrackPublicationModel: $remoteDataTrackPublicationModel }';
}

/// Use this event if a RemoteDataTrack was subscibed to.
class RemoteDataTrackSubscribed extends BaseRemoteParticipantEvent {
  final RemoteDataTrackPublicationModel remoteDataTrackPublicationModel;
  final RemoteDataTrackModel remoteDataTrackModel;

  const RemoteDataTrackSubscribed({
    @required RemoteParticipantModel remoteParticipantModel,
    @required this.remoteDataTrackPublicationModel,
    @required this.remoteDataTrackModel,
  })  : assert(remoteParticipantModel != null),
        assert(remoteDataTrackPublicationModel != null),
        assert(remoteDataTrackModel != null),
        super(remoteParticipantModel);

  @override
  String toString() => '''RemoteDataTrackSubscribed: { 
    remoteParticipantModel: $remoteParticipantModel, remoteDataTrackPublicationModel: $remoteDataTrackPublicationModel, remoteDataTrackModel: $remoteDataTrackModel
  }''';
}

/// Use this event if subscribing to a RemoteDataTrack failed.
class RemoteDataTrackSubscriptionFailed extends BaseRemoteParticipantEvent {
  final RemoteDataTrackPublicationModel remoteDataTrackPublicationModel;
  final TwilioExceptionModel exception;

  const RemoteDataTrackSubscriptionFailed({
    @required RemoteParticipantModel remoteParticipantModel,
    @required this.remoteDataTrackPublicationModel,
    @required this.exception,
  })  : assert(remoteParticipantModel != null),
        assert(remoteDataTrackPublicationModel != null),
        assert(exception != null),
        super(remoteParticipantModel);

  @override
  String toString() => '''RemoteDataTrackSubscriptionFailed: { 
    remoteParticipantModel: $remoteParticipantModel, remoteDataTrackPublicationModel: $remoteDataTrackPublicationModel, exception: $exception
  }''';
}

/// Use this event if a RemoteDataTrack was unpublished.
class RemoteDataTrackUnpublished extends BaseRemoteParticipantEvent {
  final RemoteDataTrackPublicationModel remoteDataTrackPublicationModel;

  const RemoteDataTrackUnpublished(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteDataTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteDataTrackUnpublished: { remoteParticipantModel: $remoteParticipantModel, remoteDataTrackPublicationModel: $remoteDataTrackPublicationModel }';
}

/// Use this event if a RemoteDataTrack was unsubscribed to.
class RemoteDataTrackUnsubscribed extends BaseRemoteParticipantEvent {
  final RemoteDataTrackPublicationModel remoteDataTrackPublicationModel;
  final RemoteDataTrackModel remoteDataTrackModel;

  const RemoteDataTrackUnsubscribed({
    @required RemoteParticipantModel remoteParticipantModel,
    @required this.remoteDataTrackPublicationModel,
    @required this.remoteDataTrackModel,
  })  : assert(remoteParticipantModel != null),
        assert(remoteDataTrackPublicationModel != null),
        assert(remoteDataTrackModel != null),
        super(remoteParticipantModel);

  @override
  String toString() => '''RemoteDataTrackUnsubscribed: { 
    remoteParticipantModel: $remoteParticipantModel, remoteDataTrackPublicationModel: $remoteDataTrackPublicationModel, remoteDataTrackModel: $remoteDataTrackModel
  }''';
}

/// Use this event if a RemoteVideoTrack was disabled.
class RemoteVideoTrackDisabled extends BaseRemoteParticipantEvent {
  final RemoteVideoTrackPublicationModel remoteVideoTrackPublicationModel;

  const RemoteVideoTrackDisabled(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteVideoTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteVideoTrackDisabled: { remoteParticipantModel: $remoteParticipantModel, remoteVideoTrackPublicationModel: $remoteVideoTrackPublicationModel }';
}

/// Use this event if a RemoteVideoTrack was enabled.
class RemoteVideoTrackEnabled extends BaseRemoteParticipantEvent {
  final RemoteVideoTrackPublicationModel remoteVideoTrackPublicationModel;

  const RemoteVideoTrackEnabled(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteVideoTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteVideoTrackEnabled: { remoteParticipantModel: $remoteParticipantModel, remoteVideoTrackPublicationModel: $remoteVideoTrackPublicationModel }';
}

/// Use this event if a RemoteVideoTrack was published.
class RemoteVideoTrackPublished extends BaseRemoteParticipantEvent {
  final RemoteVideoTrackPublicationModel remoteVideoTrackPublicationModel;

  const RemoteVideoTrackPublished(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteVideoTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteVideoTrackPublished: { remoteParticipantModel: $remoteParticipantModel, remoteVideoTrackPublicationModel: $remoteVideoTrackPublicationModel }';
}

/// Use this event if a RemoteVideoTrack was subscribed to.
class RemoteVideoTrackSubscribed extends BaseRemoteParticipantEvent {
  final RemoteVideoTrackPublicationModel remoteVideoTrackPublicationModel;
  final RemoteVideoTrackModel remoteVideoTrackModel;

  const RemoteVideoTrackSubscribed({
    @required RemoteParticipantModel remoteParticipantModel,
    @required this.remoteVideoTrackPublicationModel,
    @required this.remoteVideoTrackModel,
  })  : assert(remoteParticipantModel != null),
        assert(remoteVideoTrackPublicationModel != null),
        assert(remoteVideoTrackModel != null),
        super(remoteParticipantModel);

  @override
  String toString() => '''RemoteVideoTrackSubscribed: { 
    remoteParticipantModel: $remoteParticipantModel, remoteVideoTrackPublicationModel: $remoteVideoTrackPublicationModel, remoteVideoTrackModel: $remoteVideoTrackModel
  }''';
}

/// Use this event if subscribing to a RemoteVideoTrack failed.
class RemoteVideoTrackSubscriptionFailed extends BaseRemoteParticipantEvent {
  final RemoteVideoTrackPublicationModel remoteVideoTrackPublicationModel;
  final TwilioExceptionModel exception;

  const RemoteVideoTrackSubscriptionFailed({
    @required RemoteParticipantModel remoteParticipantModel,
    @required this.remoteVideoTrackPublicationModel,
    @required this.exception,
  })  : assert(remoteParticipantModel != null),
        assert(remoteVideoTrackPublicationModel != null),
        assert(exception != null),
        super(remoteParticipantModel);

  @override
  String toString() => '''RemoteVideoTrackSubscriptionFailed: { 
    remoteParticipantModel: $remoteParticipantModel, remoteVideoTrackPublicationModel: $remoteVideoTrackPublicationModel, exception: $exception
  }''';
}

/// Use this event if a RemoteVideoTrack was unpublished.
class RemoteVideoTrackUnpublished extends BaseRemoteParticipantEvent {
  final RemoteVideoTrackPublicationModel remoteVideoTrackPublicationModel;

  const RemoteVideoTrackUnpublished(
    RemoteParticipantModel remoteParticipantModel,
    this.remoteVideoTrackPublicationModel,
  ) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteVideoTrackUnpublished: { remoteParticipantModel: $remoteParticipantModel, remoteVideoTrackPublicationModel: $remoteVideoTrackPublicationModel }';
}

/// Use this event if a RemoteVideoTrack was unsubscribed to.
class RemoteVideoTrackUnsubscribed extends BaseRemoteParticipantEvent {
  final RemoteVideoTrackPublicationModel remoteVideoTrackPublicationModel;
  final RemoteVideoTrackModel remoteVideoTrackModel;

  const RemoteVideoTrackUnsubscribed({
    @required RemoteParticipantModel remoteParticipantModel,
    @required this.remoteVideoTrackPublicationModel,
    @required this.remoteVideoTrackModel,
  })  : assert(remoteParticipantModel != null),
        assert(remoteVideoTrackPublicationModel != null),
        assert(remoteVideoTrackModel != null),
        super(remoteParticipantModel);

  @override
  String toString() => '''RemoteVideoTrackUnsubscribed: { 
    remoteParticipantModel: $remoteParticipantModel, remoteVideoTrackPublicationModel: $remoteVideoTrackPublicationModel, remoteVideoTrackModel: $remoteVideoTrackModel
  }''';
}

/// Use this event if the network quality level changed.
class RemoteNetworkQualityLevelChanged extends BaseRemoteParticipantEvent {
  final NetworkQualityLevel networkQualityLevel;

  const RemoteNetworkQualityLevelChanged(RemoteParticipantModel remoteParticipantModel, this.networkQualityLevel) : super(remoteParticipantModel);

  @override
  String toString() => 'RemoteNetworkQualityLevelChanged: { remoteParticipantModel: $remoteParticipantModel, networkQualityLevel: $networkQualityLevel}';
}

/// Use this event if an invalid RemoteParticipantEvent is received from native code which should be skipped.
class SkipAbleRemoteParticipantEvent extends BaseRemoteParticipantEvent {
  const SkipAbleRemoteParticipantEvent() : super(null);

  @override
  String toString() => 'SkipAbleRemoteParticipantEvent';
}
