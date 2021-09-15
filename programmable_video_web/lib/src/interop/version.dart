@JS()
library interop;

import 'package:js/js.dart';
import 'package:version/version.dart';

final supportedVersion = Version(2, 14, 0);

@JS('Twilio.Video.version')
external String version;
