import 'package:twilio_programmable_video_web/src/programmable_video_web.dart';

abstract class BaseListener {
  // Should be overridden by all subclasses.
  void debug(String msg) {
    ProgrammableVideoPlugin.debug('Listener Event: $msg');
  }

  // Helper for debug statements
  String capitalize(String string) {
    if (string.isEmpty) {
      return string;
    }
    return string[0].toUpperCase() + string.substring(1);
  }
}
