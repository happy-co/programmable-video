/// Twilio Video SDK Exception.
class TwilioExceptionModel {
  /// Code indicator
  final int code;

  /// Message containing a short explanation.
  final String message;

  const TwilioExceptionModel(
    this.code,
    this.message,
  );

  @override
  String toString() {
    return '{ code: $code, message: $message }';
  }
}
