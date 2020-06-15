import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a LocalVideoTrackPublication.
class LocalVideoTrackPublicationModel {
  final String sid;
  final LocalVideoTrackModel localVideoTrack;

  const LocalVideoTrackPublicationModel({
    @required this.sid,
    @required this.localVideoTrack,
  })  : assert(sid != null),
        assert(localVideoTrack != null);

  factory LocalVideoTrackPublicationModel.fromEventChannelMap(Map<String, dynamic> map) {
    assert(map['localVideoTrack'] != null);
    return LocalVideoTrackPublicationModel(
      sid: map['sid'],
      localVideoTrack: LocalVideoTrackModel.fromEventChannelMap(
        Map<String, dynamic>.from(
          map['localVideoTrack'],
        ),
      ),
    );
  }

  @override
  String toString() {
    return '{ sid: $sid, localVideoTrack: $localVideoTrack }';
  }
}
