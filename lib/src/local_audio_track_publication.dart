import 'package:twilio_unofficial_programmable_video/src/audio_track.dart';
import 'package:twilio_unofficial_programmable_video/src/audio_track_publication.dart';
import 'package:twilio_unofficial_programmable_video/src/local_audio_track.dart';

class LocalAudioTrackPublication implements AudioTrackPublication {
  final String _sid;

  LocalAudioTrack _localAudioTrack;

  /// The SID of the local audio track.
  @override
  String get trackSid {
    return _sid;
  }

  /// The name of the local audio track.
  @override
  String get trackName {
    return _localAudioTrack.name;
  }

  /// Returns `true` if the published audio track is enabled or `false` otherwise.
  @override
  bool get isTrackEnabled {
    return _localAudioTrack.isEnabled;
  }

  /// The local audio track.
  LocalAudioTrack get localAudioTrack {
    return _localAudioTrack;
  }

  /// The base audio track of the published local audio track.
  @override
  AudioTrack get audioTrack {
    return _localAudioTrack;
  }

  LocalAudioTrackPublication(this._sid) : assert(_sid != null);

  factory LocalAudioTrackPublication.fromMap(Map<String, dynamic> map) {
    var localAudioTrackPublication = LocalAudioTrackPublication(map['sid']);
    localAudioTrackPublication.updateFromMap(map);
    return localAudioTrackPublication;
  }

  void updateFromMap(Map<String, dynamic> map) {
    if (map['localAudioTrack'] != null) {
      final localAudioTrackMap = Map<String, dynamic>.from(map['localAudioTrack']);
      if (_localAudioTrack == null) {
        _localAudioTrack = LocalAudioTrack.fromMap(localAudioTrackMap);
      } else {
        _localAudioTrack.updateFromMap(localAudioTrackMap);
      }
    }
  }
}
