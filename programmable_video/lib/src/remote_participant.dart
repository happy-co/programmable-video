part of twilio_programmable_video;

/// A participant represents a remote user that can connect to a [Room].
class RemoteParticipant implements Participant {
  final String _identity;

  final String? _sid;

  final List<RemoteAudioTrackPublication> _remoteAudioTrackPublications = <RemoteAudioTrackPublication>[];

  final List<RemoteDataTrackPublication> _remoteDataTrackPublications = <RemoteDataTrackPublication>[];

  final List<RemoteVideoTrackPublication> _remoteVideoTrackPublications = <RemoteVideoTrackPublication>[];

  NetworkQualityLevel _networkQualityLevel = NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN;

  /// The SID of the [RemoteParticipant].
  @override
  String? get sid => _sid;

  /// The identity of the [RemoteParticipant].
  @override
  String get identity => _identity;

  /// The network quality of the [RemoteParticipant].
  @override
  NetworkQualityLevel get networkQualityLevel => _networkQualityLevel;

  /// Read-only list of [RemoteAudioTrackPublication].
  List<RemoteAudioTrackPublication> get remoteAudioTracks => [..._remoteAudioTrackPublications];

  /// Read-only list of [RemoteDataTrackPublication].
  List<RemoteDataTrackPublication> get remoteDataTracks => [..._remoteDataTrackPublications];

  /// Read-only list of [RemoteVideoTrackPublication].
  List<RemoteVideoTrackPublication> get remoteVideoTracks => [..._remoteVideoTrackPublications];

  /// Read-only list of [AudioTrackPublication].
  @override
  List<AudioTrackPublication> get audioTracks => [..._remoteAudioTrackPublications];

  /// Read-only list of [VideoTrackPublication].
  @override
  List<VideoTrackPublication> get videoTracks => [..._remoteVideoTrackPublications];

  final StreamController<RemoteAudioTrackEvent> _onAudioTrackDisabled = StreamController<RemoteAudioTrackEvent>.broadcast();

  /// Notifies the listener that an [AudioTrack] has been disabled.
  late Stream<RemoteAudioTrackEvent> onAudioTrackDisabled;

  final StreamController<RemoteAudioTrackEvent> _onAudioTrackEnabled = StreamController<RemoteAudioTrackEvent>.broadcast();

  /// Notifies the listener that [AudioTrack] has been enabled.
  late Stream<RemoteAudioTrackEvent> onAudioTrackEnabled;

  final StreamController<RemoteAudioTrackEvent> _onAudioTrackPublished = StreamController<RemoteAudioTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has published a [RemoteAudioTrack] to this [Room].
  /// The audio of the track is not audible until the track has been subscribed to.
  late Stream<RemoteAudioTrackEvent> onAudioTrackPublished;

  final StreamController<RemoteAudioTrackSubscriptionEvent> _onAudioTrackSubscribed = StreamController<RemoteAudioTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener the [RemoteAudioTrack] of the [RemoteParticipant] has been subscribed to.
  /// The audio track is audible after this event.
  late Stream<RemoteAudioTrackSubscriptionEvent> onAudioTrackSubscribed;

  final StreamController<RemoteAudioTrackSubscriptionFailedEvent> _onAudioTrackSubscriptionFailed = StreamController<RemoteAudioTrackSubscriptionFailedEvent>.broadcast();

  /// Notifies the listener that media negotiation for a [RemoteAudioTrack] failed.
  late Stream<RemoteAudioTrackSubscriptionFailedEvent> onAudioTrackSubscriptionFailed;

  final StreamController<RemoteAudioTrackEvent> _onAudioTrackUnpublished = StreamController<RemoteAudioTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has unpublished a [RemoteAudioTrack] from this [Room].
  late Stream<RemoteAudioTrackEvent> onAudioTrackUnpublished;

  final StreamController<RemoteAudioTrackSubscriptionEvent> _onAudioTrackUnsubscribed = StreamController<RemoteAudioTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener that the [RemoteAudioTrack] of the [RemoteParticipant] has been unsubscribed from.
  /// The track is no longer audible after being unsubscribed from the audio track.
  late Stream<RemoteAudioTrackSubscriptionEvent> onAudioTrackUnsubscribed;

  final StreamController<RemoteDataTrackEvent> _onDataTrackPublished = StreamController<RemoteDataTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has published a [RemoteDataTrack] to this [Room].
  late Stream<RemoteDataTrackEvent> onDataTrackPublished;

  final StreamController<RemoteDataTrackSubscriptionEvent> _onDataTrackSubscribed = StreamController<RemoteDataTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener the [RemoteDataTrack] of the [RemoteParticipant] has been subscribed to.
  late Stream<RemoteDataTrackSubscriptionEvent> onDataTrackSubscribed;

  final StreamController<RemoteDataTrackSubscriptionFailedEvent> _onDataTrackSubscriptionFailed = StreamController<RemoteDataTrackSubscriptionFailedEvent>.broadcast();

  /// Notifies the listener that media negotiation for a [RemoteDataTrack] failed.
  late Stream<RemoteDataTrackSubscriptionFailedEvent> onDataTrackSubscriptionFailed;

  final StreamController<RemoteDataTrackEvent> _onDataTrackUnpublished = StreamController<RemoteDataTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has remove a [RemoteDataTrack] from this [Room].
  late Stream<RemoteDataTrackEvent> onDataTrackUnpublished;

  final StreamController<RemoteDataTrackSubscriptionEvent> _onDataTrackUnsubscribed = StreamController<RemoteDataTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener that the [RemoteDataTrack] of the [RemoteParticipant] has been unsubscribed from.
  late Stream<RemoteDataTrackSubscriptionEvent> onDataTrackUnsubscribed;

  final StreamController<RemoteNetworkQualityLevelChangedEvent> _onNetworkQualityLevelChanged = StreamController<RemoteNetworkQualityLevelChangedEvent>.broadcast();

  /// Notifies the listener that the [RemoteParticipant]'s [NetworkQualityLevel] has changed.
  late Stream<RemoteNetworkQualityLevelChangedEvent> onNetworkQualityLevelChanged;

  final StreamController<RemoteVideoTrackEvent> _onVideoTrackDisabled = StreamController<RemoteVideoTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] video track has been disabled.
  late Stream<RemoteVideoTrackEvent> onVideoTrackDisabled;

  final StreamController<RemoteVideoTrackEvent> _onVideoTrackEnabled = StreamController<RemoteVideoTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] video track has been enabled.
  late Stream<RemoteVideoTrackEvent> onVideoTrackEnabled;

  final StreamController<RemoteVideoTrackEvent> _onVideoTrackPublished = StreamController<RemoteVideoTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has published a [RemoteVideoTrack] to this [Room].
  /// Video frames will not begin flowing until the video track has been subscribed to.
  late Stream<RemoteVideoTrackEvent> onVideoTrackPublished;

  final StreamController<RemoteVideoTrackSubscriptionEvent> _onVideoTrackSubscribed = StreamController<RemoteVideoTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener the [RemoteVideoTrack] of the [RemoteParticipant] has been subscribed to.
  /// Video frames are now flowing and can be rendered.
  late Stream<RemoteVideoTrackSubscriptionEvent> onVideoTrackSubscribed;

  final StreamController<RemoteVideoTrackSubscriptionFailedEvent> _onVideoTrackSubscriptionFailed = StreamController<RemoteVideoTrackSubscriptionFailedEvent>.broadcast();

  /// Notifies the listener that media negotiation for a [RemoteVideoTrack] failed.
  late Stream<RemoteVideoTrackSubscriptionFailedEvent> onVideoTrackSubscriptionFailed;

  final StreamController<RemoteVideoTrackEvent> _onVideoTrackUnpublished = StreamController<RemoteVideoTrackEvent>.broadcast();

  /// Notifies the listener that a [RemoteParticipant] has removed a [RemoteVideoTrack] from this [Room].
  late Stream<RemoteVideoTrackEvent> onVideoTrackUnpublished;

  final StreamController<RemoteVideoTrackSubscriptionEvent> _onVideoTrackUnsubscribed = StreamController<RemoteVideoTrackSubscriptionEvent>.broadcast();

  /// Notifies the listener that the [RemoteVideoTrack] of the [RemoteParticipant] has been unsubscribed from.
  late Stream<RemoteVideoTrackSubscriptionEvent> onVideoTrackUnsubscribed;

  /// Represents a remote user that is connected to a [Room].
  RemoteParticipant(this._identity, this._sid) {
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

    onNetworkQualityLevelChanged = _onNetworkQualityLevelChanged.stream;

    onVideoTrackDisabled = _onVideoTrackDisabled.stream;
    onVideoTrackEnabled = _onVideoTrackEnabled.stream;
    onVideoTrackPublished = _onVideoTrackPublished.stream;
    onVideoTrackSubscribed = _onVideoTrackSubscribed.stream;
    onVideoTrackSubscriptionFailed = _onVideoTrackSubscriptionFailed.stream;
    onVideoTrackUnpublished = _onVideoTrackUnpublished.stream;
    onVideoTrackUnsubscribed = _onVideoTrackUnsubscribed.stream;
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

    await _onNetworkQualityLevelChanged.close();

    await _onVideoTrackDisabled.close();
    await _onVideoTrackEnabled.close();
    await _onVideoTrackPublished.close();
    await _onVideoTrackSubscribed.close();
    await _onVideoTrackSubscriptionFailed.close();
    await _onVideoTrackUnpublished.close();
    await _onVideoTrackUnsubscribed.close();
  }

  /// Construct from a [RemoteParticipantModel].
  factory RemoteParticipant._fromModel(RemoteParticipantModel model) {
    final remoteParticipant = RemoteParticipant(model.identity, model.sid);
    remoteParticipant._updateFromModel(model);
    return remoteParticipant;
  }

  /// Update properties from a [RemoteParticipantModel].
  void _updateFromModel(RemoteParticipantModel model) {
    for (final remoteAudioTrackPublicationModel in model.remoteAudioTrackPublications) {
      final remoteAudioTrackPublication = _remoteAudioTrackPublications.firstWhere(
        (p) => p.trackSid == remoteAudioTrackPublicationModel.sid,
        orElse: () => RemoteAudioTrackPublication._fromModel(remoteAudioTrackPublicationModel),
      );
      if (!_remoteAudioTrackPublications.contains(remoteAudioTrackPublication)) {
        _remoteAudioTrackPublications.add(remoteAudioTrackPublication);
      }
      remoteAudioTrackPublication._updateFromModel(remoteAudioTrackPublicationModel);
    }

    for (final remoteDataTrackPublicationModel in model.remoteDataTrackPublications) {
      final remoteDataTrackPublication = _remoteDataTrackPublications.firstWhere(
        (p) => p.trackSid == remoteDataTrackPublicationModel.sid,
        orElse: () => RemoteDataTrackPublication._fromModel(remoteDataTrackPublicationModel),
      );
      if (!_remoteDataTrackPublications.contains(remoteDataTrackPublication)) {
        _remoteDataTrackPublications.add(remoteDataTrackPublication);
      }
      remoteDataTrackPublication._updateFromModel(remoteDataTrackPublicationModel);
    }

    for (final remoteVideoTrackPublicationModel in model.remoteVideoTrackPublications) {
      final remoteVideoTrackPublication = _remoteVideoTrackPublications.firstWhere(
        (p) => p.trackSid == remoteVideoTrackPublicationModel.sid,
        orElse: () => RemoteVideoTrackPublication._fromModel(remoteVideoTrackPublicationModel, this),
      );
      if (!_remoteVideoTrackPublications.contains(remoteVideoTrackPublication)) {
        _remoteVideoTrackPublications.add(remoteVideoTrackPublication);
      }
      remoteVideoTrackPublication._updateFromModel(remoteVideoTrackPublicationModel);
    }
    _networkQualityLevel = model.networkQualityLevel;
  }

  void _parseEvents(BaseRemoteParticipantEvent event) {
    if (event is SkippableRemoteParticipantEvent) return;

    RemoteAudioTrackPublication findOrCreateRemoteAudioTrackPublication(RemoteAudioTrackPublicationModel model) {
      final remoteAudioTrackPublication = _remoteAudioTrackPublications.firstWhere((RemoteAudioTrackPublication p) => p.trackSid == model.sid, orElse: () => RemoteAudioTrackPublication._fromModel(model));
      if (!_remoteAudioTrackPublications.contains(remoteAudioTrackPublication)) {
        _remoteAudioTrackPublications.add(remoteAudioTrackPublication);
      }
      remoteAudioTrackPublication._updateFromModel(model);
      return remoteAudioTrackPublication;
    }

    RemoteAudioTrack findOrCreateRemoteAudioTrack(RemoteAudioTrackPublication publication, RemoteAudioTrackModel model) {
      var remoteAudioTrack = publication.remoteAudioTrack;
      return remoteAudioTrack ??= RemoteAudioTrack._fromModel(model);
    }

    RemoteDataTrackPublication findOrCreateRemoteDataTrackPublication(RemoteDataTrackPublicationModel model) {
      final remoteDataTrackPublication = _remoteDataTrackPublications.firstWhere((RemoteDataTrackPublication p) => p.trackSid == model.sid, orElse: () => RemoteDataTrackPublication._fromModel(model));
      if (!_remoteDataTrackPublications.contains(remoteDataTrackPublication)) {
        _remoteDataTrackPublications.add(remoteDataTrackPublication);
      }
      remoteDataTrackPublication._updateFromModel(model);
      return remoteDataTrackPublication;
    }

    RemoteDataTrack findOrCreateRemoteDataTrack(RemoteDataTrackPublication publication, RemoteDataTrackModel model) {
      var remoteDataTrack = publication.remoteDataTrack;
      return remoteDataTrack ??= RemoteDataTrack._fromModel(model);
    }

    RemoteVideoTrackPublication findOrCreateRemoteVideoTrackPublication(RemoteVideoTrackPublicationModel model) {
      final remoteVideoTrackPublication = _remoteVideoTrackPublications.firstWhere((RemoteVideoTrackPublication p) => p.trackSid == model.sid, orElse: () => RemoteVideoTrackPublication._fromModel(model, this));
      if (!_remoteVideoTrackPublications.contains(remoteVideoTrackPublication)) {
        _remoteVideoTrackPublications.add(remoteVideoTrackPublication);
      }
      remoteVideoTrackPublication._updateFromModel(model);
      return remoteVideoTrackPublication;
    }

    RemoteVideoTrack findOrCreateRemoteVideoTrack(RemoteVideoTrackPublication publication, RemoteVideoTrackModel model) {
      var remoteVideoTrack = publication.remoteVideoTrack;
      return remoteVideoTrack ??= RemoteVideoTrack._fromModel(model, this);
    }

    if (event is RemoteAudioTrackDisabled) {
      _onAudioTrackDisabled.add(RemoteAudioTrackEvent(this, findOrCreateRemoteAudioTrackPublication(event.remoteAudioTrackPublicationModel)));
    } else if (event is RemoteAudioTrackEnabled) {
      _onAudioTrackEnabled.add(RemoteAudioTrackEvent(this, findOrCreateRemoteAudioTrackPublication(event.remoteAudioTrackPublicationModel)));
    } else if (event is RemoteAudioTrackPublished) {
      _onAudioTrackPublished.add(RemoteAudioTrackEvent(this, findOrCreateRemoteAudioTrackPublication(event.remoteAudioTrackPublicationModel)));
    } else if (event is RemoteAudioTrackSubscribed) {
      final remoteAudioTrackPublication = findOrCreateRemoteAudioTrackPublication(event.remoteAudioTrackPublicationModel);
      final remoteAudioTrack = findOrCreateRemoteAudioTrack(remoteAudioTrackPublication, event.remoteAudioTrackModel);
      _onAudioTrackSubscribed.add(RemoteAudioTrackSubscriptionEvent(this, remoteAudioTrackPublication, remoteAudioTrack));
    } else if (event is RemoteAudioTrackSubscriptionFailed) {
      _onAudioTrackSubscriptionFailed.add(RemoteAudioTrackSubscriptionFailedEvent(this, findOrCreateRemoteAudioTrackPublication(event.remoteAudioTrackPublicationModel), TwilioException._fromModel(event.exception)));
    } else if (event is RemoteAudioTrackUnpublished) {
      _onAudioTrackUnpublished.add(RemoteAudioTrackEvent(this, findOrCreateRemoteAudioTrackPublication(event.remoteAudioTrackPublicationModel)));
    } else if (event is RemoteAudioTrackUnsubscribed) {
      final remoteAudioTrackPublication = findOrCreateRemoteAudioTrackPublication(event.remoteAudioTrackPublicationModel);
      final remoteAudioTrack = findOrCreateRemoteAudioTrack(remoteAudioTrackPublication, event.remoteAudioTrackModel);
      _onAudioTrackUnsubscribed.add(RemoteAudioTrackSubscriptionEvent(this, remoteAudioTrackPublication, remoteAudioTrack));
    } else if (event is RemoteDataTrackPublished) {
      _onDataTrackPublished.add(RemoteDataTrackEvent(this, findOrCreateRemoteDataTrackPublication(event.remoteDataTrackPublicationModel)));
    } else if (event is RemoteDataTrackSubscribed) {
      final remoteDataTrackPublication = findOrCreateRemoteDataTrackPublication(event.remoteDataTrackPublicationModel);
      final remoteDataTrack = findOrCreateRemoteDataTrack(remoteDataTrackPublication, event.remoteDataTrackModel);
      _onDataTrackSubscribed.add(RemoteDataTrackSubscriptionEvent(this, remoteDataTrackPublication, remoteDataTrack));
    } else if (event is RemoteDataTrackSubscriptionFailed) {
      _onDataTrackSubscriptionFailed.add(RemoteDataTrackSubscriptionFailedEvent(this, findOrCreateRemoteDataTrackPublication(event.remoteDataTrackPublicationModel), TwilioException._fromModel(event.exception)));
    } else if (event is RemoteDataTrackUnpublished) {
      _onDataTrackUnpublished.add(RemoteDataTrackEvent(this, findOrCreateRemoteDataTrackPublication(event.remoteDataTrackPublicationModel)));
    } else if (event is RemoteDataTrackUnsubscribed) {
      final remoteDataTrackPublication = findOrCreateRemoteDataTrackPublication(event.remoteDataTrackPublicationModel);
      final remoteDataTrack = findOrCreateRemoteDataTrack(remoteDataTrackPublication, event.remoteDataTrackModel);
      _onDataTrackUnsubscribed.add(RemoteDataTrackSubscriptionEvent(this, remoteDataTrackPublication, remoteDataTrack));
    } else if (event is RemoteVideoTrackDisabled) {
      _onVideoTrackDisabled.add(RemoteVideoTrackEvent(this, findOrCreateRemoteVideoTrackPublication(event.remoteVideoTrackPublicationModel)));
    } else if (event is RemoteVideoTrackEnabled) {
      _onVideoTrackEnabled.add(RemoteVideoTrackEvent(this, findOrCreateRemoteVideoTrackPublication(event.remoteVideoTrackPublicationModel)));
    } else if (event is RemoteVideoTrackPublished) {
      _onVideoTrackPublished.add(RemoteVideoTrackEvent(this, findOrCreateRemoteVideoTrackPublication(event.remoteVideoTrackPublicationModel)));
    } else if (event is RemoteVideoTrackSubscribed) {
      final remoteVideoTrackPublication = findOrCreateRemoteVideoTrackPublication(event.remoteVideoTrackPublicationModel);
      final remoteVideoTrack = findOrCreateRemoteVideoTrack(remoteVideoTrackPublication, event.remoteVideoTrackModel);
      _onVideoTrackSubscribed.add(RemoteVideoTrackSubscriptionEvent(this, remoteVideoTrackPublication, remoteVideoTrack));
    } else if (event is RemoteVideoTrackSubscriptionFailed) {
      _onVideoTrackSubscriptionFailed.add(RemoteVideoTrackSubscriptionFailedEvent(this, findOrCreateRemoteVideoTrackPublication(event.remoteVideoTrackPublicationModel), TwilioException._fromModel(event.exception)));
    } else if (event is RemoteVideoTrackUnpublished) {
      _onVideoTrackUnpublished.add(RemoteVideoTrackEvent(this, findOrCreateRemoteVideoTrackPublication(event.remoteVideoTrackPublicationModel)));
    } else if (event is RemoteVideoTrackUnsubscribed) {
      final remoteVideoTrackPublication = findOrCreateRemoteVideoTrackPublication(event.remoteVideoTrackPublicationModel);
      final remoteVideoTrack = findOrCreateRemoteVideoTrack(remoteVideoTrackPublication, event.remoteVideoTrackModel);
      _onVideoTrackUnsubscribed.add(RemoteVideoTrackSubscriptionEvent(this, remoteVideoTrackPublication, remoteVideoTrack));
    } else if (event is RemoteNetworkQualityLevelChanged) {
      _networkQualityLevel = event.networkQualityLevel;
      _onNetworkQualityLevelChanged.add(RemoteNetworkQualityLevelChangedEvent(this, _networkQualityLevel));
    }
  }
}
