import 'package:twilio_programmable_video_platform_interface/src/models/tracks/track_model.dart';

/// Model that a plugin implementation can use to construct a DataTrack.
class DataTrackModel extends TrackModel {
  final bool ordered;
  final bool reliable;
  final int maxPacketLifeTime;
  final int maxRetransmits;

  const DataTrackModel({String name, bool enabled, this.ordered, this.reliable, this.maxPacketLifeTime, this.maxRetransmits});

  factory DataTrackModel.fromEventChannelMap(Map<String, dynamic> map) {
    return DataTrackModel(name: map['name'], ordered: map['ordered'], reliable: map['reliable'], maxPacketLifeTime: map['maxPacketLifeTime'], maxRetransmits: map['maxRetransmits'], enabled: map['enabled']);
  }

  @override
  String toString() {
    return '{ name: $name, enabled: $enabled, ordered: $ordered, reliable: $reliable, maxPacketLifeTime: $maxPacketLifeTime, maxRetransmits: $maxRetransmits }';
  }
}
