part of twilio_programmable_video;

/// A [Room] represents a media session with zero or more remote participants. Media shared by any one [RemoteParticipant] is distributed equally to all other participants.
class Room {
  final int _internalId;

  /// Stream for the native room events.
  StreamSubscription<dynamic> _roomStream;

  /// Stream for the native remote participant events.
  StreamSubscription<dynamic> _remoteParticipantStream;

  /// Stream for the native local participant events.
  StreamSubscription<dynamic> _localParticipantStream;

  /// Stream for the native remote data track events.
  StreamSubscription<dynamic> _remoteDataTrackStream;

  String _sid;

  String _name;

  Region _mediaRegion;

  RoomState _state;

  LocalParticipant _localParticipant;

  RemoteParticipant _dominantSpeaker;

  final List<RemoteParticipant> _remoteParticipants = [];

  /// Map of buffered events for remote participants.
  final Map<String, List<dynamic>> _remoteParticipantsEventBuffer = {};

  /// The SID of this [Room].
  String get sid => _sid;

  /// The name of this [Room].
  String get name => _name;

  /// The region where media is processed.
  ///
  /// This property is set in Group Rooms by the time the [Room] reaches [RoomState.CONNECTED].
  /// It can be `null` under the following conditions:
  /// * The [Room] has not reached the [RoomState.CONNECTED] state.
  /// * The instance represents a peer-to-peer room.
  Region get mediaRegion => _mediaRegion;

  /// The current room state.
  RoomState get state => _state;

  /// The current local participant.
  ///
  /// If the room has not reached [RoomState.CONNECTED] then it will be `null`.
  LocalParticipant get localParticipant => _localParticipant;

  /// All currently connected participants.
  List<RemoteParticipant> get remoteParticipants => <RemoteParticipant>[..._remoteParticipants];

  /// The remote participant with the loudest audio track.
  RemoteParticipant get dominantSpeaker => _dominantSpeaker;

  final StreamController<DominantSpeakerChangedEvent> _onDominantSpeakerChange = StreamController<DominantSpeakerChangedEvent>.broadcast();

  /// Called when the participant with the loudest audio track changes.
  Stream<DominantSpeakerChangedEvent> onDominantSpeakerChange;

  final StreamController<RoomConnectFailureEvent> _onConnectFailure = StreamController<RoomConnectFailureEvent>.broadcast();

  /// Called when a connection to a room failed.
  Stream<RoomConnectFailureEvent> onConnectFailure;

  final StreamController<Room> _onConnected = StreamController<Room>.broadcast();

  /// Called when a room has succeeded.
  Stream<Room> onConnected;

  final StreamController<RoomDisconnectedEvent> _onDisconnected = StreamController<RoomDisconnectedEvent>.broadcast();

  /// Called when a room has been disconnected from.
  Stream<RoomDisconnectedEvent> onDisconnected;

  final StreamController<RoomParticipantConnectedEvent> _onParticipantConnected = StreamController<RoomParticipantConnectedEvent>.broadcast();

  /// Called when a participant has connected to a room.
  Stream<RoomParticipantConnectedEvent> onParticipantConnected;

  final StreamController<RoomParticipantDisconnectedEvent> _onParticipantDisconnected = StreamController<RoomParticipantDisconnectedEvent>.broadcast();

  /// Called when a participant has disconnected from a room.
  Stream<RoomParticipantDisconnectedEvent> onParticipantDisconnected;

  final StreamController<Room> _onReconnected = StreamController<Room>.broadcast();

  /// Called after the [LocalParticipant] reconnects to a room after a network disruption.
  Stream<Room> onReconnected;

  final StreamController<RoomReconnectingEvent> _onReconnecting = StreamController<RoomReconnectingEvent>.broadcast();

  /// Called when the [LocalParticipant] has experienced a network disruption and the client
  /// begins trying to reestablish a connection to a room.
  Stream<RoomReconnectingEvent> onReconnecting;

  final StreamController<Room> _onRecordingStarted = StreamController<Room>.broadcast();

  /// This method is only called when a Room which was not previously recording starts recording.
  Stream<Room> onRecordingStarted;

  final StreamController<Room> _onRecordingStopped = StreamController<Room>.broadcast();

  /// This method is only called when a Room which was previously recording stops recording.
  Stream<Room> onRecordingStopped;

  Room(this._internalId) : assert(_internalId != null) {
    _roomStream = TwilioProgrammableVideo._roomChannel.receiveBroadcastStream(_internalId).listen(_parseRoomEvents);
    _remoteParticipantStream = TwilioProgrammableVideo._remoteParticipantChannel.receiveBroadcastStream(_internalId).listen(_parseRemoteParticipantEvents);
    _localParticipantStream = TwilioProgrammableVideo._localParticipantChannel.receiveBroadcastStream(_internalId).listen(_parseLocalParticipantEvents);
    _remoteDataTrackStream = TwilioProgrammableVideo._remoteDataTrackChannel.receiveBroadcastStream(_internalId).listen(_parseRemoteDataTrackEvents);

    onDominantSpeakerChange = _onDominantSpeakerChange.stream;
    onConnectFailure = _onConnectFailure.stream;
    onConnected = _onConnected.stream;
    onDisconnected = _onDisconnected.stream;
    onParticipantConnected = _onParticipantConnected.stream;
    onParticipantDisconnected = _onParticipantDisconnected.stream;
    onReconnected = _onReconnected.stream;
    onRecordingStarted = _onRecordingStarted.stream;
    onRecordingStopped = _onRecordingStopped.stream;
  }

  /// Disconnects from the room.
  Future<void> disconnect() async {
    await const MethodChannel('twilio_programmable_video').invokeMethod('disconnect');
    await _roomStream.cancel();
    await _remoteParticipantStream.cancel();
    await _localParticipantStream.cancel();
    await _remoteDataTrackStream.cancel();
    _localParticipant?._dispose();
  }

  /// Find or create a [RemoteParticipant].
  ///
  /// If there are buffered events, they will be passed to the [RemoteParticipant].
  RemoteParticipant _findOrCreateRemoteParticipant(Map<String, dynamic> remoteParticipantMap) {
    var remoteParticipant = _remoteParticipants.firstWhere(
      (RemoteParticipant p) => p.sid == remoteParticipantMap['sid'],
      orElse: () => RemoteParticipant._fromMap(remoteParticipantMap),
    );

    // Check if there are events buffered for the remote participant.
    if (_remoteParticipantsEventBuffer.containsKey(remoteParticipant.sid)) {
      for (var event in _remoteParticipantsEventBuffer[remoteParticipant.sid]) {
        remoteParticipant._parseEvents(event);
      }
      // Empty the event buffer.
      _remoteParticipantsEventBuffer[remoteParticipant.sid] = [];
    }

    return remoteParticipant;
  }

  /// Parse native room events to the right event streams.
  void _parseRoomEvents(dynamic event) {
    final String eventName = event['name'];
    TwilioProgrammableVideo._log("Room => Event '$eventName' => ${event["data"]}, error: ${event["error"]}");
    final data = Map<String, dynamic>.from(event['data']);

    // If no room data is received, skip the event.
    if (data['room'] == null) return;

    final roomMap = Map<String, dynamic>.from(data['room']);
    _sid = roomMap['sid'];
    _name = roomMap['name'];
    _state = EnumToString.fromString(RoomState.values, roomMap['state']);
    if (roomMap['mediaRegion'] != null) {
      _mediaRegion = EnumToString.fromString(Region.values, roomMap['mediaRegion']);
    }

    if (roomMap['localParticipant'] != null) {
      final localParticipantMap = Map<String, dynamic>.from(roomMap['localParticipant']);
      _localParticipant ??= LocalParticipant._fromMap(localParticipantMap);
      _localParticipant._updateFromMap(localParticipantMap);
    }

    if (roomMap['remoteParticipants'] != null) {
      final List<Map<String, dynamic>> remoteParticipantsList = roomMap['remoteParticipants'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final remoteParticipantMap in remoteParticipantsList) {
        final remoteParticipant = _findOrCreateRemoteParticipant(remoteParticipantMap);
        if (!_remoteParticipants.contains(remoteParticipant)) {
          _remoteParticipants.add(remoteParticipant);
        }
        remoteParticipant._updateFromMap(remoteParticipantMap);
      }
    }

    if (roomMap['dominantSpeaker'] != null) {
      final dominantSpeakerMap = Map<String, dynamic>.from(roomMap['dominantSpeaker']);
      _dominantSpeaker = _findOrCreateRemoteParticipant(dominantSpeakerMap);
    }

    RemoteParticipant remoteParticipant;
    if (data['remoteParticipant'] != null) {
      final remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
      remoteParticipant = _findOrCreateRemoteParticipant(remoteParticipantMap);
      if (!_remoteParticipants.contains(remoteParticipant)) {
        _remoteParticipants.add(remoteParticipant);
      }
      remoteParticipant._updateFromMap(remoteParticipantMap);
    }

    TwilioException twilioException;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      twilioException = TwilioException(errorMap['code'] as int, errorMap['message']);
    }

    switch (eventName) {
      case 'connectFailure':
        assert(twilioException != null);
        _onConnectFailure.add(RoomConnectFailureEvent(this, twilioException));
        break;
      case 'connected':
        _onConnected.add(this);
        break;
      case 'disconnected':
        for (var participant in _remoteParticipants) {
          participant._dispose();
        }
        _remoteParticipants.clear();
        _onDisconnected.add(RoomDisconnectedEvent(this, twilioException));
        break;
      case 'participantConnected':
        assert(remoteParticipant != null);
        _onParticipantConnected.add(RoomParticipantConnectedEvent(this, remoteParticipant));
        break;
      case 'participantDisconnected':
        assert(remoteParticipant != null);
        _remoteParticipants.remove(remoteParticipant);
        _onParticipantDisconnected.add(RoomParticipantDisconnectedEvent(this, remoteParticipant));
        remoteParticipant._dispose();
        break;
      case 'reconnected':
        _onReconnected.add(this);
        break;
      case 'reconnecting':
        _onReconnecting.add(RoomReconnectingEvent(this, twilioException));
        break;
      case 'recordingStarted':
        _onRecordingStarted.add(this);
        break;
      case 'recordingStopped':
        _onRecordingStopped.add(this);
        break;
      case 'dominantSpeakerChanged':
        _onDominantSpeakerChange.add(DominantSpeakerChangedEvent(this, _dominantSpeaker));
        break;
    }
  }

  /// Parse native remote participant events.
  ///
  /// If the [RemoteParticipant] is not found, the event is buffered.
  void _parseRemoteParticipantEvents(dynamic event) {
    final eventName = event['name'];
    TwilioProgrammableVideo._log("RemoteParticipant => Event '$eventName' => ${event["data"]}, error: ${event["error"]}");

    final data = Map<String, dynamic>.from(event['data']);

    // If no remoteParticipant data is received, skip the event.
    if (data['remoteParticipant'] == null) {
      return;
    }

    final remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
    final remoteParticipant = _remoteParticipants.firstWhere((p) => p.sid == remoteParticipantMap['sid'], orElse: () => null);

    // If the received sid doesn't match, just buffer the event.
    if (remoteParticipant == null) {
      if (!_remoteParticipantsEventBuffer.containsKey(remoteParticipantMap['sid'])) {
        _remoteParticipantsEventBuffer[remoteParticipantMap['sid']] = [];
      }
      TwilioProgrammableVideo._log("RemoteParticipant => Buffering event '$eventName' for participant '${remoteParticipantMap['sid']}'");
      return _remoteParticipantsEventBuffer[remoteParticipantMap['sid']].add(event);
    }

    remoteParticipant._parseEvents(event);
  }

  /// Parse native local participant events.
  void _parseLocalParticipantEvents(dynamic event) {
    TwilioProgrammableVideo._log("LocalParticipant => Event '${event['name']}' => ${event["data"]}, error: ${event["error"]}");

    final data = Map<String, dynamic>.from(event['data']);

    // If no localParticipant data is received, skip the event.
    if (data['localParticipant'] == null || _localParticipant == null) {
      return;
    }

    final localParticipantMap = Map<String, dynamic>.from(data['localParticipant']);
    _localParticipant._updateFromMap(localParticipantMap);
    _localParticipant._parseEvents(event);
  }

  /// Parse native remote participant events.
  ///
  /// If the [RemoteDataTrack] is not found, the event is buffered.
  void _parseRemoteDataTrackEvents(dynamic event) {
    final eventName = event['name'];
    TwilioProgrammableVideo._log("RemoteDataTrack => Event '$eventName' => ${event["data"]}, error: ${event["error"]}");

    final data = Map<String, dynamic>.from(event['data']);

    // If no RemoteDataTrack data is received, skip the event.
    if (data['remoteDataTrack'] == null) {
      return;
    }

    final remoteDataTrackMap = Map<String, dynamic>.from(data['remoteDataTrack']);

    _remoteParticipants.forEach((RemoteParticipant remoteParticipant) {
      remoteParticipant.remoteDataTracks.forEach((RemoteDataTrackPublication dataTrackPublication) {
        if (dataTrackPublication.trackSid == remoteDataTrackMap['sid']) {
          dataTrackPublication.remoteDataTrack._parseEvents(event);
        }
      });
    });
  }
}
