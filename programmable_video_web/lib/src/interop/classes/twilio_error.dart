@JS()
library twilio_error;

import 'package:js/js.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.TwilioError')
class TwilioError {
  external int get code;
  @override
  external String toString();

  external factory TwilioError();
}

extension Interop on TwilioError {
  TwilioExceptionModel toModel() {
    return TwilioExceptionModel(
      code,
      toString(),
    );
  }
}
