import 'dart:async';

import 'package:flutter/services.dart';
import 'remote_video_track.dart';

class RemoteParticipant {
  Stream<dynamic> _participantStream;

  final String _identity;

  final String _sid;

  // TODO: This should become a list of "RemoteVideoTrackPublications" when the "ConnectOptions" support the "autoSubscribe" option.
  List<RemoteVideoTrack> _remoteVideoTracks = <RemoteVideoTrack>[];

  String get sid {
    return _sid;
  }

  String get identity {
    return _identity;
  }

  List<RemoteVideoTrack> get remoteVideoTracks {
    return [..._remoteVideoTracks];
  }

  final StreamController<RemoteVideoTrack> _onVideoTrackSubscribed = StreamController<RemoteVideoTrack>();
  Stream<RemoteVideoTrack> onVideoTrackSubscribed;

  final StreamController<RemoteVideoTrack> _onVideoTrackUnsubscribed = StreamController<RemoteVideoTrack>();
  Stream<RemoteVideoTrack> onVideoTrackUnsubscribed;

  RemoteParticipant(this._identity, this._sid, EventChannel remoteParticipantChannel)
      : assert(_identity != null),
        assert(_sid != null) {
    _participantStream = remoteParticipantChannel.receiveBroadcastStream()..listen(_parseEvents);

    onVideoTrackSubscribed = _onVideoTrackSubscribed.stream;
    onVideoTrackUnsubscribed = _onVideoTrackUnsubscribed.stream;
  }

  factory RemoteParticipant.fromMap(Map<String, dynamic> map, EventChannel remoteParticipantChannel) {
    final RemoteParticipant remoteParticipant = RemoteParticipant(map['identity'], map['sid'], remoteParticipantChannel);

    if (map['remoteVideoTracks'] != null) {
      final List<Map<String, String>> remoteVideoTracksList = map['remoteVideoTracks'].map<Map<String, String>>((r) => Map<String, String>.from(r)).toList();
      for (final Map<String, String> remoteVideoTrackMap in remoteVideoTracksList) {
        remoteParticipant._remoteVideoTracks.add(RemoteVideoTrack.fromMap(remoteVideoTrackMap, remoteParticipant));
      }
    }

    return remoteParticipant;
  }

  // TODO: The received data hasn't been properly namespaced. The same way that Room event data is namespaced.
  void _parseEvents(dynamic event) {
    final Map<String, String> data = Map<String, String>.from(event['data'] as Map<dynamic, dynamic>);
    if (data['remoteParticipantSid'] == _sid) {
      final String eventName = event["name"];
      print("Event '$eventName' => ${event["data"]}, error: ${event["error"]}");

      RemoteVideoTrack remoteVideoTrack;
      if (data['remoteVideoTrackSid'] != null) {
        remoteVideoTrack = remoteVideoTracks.firstWhere((RemoteVideoTrack r) => r.sid == data['remoteVideoTrackSid'], orElse: () => null);
        if (remoteVideoTrack == null) {
          remoteVideoTrack = RemoteVideoTrack(data['remoteVideoTrackSid'], this);
          remoteVideoTracks.add(remoteVideoTrack);
        }
      }

      switch (eventName) {
        case 'videoTrackSubscribed':
          _onVideoTrackSubscribed.add(remoteVideoTrack);
          break;
        case 'videoTrackUnsubscribed':
          remoteVideoTracks.remove(remoteVideoTrack);
          _onVideoTrackUnsubscribed.add(remoteVideoTrack);
          break;
      }
    }
  }
}
