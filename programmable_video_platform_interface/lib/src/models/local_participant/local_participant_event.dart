import 'package:flutter/foundation.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// The base LocalParticipantEvent that all other LocalParticipantEvent types must extend.
abstract class BaseLocalParticipantEvent {
  final LocalParticipantModel localParticipantModel;

  const BaseLocalParticipantEvent(
    this.localParticipantModel,
  );

  @override
  String toString() => 'BaseLocalParticipantEvent: { localParticipantModel: $localParticipantModel}';
}

/// Use this event if a LocalAudioTrack is published.
class LocalAudioTrackPublished extends BaseLocalParticipantEvent {
  final LocalAudioTrackPublicationModel publicationModel;

  const LocalAudioTrackPublished(
    LocalParticipantModel localParticipantModel,
    this.publicationModel,
  ) : super(localParticipantModel);

  @override
  String toString() => 'LocalAudioTrackPublished: { localParticipantModel: $localParticipantModel, publicationModel: $publicationModel }';
}

/// Use this event if publishing a LocalAudioTrack failed.
class LocalAudioTrackPublicationFailed extends BaseLocalParticipantEvent {
  final LocalAudioTrackModel localAudioTrack;
  final TwilioExceptionModel exception;

  const LocalAudioTrackPublicationFailed({
    @required this.localAudioTrack,
    @required this.exception,
    @required LocalParticipantModel localParticipantModel,
  })  : assert(localAudioTrack != null),
        assert(exception != null),
        assert(localParticipantModel != null),
        super(localParticipantModel);

  @override
  String toString() => 'LocalAudioTrackPublicationFailed: { localParticipantModel: $localParticipantModel, localAudioTrack: $localAudioTrack, exception: $exception }';
}

/// Use this event if a LocalDataTrack is published.
class LocalDataTrackPublished extends BaseLocalParticipantEvent {
  final LocalDataTrackPublicationModel publicationModel;

  const LocalDataTrackPublished(
    LocalParticipantModel localParticipantModel,
    this.publicationModel,
  ) : super(localParticipantModel);

  @override
  String toString() => 'LocalDataTrackPublished: { localParticipantModel: $localParticipantModel, publicationModel: $publicationModel }';
}

/// Use this event if publishing a LocalDataTrack failed.
class LocalDataTrackPublicationFailed extends BaseLocalParticipantEvent {
  final LocalDataTrackModel localDataTrack;
  final TwilioExceptionModel exception;

  const LocalDataTrackPublicationFailed({
    @required this.localDataTrack,
    @required this.exception,
    @required LocalParticipantModel localParticipantModel,
  })  : assert(localDataTrack != null),
        assert(exception != null),
        assert(localParticipantModel != null),
        super(localParticipantModel);

  @override
  String toString() => 'LocalDataTrackPublicationFailed: { localParticipantModel: $localParticipantModel, localDataTrack: $localDataTrack, exception: $exception }';
}

/// Use this event if a LocalVideoTrack is published.
class LocalVideoTrackPublished extends BaseLocalParticipantEvent {
  final LocalVideoTrackPublicationModel publicationModel;

  const LocalVideoTrackPublished(
    LocalParticipantModel localParticipantModel,
    this.publicationModel,
  ) : super(localParticipantModel);

  @override
  String toString() => 'LocalVideoTrackPublished: { localParticipantModel: $localParticipantModel, publicationModel: $publicationModel }';
}

/// Use this event if publishing a LocalVideoTrack failed.
class LocalVideoTrackPublicationFailed extends BaseLocalParticipantEvent {
  final LocalVideoTrackModel localVideoTrack;
  final TwilioExceptionModel exception;

  const LocalVideoTrackPublicationFailed({
    @required this.localVideoTrack,
    @required this.exception,
    @required LocalParticipantModel localParticipantModel,
  })  : assert(localVideoTrack != null),
        assert(exception != null),
        assert(localParticipantModel != null),
        super(localParticipantModel);

  @override
  String toString() => 'LocalVideoTrackPublicationFailed: { localParticipantModel: $localParticipantModel, localVideoTrack: $localVideoTrack, exception: $exception }';
}

/// Use this event if the network quality level changed.
class LocalNetworkQualityLevelChanged extends BaseLocalParticipantEvent {
  final NetworkQualityLevel networkQualityLevel;

  const LocalNetworkQualityLevelChanged(LocalParticipantModel localParticipantModel, this.networkQualityLevel) : super(localParticipantModel);

  @override
  String toString() => 'LocalNetworkQualityLevelChanged: { localParticipantModel: $localParticipantModel, networkQualityLevel: $networkQualityLevel}';
}

/// Use this event if an invalid LocalParticipantEvent is received from native code which should be skipped.
class SkipAbleLocalParticipantEvent extends BaseLocalParticipantEvent {
  const SkipAbleLocalParticipantEvent() : super(null);

  @override
  String toString() => 'SkipAbleLocalParticipantEvent';
}
