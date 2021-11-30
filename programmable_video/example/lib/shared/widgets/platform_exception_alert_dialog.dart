import 'package:flutter/services.dart';

import './platform_alert_dialog.dart';

class PlatformExceptionAlertDialog extends PlatformAlertDialog {
  PlatformExceptionAlertDialog({
    String title = 'An error occurred',
    required Exception exception,
  }) : super(
          title: title,
          content: exception is PlatformException ? _message(exception)! : exception.toString(),
          defaultActionText: 'OK',
        );

  static String? _message(PlatformException exception) {
    final exceptionCode = _errors[exception.code];
    if (exceptionCode == null) {
      final exceptionDetails = exception.details;
      final exceptionMessage = exception.message;

      return exceptionDetails != null ? (exceptionDetails['message'] ?? exceptionMessage) : exceptionMessage;
    } else {
      return exceptionCode;
    }
  }

  static final Map<String, String> _errors = <String, String>{
    'ERROR_CODE': 'Error description...',
  };
}
