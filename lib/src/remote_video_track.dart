part of twilio_unofficial_programmable_video;

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

  /// Construct from a map.
  factory RemoteVideoTrack._fromMap(Map<String, dynamic> map, RemoteParticipant remoteParticipant) {
    return map != null ? RemoteVideoTrack(map['sid'], map['enabled'], map['name'], remoteParticipant) : null;
  }

  /// Returns a native widget.
  ///
  /// By default the widget will not be mirrored, to change that set [mirror] to true.
  /// If you provide a [key] make sure it is unique among all [VideoTrack]s otherwise Flutter might send the wrong creation params to the native side.
  Widget widget({bool mirror = false, Key key}) {
    key ??= ValueKey(_sid);

    var creationParams = {
      'remoteParticipantSid': _remoteParticipant.sid,
      'remoteVideoTrackSid': _sid,
      'mirror': mirror,
    };

    return _widget ??= AndroidView(
      key: key,
      viewType: 'twilio_unofficial_programmable_video/views',
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (int viewId) {
        TwilioUnofficialProgrammableVideo._log('RemoteVideoTrack => View created: $viewId, creationParams: ${creationParams}');
      },
    );
  }
}
