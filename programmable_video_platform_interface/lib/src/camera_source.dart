import 'package:twilio_programmable_video_platform_interface/src/programmable_video_platform_interface.dart';

/// Camera Source
class CameraSource {
  /// The identifier of this camera source.
  final String cameraId;

  /// Indicates if it is front facing (front camera) or not.
  final bool isFrontFacing;

  /// Indicates if it is front facing (back camera) or not.
  final bool isBackFacing;

  /// Indicates if it is has a torch or not.
  final bool hasTorch;

  /// Construct a [CameraSource] from given arguments.
  ///
  /// **NOTE**: Should not be used outside of the plugin.
  /// Use [CameraSource.getSources] to retrieve a list of [CameraSource]s.
  const CameraSource(
    this.cameraId,
    bool? isFrontFacing,
    bool? isBackFacing,
    bool? hasTorch,
  )   : isFrontFacing = isFrontFacing ?? false,
        isBackFacing = isBackFacing ?? false,
        hasTorch = hasTorch ?? false;

  /// Construct a [CameraSource] from given [map].
  ///
  /// **NOTE**: Should not be used outside of the plugin.
  /// Use [CameraSource.getSources] to retrieve a list of [CameraSource]s.
  CameraSource.fromMap(Map<String, dynamic> map) : this(map['cameraId'], map['isFrontFacing'], map['isBackFacing'], map['hasTorch']);

  @override
  String toString() {
    return '{ cameraId: $cameraId, isFrontFacing: $isFrontFacing, isBackFacing: $isBackFacing, hasTorch: $hasTorch }';
  }

  /// Create map from properties.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'cameraId': cameraId,
      'isFrontFacing': isFrontFacing,
      'isBackFacing': isBackFacing,
      'hasTorch': hasTorch,
    };
  }

  /// Return the available camera sources.
  static Future<List<CameraSource>> getSources() {
    return ProgrammableVideoPlatform.instance.getSources();
  }
}
