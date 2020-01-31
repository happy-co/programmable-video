part of twilio_unofficial_programmable_video;

/// The event class for all [Room] events.
class RoomEvent {
  /// The receiving room.
  final Room room;

  /// The remote participant that joined or leaved.
  ///
  /// Will be non-null with the following events:
  /// - participantConnected
  /// - participantDisconnected
  final RemoteParticipant remoteParticipant;

  /// The exception of the event.
  ///
  /// Can be null.
  final TwilioException exception;

  RoomEvent(this.room, this.remoteParticipant, this.exception) : assert(room != null);
}

/// A [Room] represents a media session with zero or more remote participants. Media shared by any one [RemoteParticipant] is distributed equally to all other participants.
class Room {
  final int _internalId;

  /// Stream for the native room events.
  StreamSubscription<dynamic> _roomStream;

  /// Stream for the native remote participant events.
  StreamSubscription<dynamic> _remoteParticipantStream;

  String _sid;

  String _name;

  String _mediaRegion;

  RoomState _state;

  LocalParticipant _localParticipant;

  final List<RemoteParticipant> _remoteParticipants = [];

  /// Map of buffered events for remote participants.
  final Map<String, List<dynamic>> _remoteEventBuffer = {};

  /// The SID of this [Room].
  String get sid {
    return _sid;
  }

  /// The name of this [Room].
  String get name {
    return _name;
  }

  /// The region where media is processed.
  ///
  /// This property is set in Group Rooms by the time the [Room] reaches [RoomState.CONNECTED].
  /// It can be `null` under the following conditions:
  /// * The [Room] has not reached the [RoomState.CONNECTED] state.
  /// * The instance represents a peer-to-peer room.
  String get mediaRegion {
    return _mediaRegion;
  }

  /// The current room state.
  RoomState get state {
    return _state;
  }

  /// The current local participant.
  ///
  /// If the room has not reached [RoomState.CONNECTED] then it will be `null`.
  LocalParticipant get localParticipant {
    return _localParticipant;
  }

  /// All currently connected participants.
  List<RemoteParticipant> get remoteParticipants {
    return <RemoteParticipant>[..._remoteParticipants];
  }

  /// Called when a connection to a room failed.
  final StreamController<RoomEvent> _onConnectFailure = StreamController<RoomEvent>();
  Stream<RoomEvent> onConnectFailure;

  /// Called when a room has succeeded.
  final StreamController<RoomEvent> _onConnectedCtrl = StreamController<RoomEvent>();
  Stream<RoomEvent> onConnected;

  /// Called when a room has been disconnected from.
  final StreamController<RoomEvent> _onDisconnected = StreamController<RoomEvent>();
  Stream<RoomEvent> onDisconnected;

  /// Called when a participant has connected to a room.
  final StreamController<RoomEvent> _onParticipantConnected = StreamController<RoomEvent>();
  Stream<RoomEvent> onParticipantConnected;

  /// Called when a participant has disconnected from a room.
  final StreamController<RoomEvent> _onParticipantDisconnected = StreamController<RoomEvent>();
  Stream<RoomEvent> onParticipantDisconnected;

  /// Called after the [LocalParticipant] reconnects to a room after a network disruption.
  final StreamController<RoomEvent> _onReconnected = StreamController<RoomEvent>();
  Stream<RoomEvent> onReconnected;

  /// Called when the [LocalParticipant] has experienced a network disruption and the client begins trying to reestablish a connection to a room.
  final StreamController<RoomEvent> _onReconnecting = StreamController<RoomEvent>();
  Stream<RoomEvent> onReconnecting;

  /// This method is only called when a Room which was not previously recording starts recording.
  final StreamController<RoomEvent> _onRecordingStarted = StreamController<RoomEvent>();
  Stream<RoomEvent> onRecordingStarted;

  /// This method is only called when a Room which was previously recording stops recording.
  final StreamController<RoomEvent> _onRecordingStopped = StreamController<RoomEvent>();
  Stream<RoomEvent> onRecordingStopped;

  Room(this._internalId, EventChannel roomChannel, EventChannel remoteParticipantChannel)
      : assert(_internalId != null),
        assert(roomChannel != null),
        assert(remoteParticipantChannel != null) {
    _roomStream = roomChannel.receiveBroadcastStream(_internalId).listen(_parseRoomEvents);
    _remoteParticipantStream = remoteParticipantChannel.receiveBroadcastStream(_internalId).listen(_parseRemoteParticipantEvents);

    onConnectFailure = _onConnectFailure.stream;
    onConnected = _onConnectedCtrl.stream;
    onDisconnected = _onDisconnected.stream;
    onParticipantConnected = _onParticipantConnected.stream;
    onParticipantDisconnected = _onParticipantDisconnected.stream;
    onReconnected = _onReconnected.stream;
    onRecordingStarted = _onRecordingStarted.stream;
    onRecordingStopped = _onRecordingStopped.stream;
  }

  /// Disconnects from the room.
  Future<void> disconnect() async {
    await const MethodChannel('twilio_unofficial_programmable_video').invokeMethod('disconnect');
    await _roomStream.cancel();
    await _remoteParticipantStream.cancel();
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
    if (_remoteEventBuffer.containsKey(remoteParticipant.sid)) {
      for(var event in _remoteEventBuffer[remoteParticipant.sid]) {
        remoteParticipant._parseEvents(event);
      }
      // Empty the event buffer.
      _remoteEventBuffer[remoteParticipant.sid] = [];
    }

    return remoteParticipant;
  }

  /// Parse native room events to the right event streams.
  void _parseRoomEvents(dynamic event) {
    final String eventName = event['name'];
    TwilioUnofficialProgrammableVideo._log("Room => Event '$eventName' => ${event["data"]}, error: ${event["error"]}");
    final data = Map<String, dynamic>.from(event['data']);

    // If no room data is received, skip the event.
    if (data['room'] == null) return;

    final roomMap = Map<String, dynamic>.from(data['room']);
    _sid = roomMap['sid'];
    _name = roomMap['name'];
    _state = EnumToString.fromString(RoomState.values, roomMap['state']);
    _mediaRegion = roomMap['mediaRegion'];

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

    RemoteParticipant remoteParticipant;
    if (data['remoteParticipant'] != null) {
      final remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
      remoteParticipant = _findOrCreateRemoteParticipant(remoteParticipantMap);
      if (!_remoteParticipants.contains(remoteParticipant)) {
        _remoteParticipants.add(remoteParticipant);
      }
      remoteParticipant._updateFromMap(remoteParticipantMap);
    }

    TwilioException exception;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      exception = TwilioException(errorMap['code'] as int, errorMap['message']);
    }

    final roomEvent = RoomEvent(this, remoteParticipant, exception);

    switch (eventName) {
      case 'connectFailure':
        assert(exception != null);
        _onConnectFailure.add(roomEvent);
        break;
      case 'connected':
        _onConnectedCtrl.add(roomEvent);
        break;
      case 'disconnected':
        _onDisconnected.add(roomEvent);
        break;
      case 'participantConnected':
        assert(remoteParticipant != null);
        _onParticipantConnected.add(roomEvent);
        break;
      case 'participantDisconnected':
        assert(remoteParticipant != null);
        _remoteParticipants.remove(remoteParticipant);
        _onParticipantDisconnected.add(roomEvent);
        break;
      case 'reconnected':
        assert(exception != null);
        _onReconnected.add(roomEvent);
        break;
      case 'reconnecting':
        _onReconnecting.add(roomEvent);
        break;
      case 'recordingStarted':
        _onRecordingStarted.add(roomEvent);
        break;
      case 'recordingStopped':
        _onRecordingStopped.add(roomEvent);
        break;
    }
  }

  /// Parse native remote participant events.
  ///
  /// If the [RemoteParticipant] is not found the event is buffered.
  void _parseRemoteParticipantEvents(dynamic event) {
    final eventName = event['name'];
    TwilioUnofficialProgrammableVideo._log("RemoteParticipant => Event '$eventName' => ${event["data"]}, error: ${event["error"]}");

    final data = Map<String, dynamic>.from(event['data']);

    // If no remoteParticipant data is received, skip the event.
    if (data['remoteParticipant'] == null) {
      return;
    }

    final remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
    final remoteParticipant = _remoteParticipants.firstWhere((p) => p.sid == remoteParticipantMap['sid'], orElse: () => null);

    // If the received sid doesn't match, just buffer the event.
    if (remoteParticipant == null) {
      if (!_remoteEventBuffer.containsKey(remoteParticipantMap['sid'])) {
        _remoteEventBuffer[remoteParticipantMap['sid']] = [];
      }
      TwilioUnofficialProgrammableVideo._log("RemoteParticipant => Buffering event '$eventName' for participant '${remoteParticipantMap['sid']}'");
      return _remoteEventBuffer[remoteParticipantMap['sid']].add(event);
    }

    remoteParticipant._parseEvents(event);
  }
}
