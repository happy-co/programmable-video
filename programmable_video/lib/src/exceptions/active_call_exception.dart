part of twilio_programmable_video;

class ActiveCallException extends PlatformException {
  ActiveCallException({
    required String code,
    String? message,
    dynamic details,
  }) : super(
          code: code,
          message: message,
          details: details,
        );

  @override
  String toString() => 'ActiveCallException($code, $message, $details)';
}
