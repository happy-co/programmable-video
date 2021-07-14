@JS()
library logger;

import 'package:js/js.dart';

@JS('Twilio.Video.Logger')
class Logger {
  external static LogLevel getLogger(String name);
}

@JS()
class LogLevel {
  external dynamic get methodFactory;
  external set methodFactory(dynamic res);
  external void setLevel(String name);
  external factory LogLevel();
}
