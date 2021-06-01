part of twilio_programmable_video;

class NotFoundException extends PlatformException {
  NotFoundException({
    required String code,
    String? message,
    dynamic details,
  }) : super(
          code: code,
          message: message,
          details: details,
        );

  @override
  String toString() => 'NotFoundException($code, $message, $details)';
}
