import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a LocalVideoTrack.
class LocalVideoTrackModel extends TrackModel {
  final CameraCapturerModel cameraCapturer;

  const LocalVideoTrackModel({
    @required String name,
    @required bool enabled,
    @required this.cameraCapturer,
  })  : assert(name != null),
        assert(enabled != null),
        assert(cameraCapturer != null),
        super(name: name, enabled: enabled);

  factory LocalVideoTrackModel.fromEventChannelMap(Map<String, dynamic> map) {
    assert(map['videoCapturer'] != null);
    var videoCapturerMap = Map<String, dynamic>.from(map['videoCapturer'] as Map<dynamic, dynamic>);
    return LocalVideoTrackModel(
      name: map['name'],
      enabled: map['enabled'],
      cameraCapturer: CameraCapturerModel(
        EnumToString.fromString(CameraSource.values, videoCapturerMap['cameraSource']),
        videoCapturerMap['type'],
      ),
    );
  }

  @override
  String toString() {
    return '{ name: $name, enabled: $enabled, cameraCapturer: $cameraCapturer }';
  }

  @override

  /// Create map from properties.
  Map<String, Object> toMap() {
    return <String, Object>{
      'enable': enabled,
      'name': name,
      'videoCapturer': {
        'cameraSource': EnumToString.parse(cameraCapturer.source),
        'type': 'CameraCapturer',
      },
    };
  }
}
