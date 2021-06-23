part of twilio_programmable_video;

class MissingCameraException extends PlatformException {
  MissingCameraException({
    required String code,
    String? message,
    dynamic details,
  }) : super(
          code: code,
          message: message,
          details: details,
        );

  @override
  String toString() => 'MissingCameraException($code, $message, $details)';
}
