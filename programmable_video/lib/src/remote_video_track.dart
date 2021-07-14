part of twilio_programmable_video;

/// A remote video track represents a remote video source.
class RemoteVideoTrack extends VideoTrack {
  final String _sid;

  final RemoteParticipant _remoteParticipant;

  /// Returns the server identifier. This value uniquely identifies the remote video track within the scope of a [Room].
  String get sid => _sid;

  RemoteVideoTrack(
    this._sid,
    _enabled,
    _name,
    this._remoteParticipant,
  ) : super(_enabled, _name);

  /// Construct from a [RemoteVideoTrackModel].
  factory RemoteVideoTrack._fromModel(RemoteVideoTrackModel model, RemoteParticipant remoteParticipant) {
    return RemoteVideoTrack(model.sid, model.enabled, model.name, remoteParticipant);
  }

  /// Returns a native widget.
  ///
  /// By default the widget will not be mirrored, to change that set [mirror] to true.
  /// If you provide a [key] make sure it is unique among all [VideoTrack]s otherwise Flutter might send the wrong creation params to the native side.
  Widget widget({bool mirror = false, Key? key}) {
    key ??= ValueKey(_sid);
    final remoteParticipantSid = _remoteParticipant.sid;

    if (remoteParticipantSid == null) {
      throw MissingParameterException(
        code: 'RemoteParticipantSidNotFound',
        message: 'Cannot create widget for VideoTrack sid: $_sid. '
            'Host RemoteParticipant has no SID.',
      );
    }

    return ProgrammableVideoPlatform.instance.createRemoteVideoTrackWidget(
      remoteParticipantSid: remoteParticipantSid,
      remoteVideoTrackSid: _sid,
      mirror: mirror,
      key: key,
    );
  }
}
