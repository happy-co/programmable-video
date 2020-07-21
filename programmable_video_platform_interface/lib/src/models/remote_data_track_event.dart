import 'dart:typed_data';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// The base RemoteDataTrackEvent that all other RemoteDataTrackEvent types must extend.
abstract class BaseRemoteDataTrackEvent {
  final RemoteDataTrackModel remoteDataTrackModel;

  const BaseRemoteDataTrackEvent(this.remoteDataTrackModel);

  @override
  String toString() => 'BaseRemoteDataTrackEvent: { remoteDataTrackModel: $remoteDataTrackModel }';
}

/// Use this event when a string message was sent.
class StringMessage extends BaseRemoteDataTrackEvent {
  final String message;

  const StringMessage(
    RemoteDataTrackModel remoteDataTrackModel,
    this.message,
  ) : super(remoteDataTrackModel);

  @override
  String toString() => 'StringMessage: { remoteDataTrackModel: $remoteDataTrackModel, message: $message }';
}

/// Use this event when a buffer message was sent.
class BufferMessage extends BaseRemoteDataTrackEvent {
  final ByteBuffer message;

  const BufferMessage(
    RemoteDataTrackModel remoteDataTrackModel,
    this.message,
  ) : super(remoteDataTrackModel);

  @override
  String toString() => 'StringMessage: { remoteDataTrackModel: $remoteDataTrackModel, message: $message }';
}

/// Use this event when the event received from native code was unknown.
class UnknownEvent extends BaseRemoteDataTrackEvent {
  final String eventName;

  const UnknownEvent(
    RemoteDataTrackModel remoteDataTrackModel,
    this.eventName,
  ) : super(remoteDataTrackModel);

  @override
  String toString() => 'UnknownEvent: { eventName: $eventName }';
}

/// Use this event if an invalid RemoteDataTrackEvent was received from native code which should be skipped.
class SkipAbleRemoteDataTrackEvent extends BaseRemoteDataTrackEvent {
  const SkipAbleRemoteDataTrackEvent() : super(null);

  @override
  String toString() => 'SkipAbleRemoteDataTrackEvent';
}
