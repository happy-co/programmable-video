import 'package:twilio_unofficial_programmable_video/src/audio_track.dart';
import 'package:twilio_unofficial_programmable_video/src/audio_track_publication.dart';
import 'package:twilio_unofficial_programmable_video/src/remote_audio_track.dart';

class RemoteAudioTrackPublication implements AudioTrackPublication {
  final String _sid;

  final String _name;

  RemoteAudioTrack _remoteAudioTrack;

  bool _subscribed;

  bool _enabled;

  /// The SID of the published audio track.
  @override
  String get trackSid {
    return _sid;
  }

  /// The name of the published audio track.
  @override
  String get trackName {
    return _name;
  }

  /// Returns `true` if the published audio track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled {
    return _enabled;
  }

  /// Returns `true` if the published audio track is subscribed by the local participant or `false` otherwise.
  bool get isTrackSubscribed {
    return _subscribed;
  }

  /// Returns the published remote audio track.
  ///
  /// Will return `null` if the track is not subscribed to.
  RemoteAudioTrack get remoteAudioTrack {
    return _remoteAudioTrack;
  }

  /// The base audio track object of the published remote audio track.
  ///
  /// Will return `null` if the track is not subscribed to.
  @override
  AudioTrack get audioTrack {
    return _remoteAudioTrack;
  }

  RemoteAudioTrackPublication(this._subscribed, this._enabled, this._sid, this._name)
      : assert(_sid != null),
        assert(_name != null);

  factory RemoteAudioTrackPublication.fromMap(Map<String, dynamic> map) {
    var remoteAudioTrackPublication = RemoteAudioTrackPublication(map['subscribed'], map['enabled'], map['sid'], map['name']);
    remoteAudioTrackPublication.updateFromMap(map);
    return remoteAudioTrackPublication;
  }

  void updateFromMap(Map<String, dynamic> map) {
    _subscribed = map['subscribed'];
    _enabled = map['enabled'];

    if (map['remoteAudioTrack'] != null) {
      final remoteAudioTrackMap = Map<String, dynamic>.from(map['remoteAudioTrack']);
      _remoteAudioTrack ??= RemoteAudioTrack.fromMap(remoteAudioTrackMap);
      _remoteAudioTrack.updateFromMap(remoteAudioTrackMap);
    } else {
      _remoteAudioTrack = null;
    }
  }
}
