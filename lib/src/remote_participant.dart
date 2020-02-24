part of twilio_programmable_video;

/// A participant represents a remote user that can connect to a [Room].
class RemoteParticipant implements Participant {
  final String _identity;

  final String _sid;

  final List<RemoteAudioTrackPublication> _remoteAudioTrackPublications = <RemoteAudioTrackPublication>[];

  final List<RemoteDataTrackPublication> _remoteDataTrackPublications = <RemoteDataTrackPublication>[];

  final List<RemoteVideoTrackPublication> _remoteVideoTrackPublications = <RemoteVideoTrackPublication>[];

  /// The SID of the [RemoteParticipant].
  @override
  String get sid => _sid;

  /// The identity of the [RemoteParticipant].
  @override
  String get identity => _identity;

  /// Read-only list of [RemoteAudioTrackPublication].
  List<RemoteAudioTrackPublication> get remoteAudioTracks => [..._remoteAudioTrackPublications];

  /// Read-only list of [RemoteDataTrackPublication].
  List<RemoteDataTrackPublication> get remoteDataTracks => [..._remoteDataTrackPublications];

  /// Read-only list of [RemoteVideoTrackPublication].
  List<RemoteVideoTrackPublication> get remoteVideoTracks => [..._remoteVideoTrackPublications];

  /// Read-only list of [AudioTrackPublication].
  @override
  List<AudioTrackPublication> get audioTracks => [..._remoteAudioTrackPublications];

  /// Read-only list of data track publications.
  List<DataTrackPublication> get dataTracks => [..._remoteDataTrackPublications];

  /// Read-only list of [VideoTrackPublication].
  @override
  List<VideoTrackPublication> get videoTracks => [..._remoteVideoTrackPublications];

  final StreamController<RemoteAudioTrackEvent> _onAudioTrackDisabled = StreamController<RemoteAudioTrackEvent>.broadcast();

  /// Notifies the listener that an [AudioTrack] has been disabled.
  Stream<RemoteAudioTrackEvent> onAudioTrackDisabled;

  final StreamController<RemoteAudioTrackEvent> _onAudioTrackEnabled = StreamController<RemoteAudioTrackEvent>.broadcast();

  /// Notifies the listener that [AudioTrack] has been enabled.
  Stream<RemoteAudioTrackEvent> onAudioTrackEnabled;

  final StreamController<RemoteAudioTrackEvent> _onAudioTrackPublished = StreamController<RemoteAudioTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has published a [RemoteAudioTrack] to this [Room].
  /// The audio of the track is not audible until the track has been subscribed to.
  Stream<RemoteAudioTrackEvent> onAudioTrackPublished;

  final StreamController<RemoteAudioTrackSubscriptionEvent> _onAudioTrackSubscribed = StreamController<RemoteAudioTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener the [RemoteAudioTrack] of the [RemoteParticipant] has been subscribed to.
  /// The audio track is audible after this event.
  Stream<RemoteAudioTrackSubscriptionEvent> onAudioTrackSubscribed;

  final StreamController<RemoteAudioTrackSubscriptionFailedEvent> _onAudioTrackSubscriptionFailed = StreamController<RemoteAudioTrackSubscriptionFailedEvent>.broadcast();

  /// Notifies the listener that media negotiation for a [RemoteAudioTrack] failed.
  Stream<RemoteAudioTrackSubscriptionFailedEvent> onAudioTrackSubscriptionFailed;

  final StreamController<RemoteAudioTrackEvent> _onAudioTrackUnpublished = StreamController<RemoteAudioTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has unpublished a [RemoteAudioTrack] from this [Room].
  Stream<RemoteAudioTrackEvent> onAudioTrackUnpublished;

  final StreamController<RemoteAudioTrackSubscriptionEvent> _onAudioTrackUnsubscribed = StreamController<RemoteAudioTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener that the [RemoteAudioTrack] of the [RemoteParticipant] has been unsubscribed from.
  /// The track is no longer audible after being unsubscribed from the audio track.
  Stream<RemoteAudioTrackSubscriptionEvent> onAudioTrackUnsubscribed;

  final StreamController<RemoteDataTrackEvent> _onDataTrackPublished = StreamController<RemoteDataTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has published a [RemoteDataTrack] to this [Room].
  Stream<RemoteDataTrackEvent> onDataTrackPublished;

  final StreamController<RemoteDataTrackSubscriptionEvent> _onDataTrackSubscribed = StreamController<RemoteDataTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener the [RemoteDataTrack] of the [RemoteParticipant] has been subscribed to.
  Stream<RemoteDataTrackSubscriptionEvent> onDataTrackSubscribed;

  final StreamController<RemoteDataTrackSubscriptionFailedEvent> _onDataTrackSubscriptionFailed = StreamController<RemoteDataTrackSubscriptionFailedEvent>.broadcast();

  /// Notifies the listener that media negotiation for a [RemoteDataTrack] failed.
  Stream<RemoteDataTrackSubscriptionFailedEvent> onDataTrackSubscriptionFailed;

  final StreamController<RemoteDataTrackEvent> _onDataTrackUnpublished = StreamController<RemoteDataTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has remove a [RemoteDataTrack] from this [Room].
  Stream<RemoteDataTrackEvent> onDataTrackUnpublished;

  final StreamController<RemoteDataTrackSubscriptionEvent> _onDataTrackUnsubscribed = StreamController<RemoteDataTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener that the [RemoteDataTrack] of the [RemoteParticipant] has been unsubscribed from.
  Stream<RemoteDataTrackSubscriptionEvent> onDataTrackUnsubscribed;

  final StreamController<RemoteVideoTrackEvent> _onVideoTrackDisabled = StreamController<RemoteVideoTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] video track has been disabled.
  Stream<RemoteVideoTrackEvent> onVideoTrackDisabled;

  final StreamController<RemoteVideoTrackEvent> _onVideoTrackEnabled = StreamController<RemoteVideoTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] video track has been enabled.
  Stream<RemoteVideoTrackEvent> onVideoTrackEnabled;

  final StreamController<RemoteVideoTrackEvent> _onVideoTrackPublished = StreamController<RemoteVideoTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has published a [RemoteVideoTrack] to this [Room].
  /// Video frames will not begin flowing until the video track has been subscribed to.
  Stream<RemoteVideoTrackEvent> onVideoTrackPublished;

  final StreamController<RemoteVideoTrackSubscriptionEvent> _onVideoTrackSubscribed = StreamController<RemoteVideoTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener the [RemoteVideoTrack] of the [RemoteParticipant] has been subscribed to.
  /// Video frames are now flowing and can be rendered.
  Stream<RemoteVideoTrackSubscriptionEvent> onVideoTrackSubscribed;

  final StreamController<RemoteVideoTrackSubscriptionFailedEvent> _onVideoTrackSubscriptionFailed = StreamController<RemoteVideoTrackSubscriptionFailedEvent>.broadcast();

  /// Notifies the listener that media negotiation for a [RemoteVideoTrack] failed.
  Stream<RemoteVideoTrackSubscriptionFailedEvent> onVideoTrackSubscriptionFailed;

  final StreamController<RemoteVideoTrackEvent> _onVideoTrackUnpublished = StreamController<RemoteVideoTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has removed a [RemoteVideoTrack] from this [Room].
  Stream<RemoteVideoTrackEvent> onVideoTrackUnpublished;

  final StreamController<RemoteVideoTrackSubscriptionEvent> _onVideoTrackUnsubscribed = StreamController<RemoteVideoTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener that the [RemoteVideoTrack] of the [RemoteParticipant] has been unsubscribed from.
  Stream<RemoteVideoTrackSubscriptionEvent> onVideoTrackUnsubscribed;

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

    onDataTrackPublished = _onDataTrackPublished.stream;
    onDataTrackSubscribed = _onDataTrackSubscribed.stream;
    onDataTrackSubscriptionFailed = _onDataTrackSubscriptionFailed.stream;
    onDataTrackUnpublished = _onDataTrackUnpublished.stream;
    onDataTrackUnsubscribed = _onDataTrackUnsubscribed.stream;

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

  /// Dispose the RemoteParticipant
  void _dispose() {
    _closeStreams();
  }

  /// Dispose the event streams.
  Future<void> _closeStreams() async {
    await _onAudioTrackDisabled.close();
    await _onAudioTrackEnabled.close();
    await _onAudioTrackPublished.close();
    await _onAudioTrackSubscribed.close();
    await _onAudioTrackSubscriptionFailed.close();
    await _onAudioTrackUnpublished.close();
    await _onAudioTrackUnsubscribed.close();

    await _onDataTrackPublished.close();
    await _onDataTrackSubscribed.close();
    await _onDataTrackSubscriptionFailed.close();
    await _onDataTrackUnpublished.close();
    await _onDataTrackUnsubscribed.close();

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

    if (map['remoteDataTrackPublications'] != null) {
      final List<Map<String, dynamic>> remoteDataTrackPublicationsList = map['remoteDataTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final remoteDataTrackPublicationMap in remoteDataTrackPublicationsList) {
        final remoteDataTrackPublication = _remoteDataTrackPublications.firstWhere(
          (p) => p.trackSid == remoteDataTrackPublicationMap['sid'],
          orElse: () => RemoteDataTrackPublication._fromMap(remoteDataTrackPublicationMap),
        );
        if (!_remoteDataTrackPublications.contains(remoteDataTrackPublication)) {
          _remoteDataTrackPublications.add(remoteDataTrackPublication);
        }
        remoteDataTrackPublication._updateFromMap(remoteDataTrackPublicationMap);
      }
    }

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
  }

  /// Parse the native remote participant events to the right event streams.
  void _parseEvents(dynamic event) {
    final String eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);

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

    RemoteDataTrackPublication remoteDataTrackPublication;
    if (data['remoteDataTrackPublication'] != null) {
      final remoteDataTrackPublicationMap = Map<String, dynamic>.from(data['remoteDataTrackPublication']);
      remoteDataTrackPublication = _remoteDataTrackPublications.firstWhere(
        (RemoteDataTrackPublication p) => p.trackSid == remoteDataTrackPublicationMap['sid'],
        orElse: () => RemoteDataTrackPublication._fromMap(remoteDataTrackPublicationMap),
      );
      if (!_remoteDataTrackPublications.contains(remoteDataTrackPublication)) {
        _remoteDataTrackPublications.add(remoteDataTrackPublication);
      }
      remoteDataTrackPublication._updateFromMap(remoteDataTrackPublicationMap);
    }

    RemoteDataTrack remoteDataTrack;
    if (['dataTrackSubscribed', 'dataTrackUnsubscribed'].contains(eventName)) {
      assert(remoteDataTrackPublication != null);
      remoteDataTrack = remoteDataTrackPublication.remoteDataTrack;
      if (remoteDataTrack == null) {
        final remoteDataTrackMap = Map<String, dynamic>.from(data['remoteDataTrack']);
        remoteDataTrack = RemoteDataTrack._fromMap(remoteDataTrackMap);
      }
    }

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

    TwilioException twilioException;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      twilioException = TwilioException(errorMap['code'] as int, errorMap['message']);
    }

    switch (eventName) {
      case 'audioTrackDisabled':
        assert(remoteAudioTrackPublication != null);
        _onAudioTrackDisabled.add(RemoteAudioTrackEvent(this, remoteAudioTrackPublication));
        break;
      case 'audioTrackEnabled':
        assert(remoteAudioTrackPublication != null);
        _onAudioTrackEnabled.add(RemoteAudioTrackEvent(this, remoteAudioTrackPublication));
        break;
      case 'audioTrackPublished':
        assert(remoteAudioTrackPublication != null);
        _onAudioTrackPublished.add(RemoteAudioTrackEvent(this, remoteAudioTrackPublication));
        break;
      case 'audioTrackSubscribed':
        assert(remoteAudioTrackPublication != null);
        assert(remoteAudioTrack != null);
        _onAudioTrackSubscribed.add(RemoteAudioTrackSubscriptionEvent(this, remoteAudioTrackPublication, remoteAudioTrack));
        break;
      case 'audioTrackSubscriptionFailed':
        assert(remoteAudioTrackPublication != null);
        assert(twilioException != null);
        _onAudioTrackSubscriptionFailed.add(RemoteAudioTrackSubscriptionFailedEvent(this, remoteAudioTrackPublication, twilioException));
        break;
      case 'audioTrackUnpublished':
        assert(remoteAudioTrackPublication != null);
        _onAudioTrackUnpublished.add(RemoteAudioTrackEvent(this, remoteAudioTrackPublication));
        break;
      case 'audioTrackUnsubscribed':
        assert(remoteAudioTrackPublication != null);
        assert(remoteAudioTrack != null);
        _remoteAudioTrackPublications.remove(remoteAudioTrackPublication);
        _onAudioTrackUnsubscribed.add(RemoteAudioTrackSubscriptionEvent(this, remoteAudioTrackPublication, remoteAudioTrack));
        break;
      case 'dataTrackPublished':
        assert(remoteDataTrackPublication != null);
        _onDataTrackPublished.add(RemoteDataTrackEvent(this, remoteDataTrackPublication));
        break;
      case 'dataTrackSubscribed':
        assert(remoteDataTrackPublication != null);
        assert(remoteDataTrack != null);
        _onDataTrackSubscribed.add(RemoteDataTrackSubscriptionEvent(this, remoteDataTrackPublication, remoteDataTrack));
        break;
      case 'dataTrackSubscriptionFailed':
        assert(remoteDataTrackPublication != null);
        assert(twilioException != null);
        _onDataTrackSubscriptionFailed.add(RemoteDataTrackSubscriptionFailedEvent(this, remoteDataTrackPublication, twilioException));
        break;
      case 'dataTrackUnpublished':
        assert(remoteDataTrackPublication != null);
        _onDataTrackUnpublished.add(RemoteDataTrackEvent(this, remoteDataTrackPublication));
        break;
      case 'dataTrackUnsubscribed':
        assert(remoteDataTrackPublication != null);
        assert(remoteDataTrack != null);
        _remoteDataTrackPublications.remove(remoteDataTrackPublication);
        _onDataTrackUnsubscribed.add(RemoteDataTrackSubscriptionEvent(this, remoteDataTrackPublication, remoteDataTrack));
        break;
      case 'videoTrackDisabled':
        assert(remoteVideoTrackPublication != null);
        _onVideoTrackDisabled.add(RemoteVideoTrackEvent(this, remoteVideoTrackPublication));
        break;
      case 'videoTrackEnabled':
        assert(remoteVideoTrackPublication != null);
        _onVideoTrackEnabled.add(RemoteVideoTrackEvent(this, remoteVideoTrackPublication));
        break;
      case 'videoTrackPublished':
        assert(remoteVideoTrackPublication != null);
        _onVideoTrackPublished.add(RemoteVideoTrackEvent(this, remoteVideoTrackPublication));
        break;
      case 'videoTrackSubscribed':
        assert(remoteVideoTrackPublication != null);
        assert(remoteVideoTrack != null);
        _onVideoTrackSubscribed.add(RemoteVideoTrackSubscriptionEvent(this, remoteVideoTrackPublication, remoteVideoTrack));
        break;
      case 'videoTrackSubscriptionFailed':
        assert(remoteVideoTrackPublication != null);
        assert(twilioException != null);
        _onVideoTrackSubscriptionFailed.add(RemoteVideoTrackSubscriptionFailedEvent(this, remoteVideoTrackPublication, twilioException));
        break;
      case 'videoTrackUnpublished':
        assert(remoteVideoTrackPublication != null);
        _onVideoTrackUnpublished.add(RemoteVideoTrackEvent(this, remoteVideoTrackPublication));
        break;
      case 'videoTrackUnsubscribed':
        assert(remoteVideoTrackPublication != null);
        assert(remoteVideoTrack != null);
        _remoteVideoTrackPublications.remove(remoteVideoTrackPublication);
        _onVideoTrackUnsubscribed.add(RemoteVideoTrackSubscriptionEvent(this, remoteVideoTrackPublication, remoteVideoTrack));
        break;
    }
  }
}
