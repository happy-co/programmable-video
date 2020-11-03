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

  final StreamController<LocalNetworkQualityLevelChangedEvent> _onNetworkQualityLevelChanged = StreamController<LocalNetworkQualityLevelChangedEvent>.broadcast();

  /// Notifies the listener that the [LocalParticipant]'s [NetworkQualityLevel] has changed.
  Stream<LocalNetworkQualityLevelChangedEvent> onNetworkQualityLevelChanged;

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
  @override
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
    onNetworkQualityLevelChanged = _onNetworkQualityLevelChanged.stream;
    onVideoTrackPublished = _onVideoTrackPublished.stream;
    onVideoTrackPublicationFailed = _onVideoTrackPublicationFailed.stream;
  }

  /// Dispose the LocalParticipant
  void _dispose() {
    _closeStreams();
    _localVideoTrackPublications.forEach((videoTrack) => videoTrack.localVideoTrack._dispose());
  }

  /// Dispose the event streams.
  Future<void> _closeStreams() async {
    await _onAudioTrackPublished.close();
    await _onAudioTrackPublicationFailed.close();
    await _onDataTrackPublished.close();
    await _onDataTrackPublicationFailed.close();
    await _onNetworkQualityLevelChanged.close();
    await _onVideoTrackPublished.close();
    await _onVideoTrackPublicationFailed.close();
  }

  /// Construct from a [LocalParticipantModel].
  factory LocalParticipant._fromModel(LocalParticipantModel model) {
    var localParticipant = LocalParticipant(model.identity, model.sid, model.signalingRegion);
    localParticipant._updateFromModel(model);
    return localParticipant;
  }

  /// Update properties from a [LocalParticipantModel].
  void _updateFromModel(LocalParticipantModel model) {
    _networkQualityLevel = model.networkQualityLevel;

    if (model.localAudioTrackPublications != null) {
      for (final localAudioTrackPublicationModel in model.localAudioTrackPublications) {
        final localAudioTrackPublication = _localAudioTrackPublications.firstWhere(
          (p) => p.trackSid == localAudioTrackPublicationModel.sid,
          orElse: () => LocalAudioTrackPublication._fromModel(localAudioTrackPublicationModel),
        );
        if (!_localAudioTrackPublications.contains(localAudioTrackPublication)) {
          _localAudioTrackPublications.add(localAudioTrackPublication);
        }
        localAudioTrackPublication._updateFromModel(localAudioTrackPublicationModel);
      }
    }

    if (model.localDataTrackPublications != null) {
      for (final localDataTrackPublicationModel in model.localDataTrackPublications) {
        final localDataTrackPublication = _localDataTrackPublications.firstWhere(
          (p) => p.trackSid == localDataTrackPublicationModel.sid,
          orElse: () => LocalDataTrackPublication._fromModel(localDataTrackPublicationModel),
        );
        if (!_localDataTrackPublications.contains(localDataTrackPublication)) {
          _localDataTrackPublications.add(localDataTrackPublication);
        }
        localDataTrackPublication._updateFromModel(localDataTrackPublicationModel);
      }
    }

    if (model.localVideoTrackPublications != null) {
      for (final localVideoTrackPublicationModel in model.localVideoTrackPublications) {
        final localVideoTrackPublication = _localVideoTrackPublications.firstWhere(
          (p) => p.trackSid == localVideoTrackPublicationModel.sid,
          orElse: () => LocalVideoTrackPublication._fromModel(localVideoTrackPublicationModel),
        );
        if (!_localVideoTrackPublications.contains(localVideoTrackPublication)) {
          _localVideoTrackPublications.add(localVideoTrackPublication);
        }
        localVideoTrackPublication._updateFromModel(localVideoTrackPublicationModel);
      }
    }
  }

  /// Parse the native local participant events to the right event streams.
  void _parseEvents(BaseLocalParticipantEvent event) {
    if (event is SkipAbleLocalParticipantEvent) return;
    _updateFromModel(event.localParticipantModel);

    if (event is LocalAudioTrackPublished) {
      final localAudioTrackPublication = _localAudioTrackPublications.firstWhere((LocalAudioTrackPublication p) => p.trackSid == event.publicationModel.sid, orElse: () => LocalAudioTrackPublication._fromModel(event.publicationModel));
      _onAudioTrackPublished.add(LocalAudioTrackPublishedEvent(this, localAudioTrackPublication));
    } else if (event is LocalAudioTrackPublicationFailed) {
      final localAudioTrack = LocalAudioTrack._fromModel(event.localAudioTrack);
      _onAudioTrackPublicationFailed.add(LocalAudioTrackPublicationFailedEvent(this, localAudioTrack, TwilioException._fromModel(event.exception)));
    } else if (event is LocalDataTrackPublished) {
      final localDataTrackPublication = _localDataTrackPublications.firstWhere((LocalDataTrackPublication p) => p.trackSid == event.publicationModel.sid, orElse: () => LocalDataTrackPublication._fromModel(event.publicationModel));
      _onDataTrackPublished.add(LocalDataTrackPublishedEvent(this, localDataTrackPublication));
    } else if (event is LocalDataTrackPublicationFailed) {
      final localDataTrack = LocalDataTrack._fromModel(event.localDataTrack);
      _onDataTrackPublicationFailed.add(LocalDataTrackPublicationFailedEvent(this, localDataTrack, TwilioException._fromModel(event.exception)));
    } else if (event is LocalVideoTrackPublished) {
      final localVideoTrackPublication = _localVideoTrackPublications.firstWhere((LocalVideoTrackPublication p) => p.trackSid == event.publicationModel.sid, orElse: () => LocalVideoTrackPublication._fromModel(event.publicationModel));
      _onVideoTrackPublished.add(LocalVideoTrackPublishedEvent(this, localVideoTrackPublication));
    } else if (event is LocalVideoTrackPublicationFailed) {
      final localVideoTrack = LocalVideoTrack._fromModel(event.localVideoTrack);
      _onVideoTrackPublicationFailed.add(LocalVideoTrackPublicationFailedEvent(this, localVideoTrack, TwilioException._fromModel(event.exception)));
    } else if (event is LocalNetworkQualityLevelChanged) {
      _onNetworkQualityLevelChanged.add(LocalNetworkQualityLevelChangedEvent(this, event.networkQualityLevel));
    }
  }
}
