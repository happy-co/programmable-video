import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';
import 'package:twilio_programmable_video_example/conference/participant_widget.dart';
import 'package:twilio_programmable_video_example/debug.dart';
import 'package:uuid/uuid.dart';

class ConferenceRoom with ChangeNotifier {
  final String name;
  final String token;
  final String identity;

  final StreamController<bool> _onAudioEnabledStreamController = StreamController<bool>.broadcast();
  late Stream<bool> onAudioEnabled;
  final StreamController<bool> _onVideoEnabledStreamController = StreamController<bool>.broadcast();
  late Stream<bool> onVideoEnabled;
  final StreamController<Map<String, bool>> _flashStateStreamController = StreamController<Map<String, bool>>.broadcast();
  late Stream<Map<String, bool>> flashStateStream;
  final StreamController<Exception> _onExceptionStreamController = StreamController<Exception>.broadcast();
  late Stream<Exception> onException;
  final StreamController<NetworkQualityLevel> _onNetworkQualityStreamController = StreamController<NetworkQualityLevel>.broadcast();
  late Stream<NetworkQualityLevel> onNetworkQualityLevel;

  final Completer<Room> _completer = Completer<Room>();

  final List<ParticipantWidget> _participants = [];
  final List<ParticipantBuffer> _participantBuffer = [];
  final List<StreamSubscription> _streamSubscriptions = [];
  final List<RemoteDataTrack> _dataTracks = [];
  final List<String> _messages = [];

  late CameraCapturer _cameraCapturer;
  late Room _room;
  late Timer _timer;

  bool flashEnabled = false;
  var trackId;

  ConferenceRoom({
    required this.name,
    required this.token,
    required this.identity,
  }) {
    onAudioEnabled = _onAudioEnabledStreamController.stream;
    onVideoEnabled = _onVideoEnabledStreamController.stream;
    flashStateStream = _flashStateStreamController.stream;
    onException = _onExceptionStreamController.stream;
    onNetworkQualityLevel = _onNetworkQualityStreamController.stream;
  }

  List<ParticipantWidget> get participants {
    return [..._participants];
  }

  Future<Room> connect() async {
    Debug.log('ConferenceRoom.connect()');
    try {
      await TwilioProgrammableVideo.debug(dart: true, native: true);
      await TwilioProgrammableVideo.setSpeakerphoneOn(true);

      _cameraCapturer = CameraCapturer(CameraSource.FRONT_CAMERA);
      trackId = Uuid().v4();

      var connectOptions = ConnectOptions(
        token,
        roomName: name,
        preferredAudioCodecs: [OpusCodec()],
        audioTracks: [LocalAudioTrack(true, 'audio_track-$trackId')],
        dataTracks: [
          LocalDataTrack(
            DataTrackOptions(name: 'data_track-$trackId'),
          )
        ],
        videoTracks: [LocalVideoTrack(true, _cameraCapturer)],
        enableNetworkQuality: true,
        networkQualityConfiguration: NetworkQualityConfiguration(
          remote: NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_MINIMAL,
        ),
        enableDominantSpeaker: true,
      );

      _room = await TwilioProgrammableVideo.connect(connectOptions);

      _streamSubscriptions.add(_room.onConnected.listen(_onConnected));
      _streamSubscriptions.add(_room.onDisconnected.listen(_onDisconnected));
      _streamSubscriptions.add(_room.onReconnecting.listen(_onReconnecting));
      _streamSubscriptions.add(_room.onConnectFailure.listen(_onConnectFailure));
      _streamSubscriptions.add(_cameraCapturer.onCameraSwitched!.listen(_onCameraSwitched));

      await _updateFlashState();

      return _completer.future;
    } catch (err) {
      Debug.log(err);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    Debug.log('ConferenceRoom.disconnect()');
    _timer.cancel();
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
    await _flashStateStreamController.close();
    await _onExceptionStreamController.close();
    await _onNetworkQualityStreamController.close();
    for (var streamSubscription in _streamSubscriptions) {
      await streamSubscription.cancel();
    }
  }

  Future<List<StatsReport>?> getStats() async {
    return await TwilioProgrammableVideo.getStats();
  }

  Future<void> sendMessage(String message) async {
    final tracks = _room.localParticipant?.localDataTracks ?? [];
    final localDataTrack = tracks.isEmpty ? null : tracks[0].localDataTrack;
    if (localDataTrack == null || _messages.isNotEmpty) {
      Debug.log('ConferenceRoom.sendMessage => Track is not available yet, buffering message.');
      _messages.add(message);
      return;
    }
    await localDataTrack.send(message);
  }

  Future<void> sendBufferMessage(ByteBuffer message) async {
    final tracks = _room.localParticipant?.localDataTracks ?? [];
    final localDataTrack = tracks.isEmpty ? null : tracks[0].localDataTrack;
    if (localDataTrack == null) {
      return;
    }
    await localDataTrack.sendBuffer(message);
  }

  Future<void> toggleVideoEnabled() async {
    final tracks = _room.localParticipant?.localVideoTracks ?? [];
    final localVideoTrack = tracks.isEmpty ? null : tracks[0].localVideoTrack;
    if (localVideoTrack == null) {
      Debug.log('ConferenceRoom.toggleVideoEnabled() => Track is not available yet!');
      return;
    }
    await localVideoTrack.enable(!localVideoTrack.isEnabled);

    var index = _participants.indexWhere((ParticipantWidget participant) => !participant.isRemote);
    if (index < 0) {
      return;
    }
    _participants[index] = _participants[index].copyWith(videoEnabled: localVideoTrack.isEnabled);
    Debug.log('ConferenceRoom.toggleVideoEnabled() => ${localVideoTrack.isEnabled}');
    _onVideoEnabledStreamController.add(localVideoTrack.isEnabled);
    notifyListeners();
  }

  Future<void> toggleMute(RemoteParticipant remoteParticipant) async {
    final enabled = await remoteParticipant.remoteAudioTracks.first.remoteAudioTrack!.isPlaybackEnabled();
    remoteParticipant.remoteAudioTracks.forEach((remoteAudioTrackPublication) async {
      final remoteAudioTrack = remoteAudioTrackPublication.remoteAudioTrack;
      if (remoteAudioTrack != null && enabled != null) {
        await remoteAudioTrack.enablePlayback(!enabled);
      }
    });

    var index = _participants.indexWhere((ParticipantWidget participant) => participant.id == remoteParticipant.sid);
    if (index < 0) {
      return;
    }
    _participants[index] = _participants[index].copyWith(audioEnabledLocally: !enabled!);
    notifyListeners();
  }

  Future<void> toggleAudioEnabled() async {
    final tracks = _room.localParticipant?.localAudioTracks ?? [];
    final localAudioTrack = tracks.isEmpty ? null : tracks[0].localAudioTrack;
    if (localAudioTrack == null) {
      Debug.log('ConferenceRoom.toggleAudioEnabled() => Track is not available yet!');
      return;
    }
    await localAudioTrack.enable(!localAudioTrack.isEnabled);

    var index = _participants.indexWhere((ParticipantWidget participant) => !participant.isRemote);
    if (index < 0) {
      return;
    }
    _participants[index] = _participants[index].copyWith(audioEnabled: localAudioTrack.isEnabled);
    Debug.log('ConferenceRoom.toggleAudioEnabled() => ${localAudioTrack.isEnabled}');
    _onAudioEnabledStreamController.add(localAudioTrack.isEnabled);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    Debug.log('ConferenceRoom.switchCamera()');
    try {
      await _cameraCapturer.switchCamera();
    } on FormatException catch (e) {
      Debug.log(
        'ConferenceRoom.switchCamera() failed because of FormatException with message: ${e.message}',
      );
    }
  }

  Future<void> toggleFlashlight() async {
    await _cameraCapturer.setTorch(!flashEnabled);
    flashEnabled = !flashEnabled;
    await _updateFlashState();
  }

  void addDummy({required Widget child}) {
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
        isRemote: true,
        audioEnabled: true,
        videoEnabled: true,
        isDummy: true,
        child: child,
      ),
    );
    notifyListeners();
  }

  void removeDummy() {
    Debug.log('ConferenceRoom.removeDummy()');
    var dummy = _participants.firstWhereOrNull((participant) => participant.isDummy);
    if (dummy != null) {
      _participants.remove(dummy);
      notifyListeners();
    }
  }

  void _onDisconnected(RoomDisconnectedEvent event) {
    Debug.log('ConferenceRoom._onDisconnected');
    _timer.cancel();
  }

  void _onReconnecting(RoomReconnectingEvent room) {
    Debug.log('ConferenceRoom._onReconnecting');
    _timer.cancel();
  }

  void _onConnected(Room room) {
    Debug.log('ConferenceRoom._onConnected => state: ${room.state}');

    // When connected for the first time, add remote participant listeners
    _streamSubscriptions.add(_room.onParticipantConnected.listen(_onParticipantConnected));
    _streamSubscriptions.add(_room.onParticipantDisconnected.listen(_onParticipantDisconnected));
    _streamSubscriptions.add(_room.onDominantSpeakerChange.listen(_onDominantSpeakerChanged));

    final localParticipant = room.localParticipant;
    if (localParticipant == null) {
      Debug.log('ConferenceRoom._onConnected => localParticipant is null');
      return;
    }

    // Only add ourselves when connected for the first time too.
    _participants.add(
      _buildParticipant(
          child: localParticipant.localVideoTracks[0].localVideoTrack.widget(),
          id: identity,
          audioEnabled: true,
          videoEnabled: true,
          networkQualityLevel: localParticipant.networkQualityLevel,
          onNetworkQualityChanged: localParticipant.onNetworkQualityLevelChanged),
    );

    for (final remoteParticipant in room.remoteParticipants) {
      var participant = _participants.firstWhereOrNull((participant) => participant.id == remoteParticipant.sid);
      if (participant == null) {
        Debug.log('Adding participant that was already present in the room ${remoteParticipant.sid}, before I connected');
        _addRemoteParticipantListeners(remoteParticipant);
      }
    }

    // We have to listen for the [onDataTrackPublished] event on the [LocalParticipant] in
    // order to be able to use the [send] method.
    _streamSubscriptions.add(localParticipant.onDataTrackPublished.listen(_onLocalDataTrackPublished));
    notifyListeners();
    _completer.complete(room);

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Let's see if we can send some data over the DataTrack API
      sendMessage('And another minute has passed since I connected...');
      // Also try the ByteBuffer way of sending data
      final list = 'This data has been sent over the ByteBuffer channel of the DataTrack API'.codeUnits;
      var bytes = Uint8List.fromList(list);
      sendBufferMessage(bytes.buffer);
    });
  }

  void _onLocalDataTrackPublished(LocalDataTrackPublishedEvent event) {
    // Send buffered messages, if any...
    while (_messages.isNotEmpty) {
      var message = _messages.removeAt(0);
      Debug.log('Sending buffered message: $message');
      event.localDataTrackPublication.localDataTrack!.send(message);
    }
  }

  void _onConnectFailure(RoomConnectFailureEvent event) {
    Debug.log('ConferenceRoom._onConnectFailure: ${event.exception}');
    _completer.completeError(event.exception ?? TwilioException(TwilioException.unknownException, 'An unknown connection failure occurred.'));
  }

  void _onDominantSpeakerChanged(DominantSpeakerChangedEvent event) {
    Debug.log('ConferenceRoom._onDominantSpeakerChanged: ${event.remoteParticipant?.identity}');
    var oldDominantParticipantIndex = _participants.indexWhere((p) => p.isDominant);
    if (oldDominantParticipantIndex >= 0) {
      _participants[oldDominantParticipantIndex] = _participants[oldDominantParticipantIndex].copyWith(isDominant: false);
    }

    var newDominantParticipantIndex = _participants.indexWhere((p) => p.id == event.remoteParticipant?.sid);
    _participants[newDominantParticipantIndex] = _participants[newDominantParticipantIndex].copyWith(isDominant: true);
    notifyListeners();
  }

  void _onParticipantConnected(RoomParticipantConnectedEvent event) {
    Debug.log('ConferenceRoom._onParticipantConnected, ${event.remoteParticipant.sid}');
    _addRemoteParticipantListeners(event.remoteParticipant);
  }

  void _onParticipantDisconnected(RoomParticipantDisconnectedEvent event) {
    Debug.log('ConferenceRoom._onParticipantDisconnected: ${event.remoteParticipant.sid}');
    _participants.removeWhere((ParticipantWidget p) => p.id == event.remoteParticipant.sid);
    notifyListeners();
  }

  Future _onCameraSwitched(CameraSwitchedEvent event) async {
    flashEnabled = false;
    await _updateFlashState();
  }

  Future _updateFlashState() async {
    var flashState = <String, bool>{
      'hasFlash': await _cameraCapturer.hasTorch(),
      'flashEnabled': flashEnabled,
    };
    _flashStateStreamController.add(flashState);
  }

  ParticipantWidget _buildParticipant({
    required Widget child,
    required String? id,
    required bool audioEnabled,
    required bool videoEnabled,
    required NetworkQualityLevel networkQualityLevel,
    required Stream<NetworkQualityLevelChangedEvent> onNetworkQualityChanged,
    RemoteParticipant? remoteParticipant,
  }) {
    return ParticipantWidget(
      id: remoteParticipant?.sid,
      isRemote: remoteParticipant != null,
      audioEnabled: audioEnabled,
      videoEnabled: videoEnabled,
      networkQualityLevel: networkQualityLevel,
      onNetworkQualityChanged: onNetworkQualityChanged,
      toggleMute: () => toggleMute(remoteParticipant!),
      child: child,
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

    _streamSubscriptions.add(remoteParticipant.onDataTrackPublished.listen(_onDataTrackPublished));
    _streamSubscriptions.add(remoteParticipant.onDataTrackSubscribed.listen(_onDataTrackSubscribed));
    _streamSubscriptions.add(remoteParticipant.onDataTrackSubscriptionFailed.listen(_onDataTrackSubscriptionFailed));
    _streamSubscriptions.add(remoteParticipant.onDataTrackUnpublished.listen(_onDataTrackUnpublished));
    _streamSubscriptions.add(remoteParticipant.onDataTrackUnsubscribed.listen(_onDataTrackUnsubscribed));

    _streamSubscriptions.add(remoteParticipant.onNetworkQualityLevelChanged.listen(_onNetworkQualityChanged));

    _streamSubscriptions.add(remoteParticipant.onVideoTrackDisabled.listen(_onVideoTrackDisabled));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackEnabled.listen(_onVideoTrackEnabled));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackPublished.listen(_onVideoTrackPublished));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackSubscribed.listen(_onVideoTrackSubscribed));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackSubscriptionFailed.listen(_onVideoTrackSubscriptionFailed));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackUnpublished.listen(_onVideoTrackUnpublished));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackUnsubscribed.listen(_onVideoTrackUnsubscribed));
  }

  void _onAudioTrackDisabled(RemoteAudioTrackEvent event) {
    Debug.log('ConferenceRoom._onAudioTrackDisabled(), ${event.remoteParticipant.sid}, ${event.remoteAudioTrackPublication.trackSid}, isEnabled: ${event.remoteAudioTrackPublication.isTrackEnabled}');
    _setRemoteAudioEnabled(event);
  }

  void _onAudioTrackEnabled(RemoteAudioTrackEvent event) {
    Debug.log('ConferenceRoom._onAudioTrackEnabled(), ${event.remoteParticipant.sid}, ${event.remoteAudioTrackPublication.trackSid}, isEnabled: ${event.remoteAudioTrackPublication.isTrackEnabled}');
    _setRemoteAudioEnabled(event);
  }

  void _onAudioTrackPublished(RemoteAudioTrackEvent event) {
    Debug.log('ConferenceRoom._onAudioTrackPublished(), ${event.remoteParticipant.sid}}');
  }

  void _onAudioTrackSubscribed(RemoteAudioTrackSubscriptionEvent event) {
    Debug.log('ConferenceRoom._onAudioTrackSubscribed(), ${event.remoteParticipant.sid}, ${event.remoteAudioTrackPublication.trackSid}');
    _addOrUpdateParticipant(event);
  }

  void _onAudioTrackSubscriptionFailed(RemoteAudioTrackSubscriptionFailedEvent event) {
    Debug.log('ConferenceRoom._onAudioTrackSubscriptionFailed(), ${event.remoteParticipant.sid}, ${event.remoteAudioTrackPublication.trackSid}');
    _onExceptionStreamController.add(
      PlatformException(
        code: 'ConferenceRoom.audioTrackSubscriptionFailed',
        message: 'AudioTrack Subscription Failed',
        details: event.exception.toString(),
      ),
    );
  }

  void _onAudioTrackUnpublished(RemoteAudioTrackEvent event) {
    Debug.log('ConferenceRoom._onAudioTrackUnpublished(), ${event.remoteParticipant.sid}, ${event.remoteAudioTrackPublication.trackSid}');
  }

  void _onAudioTrackUnsubscribed(RemoteAudioTrackSubscriptionEvent event) {
    Debug.log('ConferenceRoom._onAudioTrackUnsubscribed(), ${event.remoteParticipant.sid}, ${event.remoteAudioTrack.sid}');
  }

  void _onDataTrackPublished(RemoteDataTrackEvent event) {
    Debug.log('ConferenceRoom._onDataTrackPublished(), ${event.remoteParticipant.sid}}');
  }

  void _onDataTrackSubscribed(RemoteDataTrackSubscriptionEvent event) {
    Debug.log('ConferenceRoom._onDataTrackSubscribed(), ${event.remoteParticipant.sid}, ${event.remoteDataTrackPublication.trackSid}');
    final dataTrack = event.remoteDataTrackPublication.remoteDataTrack;
    if (dataTrack == null) {
      Debug.log('ConferenceRoom._onDataTrackSubscribed() => dataTrack == null');
      return;
    }
    _dataTracks.add(dataTrack);
    _streamSubscriptions.add(dataTrack.onMessage.listen(_onMessage));
    _streamSubscriptions.add(dataTrack.onBufferMessage.listen(_onBufferMessage));
  }

  void _onDataTrackSubscriptionFailed(RemoteDataTrackSubscriptionFailedEvent event) {
    Debug.log('ConferenceRoom._onDataTrackSubscriptionFailed(), ${event.remoteParticipant.sid}, ${event.remoteDataTrackPublication.trackSid}');
    _onExceptionStreamController.add(
      PlatformException(
        code: 'ConferenceRoom.dataTrackSubscriptionFailed',
        message: 'DataTrack Subscription Failed',
        details: event.exception.toString(),
      ),
    );
  }

  void _onDataTrackUnpublished(RemoteDataTrackEvent event) {
    Debug.log('ConferenceRoom._onDataTrackUnpublished(), ${event.remoteParticipant.sid}, ${event.remoteDataTrackPublication.trackSid}');
  }

  void _onDataTrackUnsubscribed(RemoteDataTrackSubscriptionEvent event) {
    Debug.log('ConferenceRoom._onDataTrackUnsubscribed(), ${event.remoteParticipant.sid}, ${event.remoteDataTrack.sid}');
  }

  void _onNetworkQualityChanged(RemoteNetworkQualityLevelChangedEvent event) {
    Debug.log('ConferenceRoom._onNetworkQualityChanged(), ${event.remoteParticipant.sid}, ${event.networkQualityLevel}');
  }

  void _onVideoTrackDisabled(RemoteVideoTrackEvent event) {
    Debug.log('ConferenceRoom._onVideoTrackDisabled(), ${event.remoteParticipant.sid}, ${event.remoteVideoTrackPublication.trackSid}, isEnabled: ${event.remoteVideoTrackPublication.isTrackEnabled}');
    _setRemoteVideoEnabled(event);
  }

  void _onVideoTrackEnabled(RemoteVideoTrackEvent event) {
    Debug.log('ConferenceRoom._onVideoTrackEnabled(), ${event.remoteParticipant.sid}, ${event.remoteVideoTrackPublication.trackSid}, isEnabled: ${event.remoteVideoTrackPublication.isTrackEnabled}');
    _setRemoteVideoEnabled(event);
  }

  void _onVideoTrackPublished(RemoteVideoTrackEvent event) {
    Debug.log('ConferenceRoom._onVideoTrackPublished(), ${event.remoteParticipant.sid}, ${event.remoteVideoTrackPublication.trackSid}');
  }

  void _onVideoTrackSubscribed(RemoteVideoTrackSubscriptionEvent event) {
    Debug.log('ConferenceRoom._onVideoTrackSubscribed(), ${event.remoteParticipant.sid}, ${event.remoteVideoTrack.sid}');
    _addOrUpdateParticipant(event);
  }

  void _onVideoTrackSubscriptionFailed(RemoteVideoTrackSubscriptionFailedEvent event) {
    Debug.log('ConferenceRoom._onVideoTrackSubscriptionFailed(), ${event.remoteParticipant.sid}, ${event.remoteVideoTrackPublication.trackSid}');
    _onExceptionStreamController.add(
      PlatformException(
        code: 'ConferenceRoom.videoTrackSubscriptionFailed',
        message: 'VideoTrack Subscription Failed',
        details: event.exception.toString(),
      ),
    );
  }

  void _onVideoTrackUnpublished(RemoteVideoTrackEvent event) {
    Debug.log('ConferenceRoom._onVideoTrackUnpublished(), ${event.remoteParticipant.sid}, ${event.remoteVideoTrackPublication.trackSid}');
  }

  void _onVideoTrackUnsubscribed(RemoteVideoTrackSubscriptionEvent event) {
    Debug.log('ConferenceRoom._onVideoTrackUnsubscribed(), ${event.remoteParticipant.sid}, ${event.remoteVideoTrack.sid}');
  }

  void _onMessage(RemoteDataTrackStringMessageEvent event) {
    Debug.log('onMessage => ${event.remoteDataTrack.sid}, ${event.message}');
  }

  void _onBufferMessage(RemoteDataTrackBufferMessageEvent event) {
    Debug.log('onBufferMessage => ${event.remoteDataTrack.sid}, ${String.fromCharCodes(event.message.asUint8List())}');
  }

  void _setRemoteAudioEnabled(RemoteAudioTrackEvent event) {
    var index = _participants.indexWhere((ParticipantWidget participant) => participant.id == event.remoteParticipant.sid);
    if (index < 0) {
      return;
    }
    _participants[index] = _participants[index].copyWith(audioEnabled: event.remoteAudioTrackPublication.isTrackEnabled);
    notifyListeners();
  }

  void _setRemoteVideoEnabled(RemoteVideoTrackEvent event) {
    var index = _participants.indexWhere((ParticipantWidget participant) => participant.id == event.remoteParticipant.sid);
    if (index < 0) {
      return;
    }
    _participants[index] = _participants[index].copyWith(videoEnabled: event.remoteVideoTrackPublication.isTrackEnabled);
    notifyListeners();
  }

  void _addOrUpdateParticipant(RemoteParticipantEvent event) {
    Debug.log('ConferenceRoom._addOrUpdateParticipant(), ${event.remoteParticipant.sid}');
    final participant = _participants.firstWhereOrNull(
      (ParticipantWidget participant) => participant.id == event.remoteParticipant.sid,
    );
    if (participant != null) {
      Debug.log('Participant found: ${participant.id}, updating A/V enabled values');
      _setRemoteVideoEnabled(event as RemoteVideoTrackEvent);
      _setRemoteAudioEnabled(event as RemoteAudioTrackEvent);
    } else {
      final bufferedParticipant = _participantBuffer.firstWhereOrNull(
        (ParticipantBuffer participant) => participant.id == event.remoteParticipant.sid,
      );
      if (bufferedParticipant != null) {
        _participantBuffer.remove(bufferedParticipant);
      } else if (event is RemoteAudioTrackEvent) {
        Debug.log('Audio subscription came first, waiting for the video subscription...');
        _participantBuffer.add(
          ParticipantBuffer(
            id: event.remoteParticipant.sid,
            audioEnabled: event.remoteAudioTrackPublication.remoteAudioTrack?.isEnabled ?? true,
          ),
        );
        return;
      }
      if (event is RemoteVideoTrackSubscriptionEvent) {
        Debug.log('New participant, adding: ${event.remoteParticipant.sid}');
        _participants.insert(
          0,
          _buildParticipant(
            child: event.remoteVideoTrack.widget(),
            id: event.remoteParticipant.sid,
            remoteParticipant: event.remoteParticipant,
            audioEnabled: bufferedParticipant?.audioEnabled ?? true,
            videoEnabled: event.remoteVideoTrackPublication.remoteVideoTrack?.isEnabled ?? true,
            networkQualityLevel: event.remoteParticipant.networkQualityLevel,
            onNetworkQualityChanged: event.remoteParticipant.onNetworkQualityLevelChanged,
          ),
        );
      }
      notifyListeners();
    }
  }
}
