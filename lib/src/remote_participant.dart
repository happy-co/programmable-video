import 'dart:async';

import 'package:flutter/services.dart';
import 'package:twilio_unofficial_programmable_video/src/remote_video_track.dart';
import 'package:twilio_unofficial_programmable_video/src/remote_video_track_publication.dart';

class RemoteParticipantEvent {
  final RemoteParticipant remoteParticipant;

  final RemoteVideoTrackPublication remoteVideoTrackPublication;

  final RemoteVideoTrack remoteVideoTrack;

  RemoteParticipantEvent(this.remoteParticipant, this.remoteVideoTrackPublication, this.remoteVideoTrack) : assert(remoteParticipant != null);
}

class RemoteParticipant {
  Stream<dynamic> _participantStream;

  final String _identity;

  final String _sid;

  List<RemoteVideoTrackPublication> _remoteVideoTrackPublications = <RemoteVideoTrackPublication>[];

  String get sid {
    return _sid;
  }

  String get identity {
    return _identity;
  }

  List<RemoteVideoTrackPublication> get remoteVideoTracks {
    return [..._remoteVideoTrackPublications];
  }

  final StreamController<RemoteParticipantEvent> _onVideoTrackSubscribed = StreamController<RemoteParticipantEvent>();
  Stream<RemoteParticipantEvent> onVideoTrackSubscribed;

  final StreamController<RemoteParticipantEvent> _onVideoTrackUnsubscribed = StreamController<RemoteParticipantEvent>();
  Stream<RemoteParticipantEvent> onVideoTrackUnsubscribed;

  RemoteParticipant(this._identity, this._sid, EventChannel remoteParticipantChannel)
      : assert(_identity != null),
        assert(_sid != null) {
    _participantStream = remoteParticipantChannel.receiveBroadcastStream()..listen(_parseEvents);

    onVideoTrackSubscribed = _onVideoTrackSubscribed.stream;
    onVideoTrackUnsubscribed = _onVideoTrackUnsubscribed.stream;
  }

  factory RemoteParticipant.fromMap(Map<String, dynamic> map, EventChannel remoteParticipantChannel) {
    final RemoteParticipant remoteParticipant = RemoteParticipant(map['identity'], map['sid'], remoteParticipantChannel);

    if (map['remoteVideoTrackPublications'] != null) {
      final List<Map<String, dynamic>> remoteVideoTrackPublicationsList = map['remoteVideoTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final Map<String, dynamic> remoteVideoTrackPublicationMap in remoteVideoTrackPublicationsList) {
        remoteParticipant._remoteVideoTrackPublications.add(RemoteVideoTrackPublication.fromMap(remoteVideoTrackPublicationMap, remoteParticipant));
      }
    }

    return remoteParticipant;
  }

  void updateFromMap(Map<String, dynamic> map) {
    if (map['remoteVideoTrackPublications'] != null) {
      final List<Map<String, dynamic>> remoteVideoTrackPublicationsList = map['remoteVideoTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final Map<String, dynamic> remoteVideoTrackPublicationMap in remoteVideoTrackPublicationsList) {
        final RemoteVideoTrackPublication remoteVideoTrackPublication = this._remoteVideoTrackPublications.firstWhere(
              (p) => p.trackSid == remoteVideoTrackPublicationMap['sid'],
              orElse: () => RemoteVideoTrackPublication.fromMap(remoteVideoTrackPublicationMap, this),
            );
        if (!this._remoteVideoTrackPublications.contains(remoteVideoTrackPublication)) {
          this._remoteVideoTrackPublications.add(remoteVideoTrackPublication);
        }
        remoteVideoTrackPublication.updateFromMap(remoteVideoTrackPublicationMap);
      }
    }
  }

  void _parseEvents(dynamic event) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(event['data']);

    // If no remoteParticipant data is received, skip the event.
    if (data['remoteParticipant'] == null) {
      return;
    }

    final Map<String, dynamic> remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
    // If the received sid doesn't match, just skip the event.
    if (remoteParticipantMap['sid'] != _sid) {
      return;
    }

    final String eventName = event["name"];
    print("Event '$eventName' => ${event["data"]}, error: ${event["error"]}");

    RemoteVideoTrackPublication remoteVideoTrackPublication;
    if (data['remoteVideoTrackPublication'] != null) {
      final Map<String, dynamic> remoteVideoTrackPublicationMap = Map<String, dynamic>.from(data['remoteVideoTrackPublication']);
      remoteVideoTrackPublication = _remoteVideoTrackPublications.firstWhere(
        (RemoteVideoTrackPublication p) => p.trackSid == remoteVideoTrackPublicationMap['sid'],
        orElse: () => RemoteVideoTrackPublication.fromMap(remoteVideoTrackPublicationMap, this),
      );
      if (!_remoteVideoTrackPublications.contains(remoteVideoTrackPublication)) {
        _remoteVideoTrackPublications.add(remoteVideoTrackPublication);
      }
      remoteVideoTrackPublication.updateFromMap(remoteVideoTrackPublicationMap);
    }

    RemoteVideoTrack remoteVideoTrack;
    if (['videoTrackSubscribed', 'videoTrackUnsubscribed'].contains(eventName)) {
      assert(remoteVideoTrackPublication != null);
      remoteVideoTrack = remoteVideoTrackPublication.remoteVideoTrack;
    }

    final RemoteParticipantEvent remoteParticipantEvent = RemoteParticipantEvent(this, remoteVideoTrackPublication, remoteVideoTrack);

    switch (eventName) {
      case 'videoTrackSubscribed':
        assert(remoteVideoTrack != null);
        _onVideoTrackSubscribed.add(remoteParticipantEvent);
        break;
      case 'videoTrackUnsubscribed':
        assert(remoteVideoTrack != null);
        _remoteVideoTrackPublications.remove(remoteVideoTrackPublication);
        _onVideoTrackUnsubscribed.add(remoteParticipantEvent);
        break;
    }
  }
}
