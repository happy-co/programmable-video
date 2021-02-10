import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a RemoteAudioTrackPublication.
class RemoteAudioTrackPublicationModel {
  final bool subscribed;
  final bool enabled;
  final String sid;
  final String name;

  final RemoteAudioTrackModel remoteAudioTrack;

  const RemoteAudioTrackPublicationModel({
    this.subscribed,
    this.enabled,
    @required this.sid,
    @required this.name,
    @required this.remoteAudioTrack,
  })  : assert(sid != null),
        assert(name != null);

  factory RemoteAudioTrackPublicationModel.fromEventChannelMap(Map<String, dynamic> map) {
    RemoteAudioTrackModel remoteAudioTrack;
    if (map['remoteAudioTrack'] != null) {
      remoteAudioTrack = RemoteAudioTrackModel.fromEventChannelMap(Map<String, dynamic>.from(map['remoteAudioTrack']));
    }

    return RemoteAudioTrackPublicationModel(
      sid: map['sid'],
      name: map['name'],
      enabled: map['enabled'],
      subscribed: map['subscribed'],
      remoteAudioTrack: remoteAudioTrack,
    );
  }

  @override
  String toString() {
    return '{ subscribed: $subscribed, enabled: $enabled, sid: $sid, name: $name, remoteAudioTrack: $remoteAudioTrack }';
  }
}
