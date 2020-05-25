import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a LocalDataTrackPublication.
class LocalDataTrackPublicationModel {
  final String sid;
  final DataTrackModel localDataTrack;

  const LocalDataTrackPublicationModel({@required this.sid, @required this.localDataTrack})
      : assert(sid != null),
        assert(localDataTrack != null);

  factory LocalDataTrackPublicationModel.fromEventChannelMap(Map<String, dynamic> map) {
    if (map['localDataTrack'] == null) {
      return LocalDataTrackPublicationModel(sid: map['sid'], localDataTrack: null);
    }
    return LocalDataTrackPublicationModel(sid: map['sid'], localDataTrack: DataTrackModel.fromEventChannelMap(Map<String, dynamic>.from(map['localDataTrack'])));
  }

  @override
  String toString() {
    return '{ sid: $sid, localDataTrack: $localDataTrack }';
  }
}
