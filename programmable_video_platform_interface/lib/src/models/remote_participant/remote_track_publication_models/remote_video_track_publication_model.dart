import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a RemoteVideoTrackPublication.
class RemoteVideoTrackPublicationModel {
  final bool subscribed;
  final bool enabled;
  final String sid;
  final String name;

  final RemoteVideoTrackModel? remoteVideoTrack;

  const RemoteVideoTrackPublicationModel({
    required this.subscribed,
    required this.enabled,
    required this.sid,
    required this.name,
    required this.remoteVideoTrack,
  });

  factory RemoteVideoTrackPublicationModel.fromEventChannelMap(Map<String, dynamic> map) {
    RemoteVideoTrackModel? remoteVideoTrack;
    if (map['remoteVideoTrack'] != null) {
      remoteVideoTrack = RemoteVideoTrackModel.fromEventChannelMap(Map<String, dynamic>.from(map['remoteVideoTrack']));
    }
    return RemoteVideoTrackPublicationModel(
      sid: map['sid'],
      name: map['name'],
      enabled: map['enabled'],
      subscribed: map['subscribed'],
      remoteVideoTrack: remoteVideoTrack,
    );
  }

  @override
  String toString() {
    return '{ subscribed: $subscribed, enabled: $enabled, sid: $sid, name: $name, remoteVideoTrack: $remoteVideoTrack }';
  }
}
