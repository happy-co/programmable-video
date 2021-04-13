@JS()
library participant_signaling;

import 'package:js/js.dart';

@JS('Twilio.Video.ParticipantSignaling')
class ParticipantSignaling {
  external factory ParticipantSignaling();
}
