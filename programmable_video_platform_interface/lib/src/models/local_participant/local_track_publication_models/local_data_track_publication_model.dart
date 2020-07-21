import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a LocalDataTrackPublication.
class LocalDataTrackPublicationModel {
  final String sid;
  final LocalDataTrackModel localDataTrack;

  const LocalDataTrackPublicationModel({
    @required this.sid,
    @required this.localDataTrack,
  })  : assert(sid != null),
        assert(localDataTrack != null);

  factory LocalDataTrackPublicationModel.fromEventChannelMap(Map<String, dynamic> map) {
    assert(map['localDataTrack'] != null);
    return LocalDataTrackPublicationModel(
      sid: map['sid'],
      localDataTrack: LocalDataTrackModel.fromEventChannelMap(
        Map<String, dynamic>.from(
          map['localDataTrack'],
        ),
      ),
    );
  }

  @override
  String toString() {
    return '{ sid: $sid, localDataTrack: $localDataTrack }';
  }
}
