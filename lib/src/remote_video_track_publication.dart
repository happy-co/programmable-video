import 'package:twilio_unofficial_programmable_video/src/remote_participant.dart';
import 'package:twilio_unofficial_programmable_video/src/remote_video_track.dart';
import 'package:twilio_unofficial_programmable_video/src/video_track.dart';
import 'package:twilio_unofficial_programmable_video/src/video_track_publication.dart';

class RemoteVideoTrackPublication implements VideoTrackPublication {
  final String _sid;

  final String _name;

  RemoteVideoTrack _remoteVideoTrack;

  bool _subscribed;

  bool _enabled;

  RemoteParticipant _remoteParticipant;

  /// The SID of the published video track.
  @override
  String get trackSid {
    return _sid;
  }

  /// The name of the published video track.
  @override
  String get trackName {
    return _name;
  }

  /// Returns `true` if the published video track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled {
    return _enabled;
  }

  /// Returns `true` if the published video track is subscribed by the local participant or `false` otherwise.
  bool get isTrackSubscribed {
    return _subscribed;
  }

  /// Returns the published remote video track.
  ///
  /// Will return `null` if the track is not subscribed to.
  RemoteVideoTrack get remoteVideoTrack {
    return _remoteVideoTrack;
  }

  /// The base video track object of the published remote video track.
  ///
  /// Will return `null` if the track is not subscribed to.
  @override
  VideoTrack get videoTrack {
    return _remoteVideoTrack;
  }

  RemoteVideoTrackPublication(this._subscribed, this._enabled, this._sid, this._name, this._remoteParticipant)
      : assert(_sid != null),
        assert(_name != null),
        assert(_remoteParticipant != null);

  factory RemoteVideoTrackPublication.fromMap(Map<String, dynamic> map, RemoteParticipant remoteParticipant) {
    var remoteVideoTrackPublication = RemoteVideoTrackPublication(map['subscribed'], map['enabled'], map['sid'], map['name'], remoteParticipant);
    remoteVideoTrackPublication.updateFromMap(map);
    return remoteVideoTrackPublication;
  }

  void updateFromMap(Map<String, dynamic> map) {
    _subscribed = map['subscribed'];
    _enabled = map['enabled'];

    if (map['remoteVideoTrack'] != null) {
      final remoteVideoTrackMap = Map<String, dynamic>.from(map['remoteVideoTrack']);
      _remoteVideoTrack ??= RemoteVideoTrack.fromMap(remoteVideoTrackMap, _remoteParticipant);
      _remoteVideoTrack.updateFromMap(remoteVideoTrackMap);
    } else {
      _remoteVideoTrack = null;
    }
  }
}
