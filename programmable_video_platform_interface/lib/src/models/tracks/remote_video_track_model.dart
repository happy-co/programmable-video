import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a RemoteVideoTrack.
class RemoteVideoTrackModel extends TrackModel {
  final String sid;

  const RemoteVideoTrackModel({
    @required String name,
    @required bool enabled,
    @required this.sid,
  })  : assert(name != null),
        assert(enabled != null),
        assert(sid != null),
        super(
          name: name,
          enabled: enabled,
        );

  factory RemoteVideoTrackModel.fromEventChannelMap(Map<String, dynamic> map) {
    return RemoteVideoTrackModel(
      name: map['name'],
      enabled: map['enabled'],
      sid: map['sid'],
    );
  }

  @override
  String toString() {
    return '{ name: $name, enabled: $enabled, sid: $sid }';
  }
}
