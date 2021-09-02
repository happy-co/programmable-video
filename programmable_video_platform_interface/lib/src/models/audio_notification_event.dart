import 'package:flutter/foundation.dart';

/// The base LocalParticipantEvent that all other LocalParticipantEvent types must extend.
abstract class BaseAudioNotificationEvent {
  const BaseAudioNotificationEvent();

  @override
  String toString() => 'BaseAudioNotificationEvent: { }';
}

/// Use this event if an Audio Device is now available.
class NewDeviceAvailableEvent extends BaseAudioNotificationEvent {
  final String deviceName;
  final bool bluetooth;
  final bool wired;

  const NewDeviceAvailableEvent({
    required this.deviceName,
    required this.bluetooth,
    required this.wired,
  });

  @override
  String toString() => 'NewDeviceAvailableEvent: { deviceName: $deviceName, bluetooth: $bluetooth, wired: $wired }';
}

/// Use this event if an Audio Device is no longer available.
class OldDeviceUnavailableEvent extends BaseAudioNotificationEvent {
  final String deviceName;
  final bool bluetooth;
  final bool wired;

  const OldDeviceUnavailableEvent({
    required this.deviceName,
    required this.bluetooth,
    required this.wired,
  });

  @override
  String toString() => 'OldDeviceUnavailableEvent: { deviceName: $deviceName, bluetooth: $bluetooth, wired: $wired }';
}

/// Use this event if a New Audio Device is available.
class SkipAbleAudioEvent extends BaseAudioNotificationEvent {
  const SkipAbleAudioEvent();

  @override
  String toString() => 'SkipAbleAudioEvent: { }';
}
