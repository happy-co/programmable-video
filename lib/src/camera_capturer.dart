import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';
import 'package:twilio_unofficial_programmable_video/src/camera_source.dart';
import 'package:twilio_unofficial_programmable_video/src/video_capturer.dart';

/// The CameraCapturer is used to provide video frames for a [LocalVideoTrack] from a given [CameraSource].
class CameraCapturer implements VideoCapturer {
  static final CameraCapturer _cameraCapturer = CameraCapturer._internal();

  CameraSource _cameraSource;

  /// The current specified camera source.
  CameraSource get cameraSource {
    return _cameraSource;
  }

  /// Indicates that the camera capturer is not a screen cast.
  @override
  bool get isScreenCast {
    return false;
  }

  factory CameraCapturer(CameraSource cameraSource) {
    assert(cameraSource != null);
    _cameraCapturer.updateFromMap({'cameraSource': EnumToString.parse(cameraSource)});
    return _cameraCapturer;
  }

  factory CameraCapturer.fromMap(Map<String, dynamic> map) {
    var cameraCapturer = CameraCapturer(EnumToString.fromString(CameraSource.values, map['cameraSource']));
    cameraCapturer.updateFromMap(map);
    return cameraCapturer;
  }

  CameraCapturer._internal();

  /// Switch the current [CameraSource].
  ///
  /// This method can be invoked while capturing frames or not.
  Future<void> switchCamera() {
    return const MethodChannel('twilio_unofficial_programmable_video').invokeMethod('CameraCapturer#switchCamera');
  }

  @override
  void updateFromMap(Map<String, dynamic> map) {
    _cameraSource = EnumToString.fromString(CameraSource.values, map['cameraSource']);
  }

  @override
  Map<String, Object> toMap() {
    return <String, Object>{'cameraSource': EnumToString.parse(_cameraSource), 'type': 'CameraCapturer'};
  }

// TODO(WLFN): Implement event streams.
}
