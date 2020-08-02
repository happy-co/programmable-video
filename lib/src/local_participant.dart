part of twilio_programmable_video;

/// Represents the local participant of a [Room] you are connected to.
class LocalParticipant implements Participant {
  final String _identity;

  final String _sid;

  final String _signalingRegion;

  NetworkQualityLevel _networkQualityLevel;

  final List<LocalAudioTrackPublication> _localAudioTrackPublications = <LocalAudioTrackPublication>[];

  final List<LocalDataTrackPublication> _localDataTrackPublications = <LocalDataTrackPublication>[];

  final List<LocalVideoTrackPublication> _localVideoTrackPublications = <LocalVideoTrackPublication>[];

  final StreamController<LocalAudioTrackPublishedEvent> _onAudioTrackPublished = StreamController<LocalAudioTrackPublishedEvent>.broadcast();

  /// Notifies  the listener that a [LocalAudioTrack] has been shared to a [Room].
  /// Note: If a [LocalAudioTrack] was provided in [ConnectOptions] this event will
  /// not be triggered because the track is published prior to [Room.onConnected]
  /// being raised.
  Stream<LocalAudioTrackPublishedEvent> onAudioTrackPublished;

  final StreamController<LocalAudioTrackPublicationFailedEvent> _onAudioTrackPublicationFailed = StreamController<LocalAudioTrackPublicationFailedEvent>.broadcast();

  /// the listener that the [LocalParticipant] failed to publish a
  /// [LocalAudioTrack] to a Room.
  Stream<LocalAudioTrackPublicationFailedEvent> onAudioTrackPublicationFailed;

  final StreamController<LocalDataTrackPublishedEvent> _onDataTrackPublished = StreamController<LocalDataTrackPublishedEvent>.broadcast();

  /// Notifies  the listener that a [LocalDataTrack] has been shared to a [Room].
  Stream<LocalDataTrackPublishedEvent> onDataTrackPublished;

  final StreamController<LocalDataTrackPublicationFailedEvent> _onDataTrackPublicationFailed = StreamController<LocalDataTrackPublicationFailedEvent>.broadcast();

  /// Notifies the listener that the [LocalParticipant] failed to publish a
  /// [LocalDataTrack] to a [Room].
  Stream<LocalDataTrackPublicationFailedEvent> onDataTrackPublicationFailed;

  final StreamController<LocalVideoTrackPublishedEvent> _onVideoTrackPublished = StreamController<LocalVideoTrackPublishedEvent>.broadcast();

  /// Notifies the listener that a [LocalVideoTrack] has been shared to a [Room].
  /// Note: If a [LocalVideoTrack] was provided in [ConnectOptions] this event will
  /// not be triggered because the track is published prior to [Room.onConnected]
  /// being raised.
  Stream<LocalVideoTrackPublishedEvent> onVideoTrackPublished;

  final StreamController<LocalVideoTrackPublicationFailedEvent> _onVideoTrackPublicationFailed = StreamController<LocalVideoTrackPublicationFailedEvent>.broadcast();

  /// Notifies the listener that the [LocalParticipant] failed to publish a
  /// [LocalVideoTrack] to a [Room].
  Stream<LocalVideoTrackPublicationFailedEvent> onVideoTrackPublicationFailed;

  /// The SID of this [LocalParticipant].
  @override
  String get sid => _sid;

  /// The identity of this [LocalParticipant].
  @override
  String get identity => _identity;

  /// Where the [LocalParticipant] signalling traffic enters and exits
  /// Twilio's communications cloud.
  ///
  /// This property reflects the region passed to [ConnectOptions.region]
  /// and when `gll` (the default value) is provided, the region that was
  /// selected will use latency based routing.
  String get signalingRegion => _signalingRegion;

  /// The network quality of the [LocalParticipant].
  NetworkQualityLevel get networkQualityLevel => _networkQualityLevel;

  /// Read-only list of local audio track publications.
  List<LocalAudioTrackPublication> get localAudioTracks => [..._localAudioTrackPublications];

  /// Read-only list of local data track publications.
  List<LocalDataTrackPublication> get localDataTracks => [..._localDataTrackPublications];

  /// Read-only list of local video track publications.
  List<LocalVideoTrackPublication> get localVideoTracks => [..._localVideoTrackPublications];

  /// Read-only list of audio track publications.
  @override
  List<AudioTrackPublication> get audioTracks => [..._localAudioTrackPublications];

  /// Read-only list of data track publications.
  List<DataTrackPublication> get dataTracks => [..._localDataTrackPublications];

  /// Read-only list of video track publications.
  @override
  List<VideoTrackPublication> get videoTracks {
    return [..._localVideoTrackPublications];
  }

  LocalParticipant(this._identity, this._sid, this._signalingRegion)
      : assert(_identity != null),
        assert(_sid != null),
        assert(_signalingRegion != null) {
    onAudioTrackPublished = _onAudioTrackPublished.stream;
    onAudioTrackPublicationFailed = _onAudioTrackPublicationFailed.stream;
    onDataTrackPublished = _onDataTrackPublished.stream;
    onDataTrackPublicationFailed = _onDataTrackPublicationFailed.stream;
    onVideoTrackPublished = _onVideoTrackPublished.stream;
    onVideoTrackPublicationFailed = _onVideoTrackPublicationFailed.stream;
  }

  /// Reset the video of the local participant.
  Future<void> resetVideo() async {
    return const MethodChannel('twilio_programmable_video').invokeMethod('LocalParticipant#resetVideo', <String, dynamic>{});
  }

  /// Dispose the LocalParticipant
  void _dispose() {
    _closeStreams();
  }

  /// Dispose the event streams.
  Future<void> _closeStreams() async {
    await _onAudioTrackPublished.close();
    await _onAudioTrackPublicationFailed.close();
    await _onDataTrackPublished.close();
    await _onDataTrackPublicationFailed.close();
    await _onVideoTrackPublished.close();
    await _onVideoTrackPublicationFailed.close();
  }

  /// Construct from a map.
  factory LocalParticipant._fromMap(Map<String, dynamic> map) {
    var localParticipant = LocalParticipant(map['identity'], map['sid'], map['signalingRegion']);
    localParticipant._updateFromMap(map);
    return localParticipant;
  }

  /// Update properties from a map.
  void _updateFromMap(Map<String, dynamic> map) {
    _networkQualityLevel = EnumToString.fromString(NetworkQualityLevel.values, map['networkQualityLevel']) ?? NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN;

    if (map['localAudioTrackPublications'] != null) {
      final List<Map<String, dynamic>> localAudioTrackPublicationsList = map['localAudioTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final localAudioTrackPublicationMap in localAudioTrackPublicationsList) {
        final localAudioTrackPublication = _localAudioTrackPublications.firstWhere(
          (p) => p.trackSid == localAudioTrackPublicationMap['sid'],
          orElse: () => LocalAudioTrackPublication._fromMap(localAudioTrackPublicationMap),
        );
        if (!_localAudioTrackPublications.contains(localAudioTrackPublication)) {
          _localAudioTrackPublications.add(localAudioTrackPublication);
        }
        localAudioTrackPublication._updateFromMap(localAudioTrackPublicationMap);
      }
    }

    if (map['localDataTrackPublications'] != null) {
      final List<Map<String, dynamic>> localDataTrackPublicationsList = map['localDataTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final localDataTrackPublicationMap in localDataTrackPublicationsList) {
        final localDataTrackPublication = _localDataTrackPublications.firstWhere(
          (p) => p.trackSid == localDataTrackPublicationMap['sid'],
          orElse: () => LocalDataTrackPublication._fromMap(localDataTrackPublicationMap),
        );
        if (!_localDataTrackPublications.contains(localDataTrackPublication)) {
          _localDataTrackPublications.add(localDataTrackPublication);
        }
        localDataTrackPublication._updateFromMap(localDataTrackPublicationMap);
      }
    }

    if (map['localVideoTrackPublications'] != null) {
      final List<Map<String, dynamic>> localVideoTrackPublicationsList = map['localVideoTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final localVideoTrackPublicationMap in localVideoTrackPublicationsList) {
        final localVideoTrackPublication = _localVideoTrackPublications.firstWhere(
          (p) => p.trackSid == localVideoTrackPublicationMap['sid'],
          orElse: () => LocalVideoTrackPublication._fromMap(localVideoTrackPublicationMap),
        );
        if (!_localVideoTrackPublications.contains(localVideoTrackPublication)) {
          _localVideoTrackPublications.add(localVideoTrackPublication);
        }
        localVideoTrackPublication._updateFromMap(localVideoTrackPublicationMap);
      }
    }
  }

  /// Parse the native local participant events to the right event streams.
  void _parseEvents(dynamic event) {
    final String eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);

    LocalAudioTrackPublication localAudioTrackPublication;
    if (data['localAudioTrackPublication'] != null) {
      final localAudioTrackPublicationMap = Map<String, dynamic>.from(data['localAudioTrackPublication']);
      localAudioTrackPublication = _localAudioTrackPublications.firstWhere(
        (LocalAudioTrackPublication p) => p.trackSid == localAudioTrackPublicationMap['sid'],
        orElse: () => LocalAudioTrackPublication._fromMap(localAudioTrackPublicationMap),
      );
      if (!_localAudioTrackPublications.contains(localAudioTrackPublication)) {
        _localAudioTrackPublications.add(localAudioTrackPublication);
      }
      localAudioTrackPublication._updateFromMap(localAudioTrackPublicationMap);
    }

    LocalAudioTrack localAudioTrack;
    if (data['localAudioTrack'] != null) {
      final localAudioTrackMap = Map<String, dynamic>.from(data['localAudioTrack']);
      localAudioTrack = LocalAudioTrack._fromMap(localAudioTrackMap);
    }

    LocalDataTrackPublication localDataTrackPublication;
    if (data['localDataTrackPublication'] != null) {
      final localDataTrackPublicationMap = Map<String, dynamic>.from(data['localDataTrackPublication']);
      localDataTrackPublication = _localDataTrackPublications.firstWhere(
        (LocalDataTrackPublication p) => p.trackSid == localDataTrackPublicationMap['sid'],
        orElse: () => LocalDataTrackPublication._fromMap(localDataTrackPublicationMap),
      );
      if (!_localDataTrackPublications.contains(localDataTrackPublication)) {
        _localDataTrackPublications.add(localDataTrackPublication);
      }
      localDataTrackPublication._updateFromMap(localDataTrackPublicationMap);
    }

    LocalDataTrack localDataTrack;
    if (data['localDataTrack'] != null) {
      final localDataTrackMap = Map<String, dynamic>.from(data['localDataTrack']);
      localDataTrack = LocalDataTrack._fromMap(localDataTrackMap);
    }

    LocalVideoTrackPublication localVideoTrackPublication;
    if (data['localVideoTrackPublication'] != null) {
      final localVideoTrackPublicationMap = Map<String, dynamic>.from(data['localVideoTrackPublication']);
      localVideoTrackPublication = _localVideoTrackPublications.firstWhere(
        (LocalVideoTrackPublication p) => p.trackSid == localVideoTrackPublicationMap['sid'],
        orElse: () => LocalVideoTrackPublication._fromMap(localVideoTrackPublicationMap),
      );
      if (!_localVideoTrackPublications.contains(localVideoTrackPublication)) {
        _localVideoTrackPublications.add(localVideoTrackPublication);
      }
      localVideoTrackPublication._updateFromMap(localVideoTrackPublicationMap);
    }

    LocalVideoTrack localVideoTrack;
    if (data['localVideoTrack'] != null) {
      final localVideoTrackMap = Map<String, dynamic>.from(data['localVideoTrack']);
      localVideoTrack = LocalVideoTrack._fromMap(localVideoTrackMap);
    }

    TwilioException twilioException;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      twilioException = TwilioException(errorMap['code'] as int, errorMap['message']);
    }

    switch (eventName) {
      case 'audioTrackPublished':
        assert(localAudioTrackPublication != null);
        _onAudioTrackPublished.add(LocalAudioTrackPublishedEvent(this, localAudioTrackPublication));
        break;
      case 'audioTrackPublicationFailed':
        assert(localAudioTrack != null);
        _onAudioTrackPublicationFailed.add(LocalAudioTrackPublicationFailedEvent(this, localAudioTrack, twilioException));
        break;
      case 'dataTrackPublished':
        assert(localDataTrackPublication != null);
        _onDataTrackPublished.add(LocalDataTrackPublishedEvent(this, localDataTrackPublication));
        break;
      case 'dataTrackPublicationFailed':
        assert(localDataTrack != null);
        _onDataTrackPublicationFailed.add(LocalDataTrackPublicationFailedEvent(this, localDataTrack, twilioException));
        break;
      case 'videoTrackPublished':
        assert(localVideoTrackPublication != null);
        _onVideoTrackPublished.add(LocalVideoTrackPublishedEvent(this, localVideoTrackPublication));
        break;
      case 'videoTrackPublicationFailed':
        assert(localVideoTrack != null);
        _onVideoTrackPublicationFailed.add(LocalVideoTrackPublicationFailedEvent(this, localVideoTrack, twilioException));
        break;
    }
  }
}
