import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a CameraCapturer.
class CameraCapturerModel implements VideoCapturerModel {
  final CameraSource source;
  final String type;
  @override
  final bool isScreencast = false;

  const CameraCapturerModel(
    this.source,
    this.type,
  ) : assert(source != null);

  @override
  String toString() {
    return '{ source: $source, type: $type, isScreencast: $isScreencast }';
  }
}
