import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a RemoteDataTrack.
class RemoteDataTrackModel extends TrackModel {
  final bool ordered;
  final bool reliable;
  final int maxPacketLifeTime;
  final int maxRetransmits;
  final String sid;

  const RemoteDataTrackModel({
    required String name,
    required bool enabled,
    required this.sid,
    this.ordered = false,
    this.reliable = false,
    this.maxPacketLifeTime = 0,
    this.maxRetransmits = 0,
  }) : super(name: name, enabled: enabled);

  factory RemoteDataTrackModel.fromEventChannelMap(Map<String, dynamic> map) {
    return RemoteDataTrackModel(
      name: map['name'],
      ordered: map['ordered'],
      reliable: map['reliable'],
      maxPacketLifeTime: map['maxPacketLifeTime'],
      maxRetransmits: map['maxRetransmits'],
      enabled: map['enabled'],
      sid: map['sid'],
    );
  }

  @override
  String toString() {
    return '{ name: $name, enabled: $enabled, ordered: $ordered, reliable: $reliable, maxPacketLifeTime: $maxPacketLifeTime, maxRetransmits: $maxRetransmits, sid: $sid }';
  }
}
