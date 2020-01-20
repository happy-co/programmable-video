import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:twilio_unofficial_programmable_video/src/remote_participant.dart';

class RemoteVideoTrack {
  final String _sid;

  final RemoteParticipant _remoteParticipant;

  String get sid {
    return _sid;
  }

  RemoteVideoTrack(this._sid, this._remoteParticipant)
      : assert(_sid != null),
        assert(_remoteParticipant != null);

  factory RemoteVideoTrack.fromMap(Map<String, String> map, RemoteParticipant remoteParticipant) {
    return RemoteVideoTrack(map["sid"], remoteParticipant);
  }

  Widget widget() {
    return AndroidView(
      key: ValueKey<String>(_sid),
      viewType: 'twilio_unofficial_programmable_video/views',
      creationParams: <String, String>{'remoteParticipantSid': _remoteParticipant.sid, 'remoteVideoTrackSid': _sid},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (int viewId) {
        print('Remote View created => $viewId');
      },
    );
  }
}
