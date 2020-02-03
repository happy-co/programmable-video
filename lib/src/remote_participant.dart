part of twilio_unofficial_programmable_video;

/// The event class for a [RemoteParticipant] events.
class RemoteParticipantEvent {
  /// The receiving remote participant.
  final RemoteParticipant remoteParticipant;

  /// The remote video track publication.
  ///
  /// Will be non-null with the following events:
  /// - videoTrackDisabled
  /// - videoTrackEnabled
  /// - videoTrackPublished
  /// - videoTrackSubscribed
  /// - videoTrackSubscriptionFailed
  /// - videoTrackUnpublished
  /// - videoTrackUnsubscribed
  final RemoteVideoTrackPublication remoteVideoTrackPublication;

  /// The remote video track.
  ///
  /// Will be non-null with the following events:
  /// - videoTrackSubscribed
  /// - videoTrackUnsubscribed
  final RemoteVideoTrack remoteVideoTrack;

  /// The remote audio track publication.
  ///
  /// Will be non-null with the following events:
  /// - audioTrackDisabled
  /// - audioTrackEnabled
  /// - audioTrackPublished
  /// - audioTrackSubscribed
  /// - audioTrackSubscriptionFailed
  /// - audioTrackUnpublished
  /// - audioTrackUnsubscribed
  final RemoteAudioTrackPublication remoteAudioTrackPublication;

  /// The remote audio track.
  ///
  /// Will be non-null with the following events:
  /// - audioTrackSubscribed
  /// - audioTrackUnsubscribed
  final RemoteAudioTrack remoteAudioTrack;

  /// The exception of the event.
  ///
  /// Can be null.
  final TwilioException exception;

  RemoteParticipantEvent({@required this.remoteParticipant, this.remoteVideoTrackPublication, this.remoteVideoTrack, this.remoteAudioTrackPublication, this.remoteAudioTrack, this.exception}) : assert(remoteParticipant != null);
}

/// A participant represents a remote user that can connect to a [Room].
class RemoteParticipant implements Participant {
  final String _identity;

  final String _sid;

  final List<RemoteAudioTrackPublication> _remoteAudioTrackPublications = <RemoteAudioTrackPublication>[];

//  List<RemoteDataTrackPublication> _remoteDataTrackPublications = <RemoteDataTrackPublication>[];

  final List<RemoteVideoTrackPublication> _remoteVideoTrackPublications = <RemoteVideoTrackPublication>[];

  /// The SID of the [RemoteParticipant].
  @override
  String get sid {
    return _sid;
  }

  /// The identity of the [RemoteParticipant].
  @override
  String get identity {
    return _identity;
  }

  /// Read-only list of [RemoteAudioTrackPublication].
  List<RemoteAudioTrackPublication> get remoteAudioTracks {
    return [..._remoteAudioTrackPublications];
  }

//  /// Read-only list of remote data track publications.
//  List<RemoteDataTrackPublication> get remoteDataTracks {
//    return [..._remoteDataTrackPublications];
//  }

  /// Read-only list of [RemoteVideoTrackPublication].
  List<RemoteVideoTrackPublication> get remoteVideoTracks {
    return [..._remoteVideoTrackPublications];
  }

  /// Read-only list of [AudioTrackPublication].
  @override
  List<AudioTrackPublication> get audioTracks {
    return [..._remoteAudioTrackPublications];
  }

//  /// Read-only list of data track publications.
//  List<DataTrackPublication> get dataTracks {
//    return [..._remoteDataTrackPublications];
//  }

  /// Read-only list of [VideoTrackPublication].
  @override
  List<VideoTrackPublication> get videoTracks {
    return [..._remoteVideoTrackPublications];
  }

  final StreamController<RemoteParticipantEvent> _onAudioTrackDisabled = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that an [AudioTrack] has been disabled.
  Stream<RemoteParticipantEvent> onAudioTrackDisabled;

  final StreamController<RemoteParticipantEvent> _onAudioTrackEnabled = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that [AudioTrack] has been enabled.
  Stream<RemoteParticipantEvent> onAudioTrackEnabled;

  final StreamController<RemoteParticipantEvent> _onAudioTrackPublished = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has published a [RemoteAudioTrack] to this [Room].
  /// The audio of the track is not audible until the track has been subscribed to.
  Stream<RemoteParticipantEvent> onAudioTrackPublished;

  final StreamController<RemoteParticipantEvent> _onAudioTrackSubscribed = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener the [RemoteAudioTrack] of the [RemoteParticipant] has been subscribed to.
  /// The audio track is audible after this event.
  Stream<RemoteParticipantEvent> onAudioTrackSubscribed;

  final StreamController<RemoteParticipantEvent> _onAudioTrackSubscriptionFailed = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that media negotiation for a [RemoteAudioTrack] failed.
  Stream<RemoteParticipantEvent> onAudioTrackSubscriptionFailed;

  final StreamController<RemoteParticipantEvent> _onAudioTrackUnpublished = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has unpublished a [RemoteAudioTrack] from this [Room].
  Stream<RemoteParticipantEvent> onAudioTrackUnpublished;

  final StreamController<RemoteParticipantEvent> _onAudioTrackUnsubscribed = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that the [RemoteAudioTrack] of the [RemoteParticipant] has been unsubscribed from.
  /// The track is no longer audible after being unsubscribed from the audio track.
  Stream<RemoteParticipantEvent> onAudioTrackUnsubscribed;

  final StreamController<RemoteParticipantEvent> _onVideoTrackDisabled = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] video track has been disabled.
  Stream<RemoteParticipantEvent> onVideoTrackDisabled;

  final StreamController<RemoteParticipantEvent> _onVideoTrackEnabled = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] video track has been enabled.
  Stream<RemoteParticipantEvent> onVideoTrackEnabled;

  final StreamController<RemoteParticipantEvent> _onVideoTrackPublished = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has published a [RemoteVideoTrack] to this [Room].
  /// Video frames will not begin flowing until the video track has been subscribed to.
  Stream<RemoteParticipantEvent> onVideoTrackPublished;

  final StreamController<RemoteParticipantEvent> _onVideoTrackSubscribed = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener the [RemoteVideoTrack] of the [RemoteParticipant] has been subscribed to.
  /// Video frames are now flowing and can be rendered.
  Stream<RemoteParticipantEvent> onVideoTrackSubscribed;

  final StreamController<RemoteParticipantEvent> _onVideoTrackSubscriptionFailed = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that media negotiation for a [RemoteVideoTrack] failed.
  Stream<RemoteParticipantEvent> onVideoTrackSubscriptionFailed;

  final StreamController<RemoteParticipantEvent> _onVideoTrackUnpublished = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has removed a [RemoteVideoTrack] from this [Room].
  Stream<RemoteParticipantEvent> onVideoTrackUnpublished;

  final StreamController<RemoteParticipantEvent> _onVideoTrackUnsubscribed = StreamController<RemoteParticipantEvent>.broadcast();

  /// Notifies the listener that the [RemoteVideoTrack] of the [RemoteParticipant] has been unsubscribed from.
  Stream<RemoteParticipantEvent> onVideoTrackUnsubscribed;

  /// Represents a remote user that is connected to a [Room].
  RemoteParticipant(this._identity, this._sid)
      : assert(_identity != null),
        assert(_sid != null) {
    onAudioTrackDisabled = _onAudioTrackDisabled.stream;
    onAudioTrackEnabled = _onAudioTrackEnabled.stream;
    onAudioTrackPublished = _onAudioTrackPublished.stream;
    onAudioTrackSubscribed = _onAudioTrackSubscribed.stream;
    onAudioTrackSubscriptionFailed = _onAudioTrackSubscriptionFailed.stream;
    onAudioTrackUnpublished = _onAudioTrackUnpublished.stream;
    onAudioTrackUnsubscribed = _onAudioTrackUnsubscribed.stream;

    onVideoTrackDisabled = _onVideoTrackDisabled.stream;
    onVideoTrackEnabled = _onVideoTrackEnabled.stream;
    onVideoTrackPublished = _onVideoTrackPublished.stream;
    onVideoTrackSubscribed = _onVideoTrackSubscribed.stream;
    onVideoTrackSubscriptionFailed = _onVideoTrackSubscriptionFailed.stream;
    onVideoTrackUnpublished = _onVideoTrackUnpublished.stream;
    onVideoTrackUnsubscribed = _onVideoTrackUnsubscribed.stream;
  }

  /// Construct from a map.
  factory RemoteParticipant._fromMap(Map<String, dynamic> map) {
    final remoteParticipant = RemoteParticipant(map['identity'], map['sid']);
    remoteParticipant._updateFromMap(map);
    return remoteParticipant;
  }

  /// Dispose the event streams.
  void _dispose() {
    _closeStreams();
  }

  Future<void> _closeStreams() async {
    await _onAudioTrackDisabled.close();
    await _onAudioTrackEnabled.close();
    await _onAudioTrackPublished.close();
    await _onAudioTrackSubscribed.close();
    await _onAudioTrackSubscriptionFailed.close();
    await _onAudioTrackUnpublished.close();
    await _onAudioTrackUnsubscribed.close();

    await _onVideoTrackDisabled.close();
    await _onVideoTrackEnabled.close();
    await _onVideoTrackPublished.close();
    await _onVideoTrackSubscribed.close();
    await _onVideoTrackSubscriptionFailed.close();
    await _onVideoTrackUnpublished.close();
    await _onVideoTrackUnsubscribed.close();
  }

  /// Update properties from a map.
  void _updateFromMap(Map<String, dynamic> map) {
    if (map['remoteVideoTrackPublications'] != null) {
      final List<Map<String, dynamic>> remoteVideoTrackPublicationsList = map['remoteVideoTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final remoteVideoTrackPublicationMap in remoteVideoTrackPublicationsList) {
        final remoteVideoTrackPublication = _remoteVideoTrackPublications.firstWhere(
          (p) => p.trackSid == remoteVideoTrackPublicationMap['sid'],
          orElse: () => RemoteVideoTrackPublication._fromMap(remoteVideoTrackPublicationMap, this),
        );
        if (!_remoteVideoTrackPublications.contains(remoteVideoTrackPublication)) {
          _remoteVideoTrackPublications.add(remoteVideoTrackPublication);
        }
        remoteVideoTrackPublication._updateFromMap(remoteVideoTrackPublicationMap);
      }
    }

    if (map['remoteAudioTrackPublications'] != null) {
      final List<Map<String, dynamic>> remoteAudioTrackPublicationsList = map['remoteAudioTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final remoteAudioTrackPublicationMap in remoteAudioTrackPublicationsList) {
        final remoteAudioTrackPublication = _remoteAudioTrackPublications.firstWhere(
          (p) => p.trackSid == remoteAudioTrackPublicationMap['sid'],
          orElse: () => RemoteAudioTrackPublication._fromMap(remoteAudioTrackPublicationMap),
        );
        if (!_remoteAudioTrackPublications.contains(remoteAudioTrackPublication)) {
          _remoteAudioTrackPublications.add(remoteAudioTrackPublication);
        }
        remoteAudioTrackPublication._updateFromMap(remoteAudioTrackPublicationMap);
      }
    }
  }

  /// Parse the native remote participant events to the right event streams.
  void _parseEvents(dynamic event) {
    final String eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);

    RemoteVideoTrackPublication remoteVideoTrackPublication;
    if (data['remoteVideoTrackPublication'] != null) {
      final remoteVideoTrackPublicationMap = Map<String, dynamic>.from(data['remoteVideoTrackPublication']);
      remoteVideoTrackPublication = _remoteVideoTrackPublications.firstWhere(
        (RemoteVideoTrackPublication p) => p.trackSid == remoteVideoTrackPublicationMap['sid'],
        orElse: () => RemoteVideoTrackPublication._fromMap(remoteVideoTrackPublicationMap, this),
      );
      if (!_remoteVideoTrackPublications.contains(remoteVideoTrackPublication)) {
        _remoteVideoTrackPublications.add(remoteVideoTrackPublication);
      }
      remoteVideoTrackPublication._updateFromMap(remoteVideoTrackPublicationMap);
    }

    RemoteVideoTrack remoteVideoTrack;
    if (['videoTrackSubscribed', 'videoTrackUnsubscribed', 'videoTrackEnabled', 'videoTrackDisabled'].contains(eventName)) {
      assert(remoteVideoTrackPublication != null);
      remoteVideoTrack = remoteVideoTrackPublication.remoteVideoTrack;
      if (remoteVideoTrack == null) {
        final remoteVideoTrackMap = Map<String, dynamic>.from(data['remoteVideoTrack']);
        remoteVideoTrack = RemoteVideoTrack._fromMap(remoteVideoTrackMap, this);
      }
    }

    RemoteAudioTrackPublication remoteAudioTrackPublication;
    if (data['remoteAudioTrackPublication'] != null) {
      final remoteAudioTrackPublicationMap = Map<String, dynamic>.from(data['remoteAudioTrackPublication']);
      remoteAudioTrackPublication = _remoteAudioTrackPublications.firstWhere(
        (RemoteAudioTrackPublication p) => p.trackSid == remoteAudioTrackPublicationMap['sid'],
        orElse: () => RemoteAudioTrackPublication._fromMap(remoteAudioTrackPublicationMap),
      );
      if (!_remoteAudioTrackPublications.contains(remoteAudioTrackPublication)) {
        _remoteAudioTrackPublications.add(remoteAudioTrackPublication);
      }
      remoteAudioTrackPublication._updateFromMap(remoteAudioTrackPublicationMap);
    }

    RemoteAudioTrack remoteAudioTrack;
    if (['audioTrackSubscribed', 'audioTrackUnsubscribed', 'audioTrackEnabled', 'audioTrackDisabled'].contains(eventName)) {
      assert(remoteAudioTrackPublication != null);
      remoteAudioTrack = remoteAudioTrackPublication.remoteAudioTrack;
      if (remoteAudioTrack == null) {
        final remoteAudioTrackMap = Map<String, dynamic>.from(data['remoteAudioTrack']);
        remoteAudioTrack = RemoteAudioTrack._fromMap(remoteAudioTrackMap);
      }
    }

    TwilioException exception;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      exception = TwilioException(errorMap['code'] as int, errorMap['message']);
    }

    final remoteParticipantEvent = RemoteParticipantEvent(
      remoteParticipant: this,
      remoteAudioTrack: remoteAudioTrack,
      remoteAudioTrackPublication: remoteAudioTrackPublication,
      remoteVideoTrack: remoteVideoTrack,
      remoteVideoTrackPublication: remoteVideoTrackPublication,
    );

    switch (eventName) {
      case 'audioTrackDisabled':
        assert(remoteAudioTrackPublication != null);
        _onAudioTrackDisabled.add(remoteParticipantEvent);
        break;
      case 'audioTrackEnabled':
        assert(remoteAudioTrackPublication != null);
        _onAudioTrackEnabled.add(remoteParticipantEvent);
        break;
      case 'audioTrackPublished':
        assert(remoteAudioTrackPublication != null);
        _onAudioTrackPublished.add(remoteParticipantEvent);
        break;
      case 'audioTrackSubscribed':
        assert(remoteAudioTrackPublication != null);
        assert(remoteAudioTrack != null);
        _onAudioTrackSubscribed.add(remoteParticipantEvent);
        break;
      case 'audioTrackSubscriptionFailed':
        assert(remoteAudioTrackPublication != null);
        assert(exception != null);
        _onAudioTrackSubscriptionFailed.add(remoteParticipantEvent);
        break;
      case 'audioTrackUnpublished':
        assert(remoteAudioTrackPublication != null);
        _onAudioTrackUnpublished.add(remoteParticipantEvent);
        break;
      case 'audioTrackUnsubscribed':
        assert(remoteAudioTrackPublication != null);
        assert(remoteAudioTrack != null);
        _remoteAudioTrackPublications.remove(remoteAudioTrackPublication);
        _onAudioTrackUnsubscribed.add(remoteParticipantEvent);
        break;
      case 'videoTrackDisabled':
        assert(remoteVideoTrackPublication != null);
        _onVideoTrackDisabled.add(remoteParticipantEvent);
        break;
      case 'videoTrackEnabled':
        assert(remoteVideoTrackPublication != null);
        _onVideoTrackEnabled.add(remoteParticipantEvent);
        break;
      case 'videoTrackPublished':
        assert(remoteVideoTrackPublication != null);
        _onVideoTrackPublished.add(remoteParticipantEvent);
        break;
      case 'videoTrackSubscribed':
        assert(remoteVideoTrackPublication != null);
        assert(remoteVideoTrack != null);
        _onVideoTrackSubscribed.add(remoteParticipantEvent);
        break;
      case 'videoTrackSubscriptionFailed':
        assert(remoteVideoTrackPublication != null);
        assert(exception != null);
        _onVideoTrackSubscriptionFailed.add(remoteParticipantEvent);
        break;
      case 'videoTrackUnpublished':
        assert(remoteVideoTrackPublication != null);
        _onVideoTrackUnpublished.add(remoteParticipantEvent);
        break;
      case 'videoTrackUnsubscribed':
        assert(remoteVideoTrackPublication != null);
        assert(remoteVideoTrack != null);
        _remoteVideoTrackPublications.remove(remoteVideoTrackPublication);
        _onVideoTrackUnsubscribed.add(remoteParticipantEvent);
        break;
    }
  }
}
