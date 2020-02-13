import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twilio_unofficial_programmable_video/twilio_unofficial_programmable_video.dart';
import 'package:twilio_unofficial_programmable_video_example/conference/participant_widget.dart';
import 'package:twilio_unofficial_programmable_video_example/debug.dart';

class ConferenceRoom with ChangeNotifier {
  final String name;
  final String token;
  final String identity;

  final StreamController<bool> _onAudioEnabledStreamController = StreamController<bool>.broadcast();
  Stream<bool> onAudioEnabled;
  final StreamController<bool> _onVideoEnabledStreamController = StreamController<bool>.broadcast();
  Stream<bool> onVideoEnabled;
  final StreamController<Exception> _onExceptionStreamController = StreamController<Exception>.broadcast();
  Stream<Exception> onException;

  final Completer<void> _completer = Completer<void>();

  final List<ParticipantWidget> _participants = [];
  final List<ParticipantBuffer> _participantBuffer = [];
  final List<StreamSubscription> _streamSubscriptions = [];

  CameraCapturer _cameraCapturer;
  Room _room;

  ConferenceRoom({
    @required this.name,
    @required this.token,
    @required this.identity,
  }) {
    onAudioEnabled = _onAudioEnabledStreamController.stream;
    onVideoEnabled = _onVideoEnabledStreamController.stream;
    onException = _onExceptionStreamController.stream;
  }

  List<ParticipantWidget> get participants {
    return [..._participants];
  }

  Future<void> connect() async {
    Debug.log('ConferenceRoom.connect()');
    try {
      await TwilioUnofficialProgrammableVideo.debug(dart: true, native: true);
      await TwilioUnofficialProgrammableVideo.setSpeakerphoneOn(true);

      _cameraCapturer = CameraCapturer(CameraSource.FRONT_CAMERA);
      var connectOptions = ConnectOptions(token)
        ..roomName(name)
        ..preferAudioCodecs([OpusCodec()])
        ..audioTracks([LocalAudioTrack(true)])
        ..videoTracks([LocalVideoTrack(true, _cameraCapturer)]);

      _room = await TwilioUnofficialProgrammableVideo.connect(connectOptions);

      _streamSubscriptions.add(_room.onConnected.listen(_onConnected));
      _streamSubscriptions.add(_room.onConnectFailure.listen(_onConnectFailure));

      return _completer.future;
    } catch (err) {
      Debug.log(err);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    Debug.log('ConferenceRoom.disconnect()');
    await _room.disconnect();
  }

  @override
  void dispose() {
    Debug.log('ConferenceRoom.dispose()');
    _disposeStreamsAndSubscriptions();
    super.dispose();
  }

  Future<void> _disposeStreamsAndSubscriptions() async {
    await _onAudioEnabledStreamController.close();
    await _onVideoEnabledStreamController.close();
    await _onExceptionStreamController.close();
    for (var streamSubscription in _streamSubscriptions) {
      await streamSubscription.cancel();
    }
  }

  Future<void> toggleVideoEnabled() async {
    final localVideoTrack = _room.localParticipant.localVideoTracks[0].localVideoTrack;
    await localVideoTrack.enable(!localVideoTrack.isEnabled);

    var index = _participants.indexWhere((ParticipantWidget participant) => !participant.isRemote);
    if (index < 0) {
      return;
    }
    var participant = _participants[index];
    _participants.replaceRange(
      index,
      index + 1,
      [
        participant.copyWith(videoEnabled: localVideoTrack.isEnabled),
      ],
    );
    Debug.log('ConferenceRoom.toggleVideoEnabled() => ${localVideoTrack.isEnabled}');
    _onVideoEnabledStreamController.add(localVideoTrack.isEnabled);
    notifyListeners();
  }

  Future<void> toggleAudioEnabled() async {
    final localAudioTrack = _room.localParticipant.localAudioTracks[0].localAudioTrack;
    await localAudioTrack.enable(!localAudioTrack.isEnabled);

    var index = _participants.indexWhere((ParticipantWidget participant) => !participant.isRemote);
    if (index < 0) {
      return;
    }
    var participant = _participants[index];
    _participants.replaceRange(
      index,
      index + 1,
      [
        participant.copyWith(audioEnabled: localAudioTrack.isEnabled),
      ],
    );
    Debug.log('ConferenceRoom.toggleAudioEnabled() => ${localAudioTrack.isEnabled}');
    _onAudioEnabledStreamController.add(localAudioTrack.isEnabled);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    Debug.log('ConferenceRoom.switchCamera()');
    await _cameraCapturer.switchCamera();
  }

  void addDummy({Widget child}) {
    Debug.log('ConferenceRoom.addDummy()');
    if (_participants.length >= 18) {
      throw PlatformException(
        code: 'ConferenceRoom.maximumReached',
        message: 'Maximum reached',
        details: 'Currently the lay-out can only render a maximum of 18 participants',
      );
    }
    _participants.insert(
      0,
      ParticipantWidget(
        id: (_participants.length + 1).toString(),
        child: child,
        isRemote: true,
        audioEnabled: true,
        videoEnabled: true,
        isDummy: true,
      ),
    );
    notifyListeners();
  }

  void removeDummy() {
    Debug.log('ConferenceRoom.removeDummy()');
    var dummy = _participants.firstWhere((participant) => participant.isDummy, orElse: () => null);
    if (dummy != null) {
      _participants.remove(dummy);
      notifyListeners();
    }
  }

  void _onConnected(RoomEvent roomEvent) {
    Debug.log('ConferenceRoom._onConnected => state: ${roomEvent.room.state}');

    if (roomEvent.room.state == RoomState.CONNECTED) {
      // When connected for the first time, add remote participant listeners
      _streamSubscriptions.add(_room.onParticipantConnected.listen(_onParticipantConnected));
      _streamSubscriptions.add(_room.onParticipantDisconnected.listen(_onParticipantDisconnected));
      // Only add ourselves when connected for the first time too.
      _participants.add(
        _buildParticipant(
          child: roomEvent.room.localParticipant.localVideoTracks[0].localVideoTrack.widget(),
          id: identity,
          audioEnabled: true,
          videoEnabled: true,
        ),
      );
      notifyListeners();
      _completer.complete();
    }
    for (final remoteParticipant in roomEvent.room.remoteParticipants) {
      var participant = _participants.firstWhere((participant) => participant.id == remoteParticipant.sid, orElse: () => null);
      if (participant == null) {
        Debug.log('Adding participant that was already present in the room ${remoteParticipant.sid}, before I connected');
        _addRemoteParticipantListeners(remoteParticipant);
      }
    }
  }

  Future<void> _onConnectFailure(RoomEvent roomEvent) async {
    Debug.log('ConferenceRoom._onConnectFailure: ${roomEvent.exception}');
    _completer.completeError(roomEvent.exception);
  }

  void _onParticipantConnected(RoomEvent roomEvent) {
    Debug.log('ConferenceRoom._onParticipantConnected, ${roomEvent.remoteParticipant.sid}');
    _addRemoteParticipantListeners(roomEvent.remoteParticipant);
  }

  void _onParticipantDisconnected(RoomEvent roomEvent) {
    Debug.log('ConferenceRoom._onParticipantDisconnected: ${roomEvent.remoteParticipant.sid}');
    _participants.removeWhere((ParticipantWidget p) => p.id == roomEvent.remoteParticipant.sid);
    notifyListeners();
  }

  ParticipantWidget _buildParticipant({
    @required Widget child,
    @required String id,
    @required bool audioEnabled,
    @required bool videoEnabled,
    RemoteParticipant remoteParticipant,
  }) {
    return ParticipantWidget(
      id: remoteParticipant?.sid,
      isRemote: remoteParticipant != null,
      child: child,
      audioEnabled: audioEnabled,
      videoEnabled: videoEnabled,
    );
  }

  void _addRemoteParticipantListeners(RemoteParticipant remoteParticipant) {
    Debug.log('ConferenceRoom._addRemoteParticipantListeners() => Adding listeners to remoteParticipant ${remoteParticipant.sid}');
    _streamSubscriptions.add(remoteParticipant.onAudioTrackDisabled.listen(_onAudioTrackDisabled));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackEnabled.listen(_onAudioTrackEnabled));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackPublished.listen(_onAudioTrackPublished));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackSubscribed.listen(_onAudioTrackSubscribed));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackSubscriptionFailed.listen(_onAudioTrackSubscriptionFailed));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackUnpublished.listen(_onAudioTrackUnpublished));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackUnsubscribed.listen(_onAudioTrackUnsubscribed));

    _streamSubscriptions.add(remoteParticipant.onVideoTrackDisabled.listen(_onVideoTrackDisabled));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackEnabled.listen(_onVideoTrackEnabled));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackPublished.listen(_onVideoTrackPublished));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackSubscribed.listen(_onVideoTrackSubscribed));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackSubscriptionFailed.listen(_onVideoTrackSubscriptionFailed));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackUnpublished.listen(_onVideoTrackUnpublished));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackUnsubscribed.listen(_onVideoTrackUnsubscribed));
  }

  void _onAudioTrackDisabled(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onAudioTrackDisabled(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrack.sid}, isEnabled: ${remoteParticipantEvent.remoteAudioTrack.isEnabled}');
    _setRemoteAudioEnabled(remoteParticipantEvent);
  }

  void _onAudioTrackEnabled(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onAudioTrackEnabled(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrack.sid}, isEnabled: ${remoteParticipantEvent.remoteAudioTrack.isEnabled}');
    _setRemoteAudioEnabled(remoteParticipantEvent);
  }

  void _onAudioTrackPublished(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onAudioTrackPublished(), ${remoteParticipantEvent.remoteParticipant.sid}}');
  }

  void _onAudioTrackSubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onAudioTrackSubscribed(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrackPublication.trackSid}');
    _addOrUpdateParticipant(remoteParticipantEvent);
  }

  void _onAudioTrackSubscriptionFailed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onAudioTrackSubscriptionFailed(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrackPublication.trackSid}');
    _onExceptionStreamController.add(
      PlatformException(
        code: 'ConferenceRoom.audioTrackSubscriptionFailed',
        message: 'AudioTrack Subscription Failed',
        details: remoteParticipantEvent.exception.toString(),
      ),
    );
  }

  void _onAudioTrackUnpublished(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onAudioTrackUnpublished(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrackPublication.trackSid}');
  }

  void _onAudioTrackUnsubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onAudioTrackUnsubscribed(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrack.sid}');
  }

  void _onVideoTrackDisabled(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onVideoTrackDisabled(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrack.sid}, isEnabled: ${remoteParticipantEvent.remoteVideoTrack.isEnabled}');
    _setRemoteVideoEnabled(remoteParticipantEvent);
  }

  void _onVideoTrackEnabled(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onVideoTrackEnabled(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrack.sid}, isEnabled: ${remoteParticipantEvent.remoteVideoTrack.isEnabled}');
    _setRemoteVideoEnabled(remoteParticipantEvent);
  }

  void _onVideoTrackPublished(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onVideoTrackPublished(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrackPublication.trackSid}');
  }

  void _onVideoTrackSubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onVideoTrackSubscribed(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrack.sid}');
    _addOrUpdateParticipant(remoteParticipantEvent);
  }

  void _onVideoTrackSubscriptionFailed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onVideoTrackSubscriptionFailed(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrackPublication.trackSid}');
    _onExceptionStreamController.add(
      PlatformException(
        code: 'ConferenceRoom.videoTrackSubscriptionFailed',
        message: 'VideoTrack Subscription Failed',
        details: remoteParticipantEvent.exception.toString(),
      ),
    );
  }

  void _onVideoTrackUnpublished(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onVideoTrackUnpublished(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrackPublication.trackSid}');
  }

  void _onVideoTrackUnsubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._onVideoTrackUnsubscribed(), ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrack.sid}');
  }

  void _setRemoteAudioEnabled(RemoteParticipantEvent remoteParticipantEvent) {
    if (remoteParticipantEvent.remoteAudioTrackPublication == null) {
      return;
    }
    var index = _participants.indexWhere((ParticipantWidget participant) => participant.id == remoteParticipantEvent.remoteParticipant.sid);
    if (index < 0) {
      return;
    }
    var participant = _participants[index];
    _participants.replaceRange(
      index,
      index + 1,
      [
        participant.copyWith(audioEnabled: remoteParticipantEvent.remoteAudioTrackPublication.isTrackEnabled),
      ],
    );
    notifyListeners();
  }

  void _setRemoteVideoEnabled(RemoteParticipantEvent remoteParticipantEvent) {
    if (remoteParticipantEvent.remoteVideoTrackPublication == null) {
      return;
    }
    var index = _participants.indexWhere((ParticipantWidget participant) => participant.id == remoteParticipantEvent.remoteParticipant.sid);
    if (index < 0) {
      return;
    }
    var participant = _participants[index];
    _participants.replaceRange(
      index,
      index + 1,
      [
        participant.copyWith(videoEnabled: remoteParticipantEvent.remoteVideoTrackPublication.isTrackEnabled),
      ],
    );
    notifyListeners();
  }

  void _addOrUpdateParticipant(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('ConferenceRoom._addOrUpdateParticipant(), ${remoteParticipantEvent.remoteParticipant.sid}');
    final participant = _participants.firstWhere(
      (ParticipantWidget participant) => participant.id == remoteParticipantEvent.remoteParticipant.sid,
      orElse: () => null,
    );
    if (participant != null) {
      Debug.log('Participant found: ${participant.id}, updating A/V enabled values');
      _setRemoteVideoEnabled(remoteParticipantEvent);
      _setRemoteAudioEnabled(remoteParticipantEvent);
    } else {
      final bufferedParticipant = _participantBuffer.firstWhere(
        (ParticipantBuffer participant) => participant.id == remoteParticipantEvent.remoteParticipant.sid,
        orElse: () => null,
      );
      if (bufferedParticipant != null) {
        _participantBuffer.remove(bufferedParticipant);
      } else if (remoteParticipantEvent.remoteVideoTrack == null) {
        Debug.log('Audio subscription came first, waiting for the video subscription...');
        _participantBuffer.add(
          ParticipantBuffer(
            id: remoteParticipantEvent.remoteParticipant.sid,
            audioEnabled: remoteParticipantEvent.remoteAudioTrackPublication?.remoteAudioTrack?.isEnabled ?? true,
          ),
        );
        return;
      }
      Debug.log('New participant, adding: ${remoteParticipantEvent.remoteParticipant.sid}');
      _participants.insert(
        0,
        _buildParticipant(
          child: remoteParticipantEvent.remoteVideoTrack.widget(),
          id: remoteParticipantEvent.remoteParticipant.sid,
          remoteParticipant: remoteParticipantEvent.remoteParticipant,
          audioEnabled: remoteParticipantEvent.remoteAudioTrackPublication?.remoteAudioTrack?.isEnabled ?? bufferedParticipant?.audioEnabled ?? true,
          videoEnabled: remoteParticipantEvent.remoteVideoTrackPublication?.remoteVideoTrack?.isEnabled ?? true,
        ),
      );
      notifyListeners();
    }
  }
}
