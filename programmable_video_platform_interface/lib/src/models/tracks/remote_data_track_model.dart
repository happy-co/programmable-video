import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a RemoteDataTrack.
class RemoteDataTrackModel extends DataTrackModel {
  final String sid;

  const RemoteDataTrackModel({@required String name, @required bool enabled, @required bool ordered, @required bool reliable, @required int maxPacketLifeTime, @required int maxRetransmits, @required this.sid})
      : assert(name != null),
        assert(enabled != null),
        assert(ordered != null),
        assert(reliable != null),
        assert(maxPacketLifeTime != null),
        assert(maxRetransmits != null),
        assert(sid != null),
        super(name: name, enabled: enabled, ordered: ordered, reliable: reliable, maxPacketLifeTime: maxPacketLifeTime, maxRetransmits: maxRetransmits);

  factory RemoteDataTrackModel.fromEventChannelMap(Map<String, dynamic> map) {
    final dataTrack = DataTrackModel.fromEventChannelMap(map);
    return RemoteDataTrackModel(
        name: dataTrack.name, enabled: dataTrack.enabled, ordered: dataTrack.ordered, reliable: dataTrack.reliable, maxPacketLifeTime: dataTrack.maxPacketLifeTime, maxRetransmits: dataTrack.maxRetransmits, sid: map['sid']);
  }

  @override
  String toString() {
    return '{ name: $name, enabled: $enabled, sid: $sid }';
  }
}
