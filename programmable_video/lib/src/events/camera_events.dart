part of twilio_programmable_video;

class CameraSwitchedEvent {
  final CameraCapturer cameraCapturer;

  const CameraSwitchedEvent(this.cameraCapturer);
}

class FirstFrameAvailableEvent {
  final CameraCapturer cameraCapturer;

  const FirstFrameAvailableEvent(this.cameraCapturer);
}

class CameraErrorEvent {
  final CameraCapturer cameraCapturer;
  final TwilioException exception;

  const CameraErrorEvent(this.cameraCapturer, this.exception);
}
