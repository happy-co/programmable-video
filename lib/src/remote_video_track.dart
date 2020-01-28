import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:twilio_unofficial_programmable_video/src/remote_participant.dart';
import 'package:twilio_unofficial_programmable_video/src/video_track.dart';

/// A remote video track represents a remote video source.
class RemoteVideoTrack extends VideoTrack {
  final String _sid;

  final RemoteParticipant _remoteParticipant;

  Widget _widget;

  /// Returns the server identifier. This value uniquely identifies the remote video track within the scope of a [Room].
  String get sid {
    return _sid;
  }

  RemoteVideoTrack(this._sid, _enabled, _name, this._remoteParticipant)
      : assert(_sid != null),
        assert(_remoteParticipant != null),
        super(_enabled, _name);

  factory RemoteVideoTrack.fromMap(Map<String, dynamic> map, RemoteParticipant remoteParticipant) {
    return map != null ? RemoteVideoTrack(map['sid'], map['enabled'], map['name'], remoteParticipant) : null;
  }

  /// Returns a native widget.
  ///
  /// By default the widget will not be mirrored, to change that set [mirror] to true.
  Widget widget({bool mirror = false}) {
    return _widget ??= AndroidView(
      viewType: 'twilio_unofficial_programmable_video/views',
      creationParams: <String, dynamic>{'remoteParticipantSid': _remoteParticipant.sid, 'remoteVideoTrackSid': _sid, 'mirror': mirror},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (int viewId) {
        print('Remote View created => $viewId');
      },
    );
  }
}
