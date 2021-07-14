@JS()
library local_video_track;

import 'package:js/js.dart';

@JS('Twilio.Video.LocalTrackOptions')
class LocalTrackOptions {
  external String? get name;

  external factory LocalTrackOptions(
    String? name,
  );
}
