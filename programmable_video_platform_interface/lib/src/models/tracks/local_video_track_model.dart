import 'package:twilio_programmable_video_platform_interface/src/camera_source.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a LocalVideoTrack.
class LocalVideoTrackModel extends TrackModel {
  final CameraCapturerModel cameraCapturer;

  const LocalVideoTrackModel({
    required String name,
    required bool enabled,
    required this.cameraCapturer,
  }) : super(name: name, enabled: enabled);

  factory LocalVideoTrackModel.fromEventChannelMap(Map<String, dynamic> map) {
    assert(map['videoCapturer'] != null);
    var videoCapturerMap = Map<String, dynamic>.from(
      map['videoCapturer'] as Map<dynamic, dynamic>,
    );

    final sourceData = videoCapturerMap['source'];
    assert(sourceData != null && sourceData['cameraId'] != null);
    final source = CameraSource.fromMap(Map<String, dynamic>.from(sourceData));

    return LocalVideoTrackModel(
      name: map['name'],
      enabled: map['enabled'],
      cameraCapturer: CameraCapturerModel(source, videoCapturerMap['type']),
    );
  }

  @override
  String toString() {
    return '{ name: $name, enabled: $enabled, cameraCapturer: $cameraCapturer }';
  }

  @override

  /// Create map from properties.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'enable': enabled,
      'name': name,
      'videoCapturer': {
        'source': cameraCapturer.source?.toMap(),
        'type': 'CameraCapturer',
      },
    };
  }
}
