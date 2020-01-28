import 'package:flutter/services.dart';
import 'package:twilio_unofficial_programmable_video/src/audio_track.dart';

class LocalAudioTrack extends AudioTrack {
  bool _enabled;

  /// Check if it is enabled.
  ///
  /// When the value is `false`, the local audio track is muted. When the value is `true` the local audio track is live.
  @override
  bool get isEnabled {
    return _enabled;
  }

  LocalAudioTrack(this._enabled, {String name = ''}) : super(_enabled, name);

  factory LocalAudioTrack.fromMap(Map<String, dynamic> map) {
    var localAudioTrack = LocalAudioTrack(map['enabled'], name: map['name']);
    localAudioTrack.updateFromMap(map);
    return localAudioTrack;
  }

  /// Set the state.
  ///
  /// The results of this operation are signaled to other [Particpant]s in the same [Room].
  Future<bool> enable(bool enabled) async {
    _enabled = enabled;
    return const MethodChannel('twilio_unofficial_programmable_video').invokeMethod('LocalAudioTrack#enable', <String, dynamic>{'name': name, 'enable': enabled});
  }

  Map<String, Object> toMap() {
    return <String, Object>{'enable': isEnabled, 'name': name};
  }
}
