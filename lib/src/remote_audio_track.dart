import 'package:twilio_unofficial_programmable_video/src/audio_track.dart';

/// A remote audio track represents a remote audio source.
class RemoteAudioTrack extends AudioTrack {
  final String _sid;

  /// Returns the server identifier. This value uniquely identifies the remote audio track within the scope of a [Room].
  String get sid {
    return _sid;
  }

  RemoteAudioTrack(this._sid, _enabled, _name)
      : assert(_sid != null),
        super(_enabled, _name);

  factory RemoteAudioTrack.fromMap(Map<String, dynamic> map) {
    return map != null ? RemoteAudioTrack(map['sid'], map['enabled'], map['name']) : null;
  }
}
