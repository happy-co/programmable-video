class TwilioException implements Exception {
  final int code;

  final String message;

  TwilioException(this.code, this.message);

  @override
  String toString() {
    return 'TwilioException: code: $code, message: $message';
  }
}
