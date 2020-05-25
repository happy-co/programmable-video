import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a LocalAudioTrackPublication.
class LocalAudioTrackPublicationModel {
  final String sid;
  final TrackModel localAudioTrack;

  const LocalAudioTrackPublicationModel({@required this.sid, @required this.localAudioTrack})
      : assert(sid != null),
        assert(localAudioTrack != null);

  factory LocalAudioTrackPublicationModel.fromEventChannelMap(Map<String, dynamic> map) {
    if (map['localAudioTrack'] == null) {
      return LocalAudioTrackPublicationModel(sid: map['sid'], localAudioTrack: null);
    }
    return LocalAudioTrackPublicationModel(sid: map['sid'], localAudioTrack: TrackModel.fromEventChannelMap(Map<String, dynamic>.from(map['localAudioTrack'])));
  }

  @override
  String toString() {
    return '{ sid: $sid, localAudioTrack: $localAudioTrack }';
  }
}
