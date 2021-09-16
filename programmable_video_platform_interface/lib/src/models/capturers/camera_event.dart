import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

abstract class BaseCameraEvent {
  final CameraCapturerModel? model;

  const BaseCameraEvent(this.model);

  @override
  String toString() => 'CameraEvent: { source: ${model!.source} }';
}

/// Use this event if camera was switched
class CameraSwitched extends BaseCameraEvent {
  const CameraSwitched(
    CameraCapturerModel model,
  ) : super(model);

  @override
  String toString() => 'CameraSwitchedEvent: { source: ${model!.source} }';
}

/// Use this event if camera was switched
class FirstFrameAvailable extends BaseCameraEvent {
  const FirstFrameAvailable(
    CameraCapturerModel model,
  ) : super(model);

  @override
  String toString() => 'FirstFrameAvailableEvent: { source: ${model!.source} }';
}

/// Use this event if camera was switched
class CameraError extends BaseCameraEvent {
  final TwilioExceptionModel exception;

  const CameraError(
    CameraCapturerModel model,
    this.exception,
  ) : super(model);

  @override
  String toString() => 'CameraErrorEvent: { source: ${model!.source}, exception: $exception }';
}

class SkippableCameraEvent extends BaseCameraEvent {
  const SkippableCameraEvent() : super(null);

  @override
  String toString() => 'SkippableCameraEvent';
}
