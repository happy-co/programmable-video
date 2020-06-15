import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a RemoteDataTrackPublication.
class RemoteDataTrackPublicationModel {
  final bool subscribed;
  final bool enabled;
  final String sid;
  final String name;

  final RemoteDataTrackModel remoteDataTrack;

  const RemoteDataTrackPublicationModel({
    this.subscribed,
    this.enabled,
    @required this.sid,
    @required this.name,
    @required this.remoteDataTrack,
  })  : assert(sid != null),
        assert(name != null);

  factory RemoteDataTrackPublicationModel.fromEventChannelMap(Map<String, dynamic> map) {
    RemoteDataTrackModel remoteDataTrack;
    if (map['remoteDataTrack'] != null) {
      remoteDataTrack = RemoteDataTrackModel.fromEventChannelMap(Map<String, dynamic>.from(map['remoteDataTrack']));
    }

    return RemoteDataTrackPublicationModel(
      sid: map['sid'],
      name: map['name'],
      enabled: map['enabled'],
      subscribed: map['subscribed'],
      remoteDataTrack: remoteDataTrack,
    );
  }

  @override
  String toString() {
    return '{ subscribed: $subscribed, enabled: $enabled, sid: $sid, name: $name, remoteDataTrack: $remoteDataTrack }';
  }
}
