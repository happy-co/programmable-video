import 'dart:async';
import 'package:flutter/services.dart';
import 'package:twilio_unofficial_programmable_video/src/local_participant.dart';
import 'package:twilio_unofficial_programmable_video/src/remote_participant.dart';
import 'package:twilio_unofficial_programmable_video/src/twilio_exception.dart';

class Room {
  final int _internalId;

  final EventChannel _eventChannel;

  final EventChannel _remoteParticipantChannel;

  Stream<dynamic> _roomStream;

  String _sid;

  String _name;

  LocalParticipant _localParticipant;

  String get sid {
    return _sid;
  }

  String get name {
    return _name;
  }

  LocalParticipant get localParticipant {
    return _localParticipant;
  }

  List<RemoteParticipant> remoteParticipants = <RemoteParticipant>[];

  final StreamController<TwilioException> _onConnectFailure = StreamController<TwilioException>();
  Stream<TwilioException> onConnectFailure;

  final StreamController<Room> _onConnectedCtrl = StreamController<Room>();
  Stream<Room> onConnected;

  final StreamController<TwilioException> _onDisconnected = StreamController<TwilioException>();
  Stream<TwilioException> onDisconnected;

  final StreamController<RemoteParticipant> _onParticipantConnected = StreamController<RemoteParticipant>();
  Stream<RemoteParticipant> onParticipantConnected;

  final StreamController<RemoteParticipant> _onParticipantDisconnected = StreamController<RemoteParticipant>();
  Stream<RemoteParticipant> onParticipantDisconnected;

  final StreamController<Room> _onReconnected = StreamController<Room>();
  Stream<Room> onReconnected;

  final StreamController<TwilioException> _onReconnecting = StreamController<TwilioException>();
  Stream<TwilioException> onReconnecting;

  final StreamController<Room> _onRecordingStarted = StreamController<Room>();
  Stream<Room> onRecordingStarted;

  final StreamController<Room> _onRecordingStopped = StreamController<Room>();
  Stream<Room> onRecordingStopped;

  Room(this._internalId, this._eventChannel, this._remoteParticipantChannel)
      : assert(_internalId != null),
        assert(_eventChannel != null) {
    _roomStream = _eventChannel.receiveBroadcastStream(_internalId)..listen(_parseEvents);

    onConnectFailure = _onConnectFailure.stream;
    onConnected = _onConnectedCtrl.stream;
    onDisconnected = _onDisconnected.stream;
    onParticipantConnected = _onParticipantConnected.stream;
    onParticipantDisconnected = _onParticipantDisconnected.stream;
    onReconnected = _onReconnected.stream;
    onRecordingStarted = _onRecordingStarted.stream;
    onRecordingStopped = _onRecordingStopped.stream;
  }

  void disconnect() {}

  RemoteParticipant _createRemoteParticipant(Map<String, dynamic> remoteParticipantMap) {
    return remoteParticipants.firstWhere(
      (RemoteParticipant p) => p.sid == remoteParticipantMap['sid'],
      orElse: () => RemoteParticipant.fromMap(remoteParticipantMap, _remoteParticipantChannel),
    );
  }

  void _parseEvents(dynamic event) {
    final String eventName = event['name'];
    print("Event '$eventName' => ${event['data']}, error: ${event['error']}");
    final Map<String, dynamic> data = Map<String, dynamic>.from(event['data']);

    if (data['room'] != null) {
      final Map<String, String> roomMap = Map<String, String>.from(data['room']);
      _sid = roomMap['sid'];
      _name = roomMap['name'];
    }

    // This is only filled if it is the "connected" event.
    if (data['localParticipant'] != null && _localParticipant == null) {
      final Map<String, String> localParticipantMap = Map<String, String>.from(data['localParticipant']);
      if (localParticipantMap['sid'] != null) {
        _localParticipant = LocalParticipant(localParticipantMap['identity'], localParticipantMap['sid']);
      }
    }

    // This is only filled if it is the "connected" event.
    // TODO: Might be needed for the "reconnected" event as well.
    if (data['remoteParticipants'] != null) {
      final List<Map<String, dynamic>> remoteParticipantsList = data['remoteParticipants'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final Map<String, dynamic> remoteParticipantMap in remoteParticipantsList) {
        remoteParticipants.add(_createRemoteParticipant(remoteParticipantMap));
      }
    }

    RemoteParticipant participant;
    if (data['remoteParticipant'] != null) {
      final Map<String, dynamic> participantMap = Map<String, dynamic>.from(data['remoteParticipant']);
      participant = _createRemoteParticipant(participantMap);
      remoteParticipants.add(participant);
    }

    TwilioException exception;
    if (event['error'] != null) {
      final Map<String, String> errorMap = Map<String, String>.from(event['error'] as Map<dynamic, dynamic>);
      exception = TwilioException(errorMap['code'] as int, errorMap['message']);
    }

    switch (eventName) {
      case 'connectFailure':
        _onConnectFailure.add(exception);
        break;
      case 'connected':
        _onConnectedCtrl.add(this);
        break;
      case 'disconnected':
        _onDisconnected.add(exception);
        break;
      case 'participantConnected':
        _onParticipantConnected.add(participant);
        break;
      case 'participantDisconnected':
        remoteParticipants.remove(participant);
        // TODO: The "participantDisconnected" event might have an exception. But we are not sending it.
        _onParticipantDisconnected.add(participant);
        break;
      case 'reconnected':
        _onReconnected.add(this);
        break;
      case 'reconnecting':
        _onReconnecting.add(exception);
        break;
      case 'recordingStarted':
        _onRecordingStarted.add(this);
        break;
      case 'recordingStopped':
        _onRecordingStopped.add(this);
        break;
    }
  }
}
