import 'dart:async';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';
import 'package:twilio_unofficial_programmable_video/src/local_participant.dart';
import 'package:twilio_unofficial_programmable_video/src/remote_participant.dart';
import 'package:twilio_unofficial_programmable_video/src/room_state.dart';
import 'package:twilio_unofficial_programmable_video/src/twilio_exception.dart';

class RoomEvent {
  final Room room;

  final RemoteParticipant remoteParticipant;

  final TwilioException exception;

  RoomEvent(this.room, this.remoteParticipant, this.exception) : assert(room != null);
}

class Room {
  final int _internalId;

  final EventChannel _eventChannel;

  final EventChannel _remoteParticipantChannel;

  StreamSubscription<dynamic> _roomStream;

  String _sid;

  String _name;

  String _mediaRegion;

  RoomState _state;

  LocalParticipant _localParticipant;

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
  List<RemoteParticipant> remoteParticipants = <RemoteParticipant>[];

  final StreamController<RoomEvent> _onConnectFailure = StreamController<RoomEvent>();
  Stream<RoomEvent> onConnectFailure;

  final StreamController<RoomEvent> _onConnectedCtrl = StreamController<RoomEvent>();
  Stream<RoomEvent> onConnected;

  final StreamController<RoomEvent> _onDisconnected = StreamController<RoomEvent>();
  Stream<RoomEvent> onDisconnected;

  final StreamController<RoomEvent> _onParticipantConnected = StreamController<RoomEvent>();
  Stream<RoomEvent> onParticipantConnected;

  final StreamController<RoomEvent> _onParticipantDisconnected = StreamController<RoomEvent>();
  Stream<RoomEvent> onParticipantDisconnected;

  final StreamController<RoomEvent> _onReconnected = StreamController<RoomEvent>();
  Stream<RoomEvent> onReconnected;

  final StreamController<RoomEvent> _onReconnecting = StreamController<RoomEvent>();
  Stream<RoomEvent> onReconnecting;

  final StreamController<RoomEvent> _onRecordingStarted = StreamController<RoomEvent>();
  Stream<RoomEvent> onRecordingStarted;

  final StreamController<RoomEvent> _onRecordingStopped = StreamController<RoomEvent>();
  Stream<RoomEvent> onRecordingStopped;

  Room(this._internalId, this._eventChannel, this._remoteParticipantChannel)
      : assert(_internalId != null),
        assert(_eventChannel != null) {
    _roomStream = _eventChannel.receiveBroadcastStream(_internalId).listen(_parseEvents);

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
  }

  RemoteParticipant _findOrCreateRemoteParticipant(Map<String, dynamic> remoteParticipantMap) {
    return remoteParticipants.firstWhere(
      (RemoteParticipant p) => p.sid == remoteParticipantMap['sid'],
      orElse: () => RemoteParticipant.fromMap(remoteParticipantMap, _remoteParticipantChannel),
    );
  }

  void _parseEvents(dynamic event) {
    final String eventName = event['name'];
    print("Event '$eventName' => ${event['data']}, error: ${event['error']}");
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
      _localParticipant ??= LocalParticipant.fromMap(localParticipantMap);
      _localParticipant.updateFromMap(localParticipantMap);
    }

    if (roomMap['remoteParticipants'] != null) {
      final List<Map<String, dynamic>> remoteParticipantsList = roomMap['remoteParticipants'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final remoteParticipantMap in remoteParticipantsList) {
        final remoteParticipant = _findOrCreateRemoteParticipant(remoteParticipantMap);
        if (!remoteParticipants.contains(remoteParticipant)) {
          remoteParticipants.add(remoteParticipant);
        }
        remoteParticipant.updateFromMap(remoteParticipantMap);
      }
    }

    RemoteParticipant remoteParticipant;
    if (data['remoteParticipant'] != null) {
      final remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
      remoteParticipant = _findOrCreateRemoteParticipant(remoteParticipantMap);
      if (!remoteParticipants.contains(remoteParticipant)) {
        remoteParticipants.add(remoteParticipant);
      }
      remoteParticipant.updateFromMap(remoteParticipantMap);
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
        remoteParticipants.remove(remoteParticipant);
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
}
