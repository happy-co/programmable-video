part of twilio_programmable_video;

/// A [Room] represents a media session with zero or more remote participants. Media shared by any one [RemoteParticipant] is distributed equally to all other participants.
class Room {
  final int _internalId;

  /// Stream for the native room events.
  late StreamSubscription<BaseRoomEvent> _roomStream;

  /// Stream for the native remote participant events.
  late StreamSubscription<BaseRemoteParticipantEvent> _remoteParticipantStream;

  /// Stream for the native local participant events.
  late StreamSubscription<BaseLocalParticipantEvent> _localParticipantStream;

  /// Stream for the native remote data track events.
  late StreamSubscription<BaseRemoteDataTrackEvent> _remoteDataTrackStream;

  String? _sid;

  String? _name;

  Region? _mediaRegion;

  RoomState? _state;

  LocalParticipant? _localParticipant;

  RemoteParticipant? _dominantSpeaker;

  final List<RemoteParticipant> _remoteParticipants = [];

  /// Map of buffered events for remote participants.
  final Map<String, List<dynamic>> _remoteParticipantsEventBuffer = {};

  /// The SID of this [Room].
  String? get sid => _sid;

  /// The name of this [Room].
  String? get name => _name;

  /// The region where media is processed.
  ///
  /// This property is set in Group Rooms by the time the [Room] reaches [RoomState.CONNECTED].
  /// It can be `null` under the following conditions:
  /// * The [Room] has not reached the [RoomState.CONNECTED] state.
  /// * The instance represents a peer-to-peer room.
  Region? get mediaRegion => _mediaRegion;

  /// The current room state.
  RoomState? get state => _state;

  /// The current local participant.
  ///
  /// If the room has not reached [RoomState.CONNECTED] then it will be `null`.
  LocalParticipant? get localParticipant => _localParticipant;

  /// All currently connected participants.
  List<RemoteParticipant> get remoteParticipants => <RemoteParticipant>[..._remoteParticipants];

  /// The remote participant with the loudest audio track.
  RemoteParticipant? get dominantSpeaker => _dominantSpeaker;

  final StreamController<DominantSpeakerChangedEvent> _onDominantSpeakerChange = StreamController<DominantSpeakerChangedEvent>.broadcast();

  /// Called when the participant with the loudest audio track changes.
  late Stream<DominantSpeakerChangedEvent> onDominantSpeakerChange;

  final StreamController<RoomConnectFailureEvent> _onConnectFailure = StreamController<RoomConnectFailureEvent>.broadcast();

  /// Called when a connection to a room failed.
  late Stream<RoomConnectFailureEvent> onConnectFailure;

  final StreamController<Room> _onConnected = StreamController<Room>.broadcast();

  /// Called when a room has succeeded.
  late Stream<Room> onConnected;

  final StreamController<RoomDisconnectedEvent> _onDisconnected = StreamController<RoomDisconnectedEvent>.broadcast();

  /// Called when a room has been disconnected from.
  late Stream<RoomDisconnectedEvent> onDisconnected;

  final StreamController<RoomParticipantConnectedEvent> _onParticipantConnected = StreamController<RoomParticipantConnectedEvent>.broadcast();

  /// Called when a participant has connected to a room.
  late Stream<RoomParticipantConnectedEvent> onParticipantConnected;

  final StreamController<RoomParticipantDisconnectedEvent> _onParticipantDisconnected = StreamController<RoomParticipantDisconnectedEvent>.broadcast();

  /// Called when a participant has disconnected from a room.
  late Stream<RoomParticipantDisconnectedEvent> onParticipantDisconnected;

  final StreamController<Room> _onReconnected = StreamController<Room>.broadcast();

  /// Called after the [LocalParticipant] reconnects to a room after a network disruption.
  late Stream<Room> onReconnected;

  final StreamController<RoomReconnectingEvent> _onReconnecting = StreamController<RoomReconnectingEvent>.broadcast();

  /// Called when the [LocalParticipant] has experienced a network disruption and the client
  /// begins trying to reestablish a connection to a room.
  late Stream<RoomReconnectingEvent> onReconnecting;

  final StreamController<Room> _onRecordingStarted = StreamController<Room>.broadcast();

  /// This method is only called when a Room which was not previously recording starts recording.
  late Stream<Room> onRecordingStarted;

  final StreamController<Room> _onRecordingStopped = StreamController<Room>.broadcast();

  /// This method is only called when a Room which was previously recording stops recording.
  late Stream<Room> onRecordingStopped;

  Room(this._internalId) {
    _roomStream = ProgrammableVideoPlatform.instance.roomStream(_internalId)!.listen(_parseRoomEvents);
    _remoteParticipantStream = ProgrammableVideoPlatform.instance.remoteParticipantStream(_internalId)!.listen(_parseRemoteParticipantEvents);
    _localParticipantStream = ProgrammableVideoPlatform.instance.localParticipantStream(_internalId)!.listen(_parseLocalParticipantEvents);
    _remoteDataTrackStream = ProgrammableVideoPlatform.instance.remoteDataTrackStream(_internalId)!.listen(_parseRemoteDataTrackEvents);

    onDominantSpeakerChange = _onDominantSpeakerChange.stream;
    onConnectFailure = _onConnectFailure.stream;
    onConnected = _onConnected.stream;
    onDisconnected = _onDisconnected.stream;
    onParticipantConnected = _onParticipantConnected.stream;
    onParticipantDisconnected = _onParticipantDisconnected.stream;
    onReconnected = _onReconnected.stream;
    onReconnecting = _onReconnecting.stream;
    onRecordingStarted = _onRecordingStarted.stream;
    onRecordingStopped = _onRecordingStopped.stream;
  }

  /// Disconnects from the room.
  Future<void> disconnect() async {
    await ProgrammableVideoPlatform.instance.disconnect();
    _localParticipant?._dispose();
  }

  Future<void> dispose() async {
    await _roomStream.cancel();
    await _remoteParticipantStream.cancel();
    await _localParticipantStream.cancel();
    await _remoteDataTrackStream.cancel();
  }

  /// Find or create a [RemoteParticipant].
  ///
  /// If there are buffered events, they will be passed to the [RemoteParticipant].
  RemoteParticipant _findOrCreateRemoteParticipant(RemoteParticipantModel model) {
    var remoteParticipant = _remoteParticipants.firstWhere(
      (RemoteParticipant p) => p.sid == model.sid,
      orElse: () => RemoteParticipant._fromModel(model),
    );

    // Check if there is an actual remote participants
    final remoteParticipantSid = remoteParticipant.sid;
    if (remoteParticipantSid != null) {
      // Check if there are events buffered for the remote participant.
      if (_remoteParticipantsEventBuffer.containsKey(remoteParticipantSid)) {
        for (var event in _remoteParticipantsEventBuffer[remoteParticipantSid]!) {
          remoteParticipant._parseEvents(event);
        }
        // Empty the event buffer.
        _remoteParticipantsEventBuffer[remoteParticipantSid] = [];
      }
    }

    return remoteParticipant;
  }

  /// Parse native room events to the right event streams.
  void _parseRoomEvents(BaseRoomEvent event) {
    TwilioProgrammableVideo._log("Room => Event '$event'");
    if (event is SkippableRoomEvent) {
      return;
    }
    _updateFromModel(event.roomModel);

    if (event is ConnectFailure) {
      final exception = event.exception != null ? TwilioException._fromModel(event.exception!) : null;
      _onConnectFailure.add(RoomConnectFailureEvent(this, exception));
    } else if (event is Connected) {
      _onConnected.add(this);
    } else if (event is Disconnected) {
      dispose();

      for (var participant in _remoteParticipants) {
        participant._dispose();
      }
      _remoteParticipants.clear();

      final exception = event.exception != null ? TwilioException._fromModel(event.exception!) : null;
      _onDisconnected.add(RoomDisconnectedEvent(this, exception));
    } else if (event is ParticipantConnected) {
      final remoteParticipant = _findOrCreateRemoteParticipant(event.connectedParticipant);

      if (!_remoteParticipants.contains(remoteParticipant)) {
        _remoteParticipants.add(remoteParticipant);
      }
      _onParticipantConnected.add(RoomParticipantConnectedEvent(this, remoteParticipant));
    } else if (event is ParticipantDisconnected) {
      var remoteParticipant = _findOrCreateRemoteParticipant(event.disconnectedParticipant);

      _remoteParticipants.remove(remoteParticipant);
      _onParticipantDisconnected.add(RoomParticipantDisconnectedEvent(this, remoteParticipant));
      remoteParticipant._dispose();
    } else if (event is Reconnected) {
      _onReconnected.add(this);
    } else if (event is Reconnecting) {
      final exception = event.exception != null ? TwilioException._fromModel(event.exception!) : null;
      _onReconnecting.add(RoomReconnectingEvent(this, exception));
    } else if (event is RecordingStarted) {
      _onRecordingStarted.add(this);
    } else if (event is RecordingStopped) {
      _onRecordingStopped.add(this);
    } else if (event is DominantSpeakerChanged) {
      final dominantSpeaker = event.dominantSpeaker;
      final remoteParticipant = dominantSpeaker != null ? _findOrCreateRemoteParticipant(dominantSpeaker) : null;
      _onDominantSpeakerChange.add(DominantSpeakerChangedEvent(this, remoteParticipant));

      if (remoteParticipant != null && !_remoteParticipants.contains(remoteParticipant)) {
        _remoteParticipants.add(remoteParticipant);
      }
    }
  }

  /// Parse native remote participant events.
  ///
  /// If the [RemoteParticipant] is not found, the event is buffered.
  void _parseRemoteParticipantEvents(BaseRemoteParticipantEvent event) {
    TwilioProgrammableVideo._log("RemoteParticipant => Event '$event'");

    // If no remoteParticipant data is received, skip the event.
    if (event is SkippableRemoteParticipantEvent) return;

    final remoteParticipantModel = event.remoteParticipantModel;
    if (remoteParticipantModel != null) {
      final remoteParticipant = _remoteParticipants.firstWhereOrNull((p) => p.sid == remoteParticipantModel.sid);
      final remoteParticipantModelSid = remoteParticipantModel.sid;

      if (remoteParticipantModelSid != null) {
        // If the received sid doesn't match, just buffer the event.
        if (remoteParticipant == null) {
          if (!_remoteParticipantsEventBuffer.containsKey(remoteParticipantModelSid)) {
            _remoteParticipantsEventBuffer[remoteParticipantModelSid] = [];
          }
          TwilioProgrammableVideo._log("RemoteParticipant => Buffering event '$event' for participant '$remoteParticipantModelSid'");
          return _remoteParticipantsEventBuffer[remoteParticipantModelSid]!.add(event);
        }

        remoteParticipant._parseEvents(event);
      }
    }
  }

  /// Parse native local participant events.
  void _parseLocalParticipantEvents(BaseLocalParticipantEvent event) {
    TwilioProgrammableVideo._log("LocalParticipant => Event '$event'");

    final localParticipant = _localParticipant;

    // If no localParticipant data is received, skip the event.
    if (event is SkippableLocalParticipantEvent || localParticipant == null) {
      return;
    }

    localParticipant._updateFromModel(event.localParticipantModel!);
    localParticipant._parseEvents(event);
  }

  /// Parse native remote participant events.
  ///
  /// If the [RemoteDataTrack] is not found, the event is buffered.
  void _parseRemoteDataTrackEvents(BaseRemoteDataTrackEvent event) {
    TwilioProgrammableVideo._log("RemoteDataTrack => Event '$event'");

    // If no RemoteDataTrack data is received, skip the event.
    if (event is SkippableRemoteDataTrackEvent) {
      return;
    }

    final remoteDataTrackModel = event.remoteDataTrackModel;

    _remoteParticipants.forEach((RemoteParticipant remoteParticipant) {
      remoteParticipant.remoteDataTracks.forEach((RemoteDataTrackPublication dataTrackPublication) {
        if (dataTrackPublication.trackSid == remoteDataTrackModel!.sid) {
          dataTrackPublication.remoteDataTrack!._parseEvents(event);
        }
      });
    });
  }

  /// Update this instances state from RoomEvents
  void _updateFromModel(RoomModel? roomModel) {
    if (roomModel != null && _sid == null || roomModel!.sid == _sid) {
      _sid ??= roomModel.sid;
      _name = roomModel.name;
      _state = roomModel.state;
      if (roomModel.mediaRegion != null) {
        _mediaRegion = roomModel.mediaRegion;
      }

      if (roomModel.localParticipant != null) {
        _localParticipant ??= LocalParticipant._fromModel(roomModel.localParticipant!);
        _localParticipant!._updateFromModel(roomModel.localParticipant!);
      }

      for (final remoteParticipantModel in roomModel.remoteParticipants) {
        final remoteParticipant = _findOrCreateRemoteParticipant(remoteParticipantModel);
        if (!_remoteParticipants.contains(remoteParticipant)) {
          _remoteParticipants.add(remoteParticipant);
        }
        remoteParticipant._updateFromModel(remoteParticipantModel);
      }
      var removeParticipants = _remoteParticipants.where((p) => !roomModel.remoteParticipants.any((model) => p.sid == model.sid)).toList();
      for (var participant in removeParticipants) {
        _remoteParticipants.remove(participant);
        participant._dispose();
      }
    }
  }
}
