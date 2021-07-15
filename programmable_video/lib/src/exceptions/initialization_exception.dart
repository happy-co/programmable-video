part of twilio_programmable_video;

class InitializationException extends PlatformException {
  InitializationException({
    required String code,
    String? message,
    dynamic details,
  }) : super(
          code: code,
          message: message,
          details: details,
        );

  @override
  String toString() => 'InitializationException($code, $message, $details)';
}
