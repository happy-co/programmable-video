part of twilio_programmable_video;

class MissingParameterException extends PlatformException {
  MissingParameterException({
    required String code,
    String? message,
    dynamic details,
  }) : super(
          code: code,
          message: message,
          details: details,
        );

  @override
  String toString() => 'MissingParameterException($code, $message, $details)';
}
