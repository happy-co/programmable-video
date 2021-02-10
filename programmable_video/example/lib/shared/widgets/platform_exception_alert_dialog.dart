import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './platform_alert_dialog.dart';

class PlatformExceptionAlertDialog extends PlatformAlertDialog {
  PlatformExceptionAlertDialog({
    String title = 'An error occurred',
    @required Exception exception,
  }) : super(
          title: title,
          content: exception is PlatformException ? _message(exception) : exception.toString(),
          defaultActionText: 'OK',
        );

  static String _message(PlatformException exception) {
    return _errors[exception.code] ?? (exception.details != null ? (exception.details['message'] ?? exception.message) : exception.message);
  }

  static final Map<String, String> _errors = <String, String>{
    'ERROR_CODE': 'Error description...',
  };
}
