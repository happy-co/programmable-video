part of twilio_programmable_video;

class RemoteDataTrack extends DataTrack {
  final String _sid;

  final StreamController<RemoteDataTrackStringMessageEvent> _onStringMessage = StreamController<RemoteDataTrackStringMessageEvent>.broadcast();

  /// Notifies the listener that a string message was received
  Stream<RemoteDataTrackStringMessageEvent> onMessage;

  final StreamController<RemoteDataTrackBufferMessageEvent> _onBufferMessage = StreamController<RemoteDataTrackBufferMessageEvent>.broadcast();

  /// Notifies the listener that a string message was received
  Stream<RemoteDataTrackBufferMessageEvent> onBufferMessage;

  /// Returns the server identifier. This value uniquely identifies the remote data track within the scope of a [Room].
  String get sid => _sid;

  RemoteDataTrack(this._sid) : assert(_sid != null) {
    onMessage = _onStringMessage.stream;
    onBufferMessage = _onBufferMessage.stream;
  }

  /// Dispose the RemoteDataTrack
  void dispose() {
    _closeStreams();
  }

  /// Dispose the event streams.
  Future<void> _closeStreams() async {
    await _onStringMessage.close();
    await _onBufferMessage.close();
  }

  /// Construct from a [RemoteDataTrackModel].
  factory RemoteDataTrack._fromModel(RemoteDataTrackModel model) {
    if (model == null) {
      return null;
    }
    var remoteDataTrack = RemoteDataTrack(model.sid);
    remoteDataTrack._updateFromModel(model);
    return remoteDataTrack;
  }

  /// Update properties from a [RemoteDataTrackModel].
  @override
  void _updateFromModel(TrackModel model) {
    if (model is RemoteDataTrackModel) {
      super._updateFromModel(model);
      _name = model.name;
      _ordered = model.ordered;
      _reliable = model.reliable;
      _maxPacketLifeTime = model.maxPacketLifeTime;
      _maxRetransmits = model.maxRetransmits;
    }
  }

  void _parseEvents(BaseRemoteDataTrackEvent event) {
    _updateFromModel(event.remoteDataTrackModel);

    if (event is StringMessage) {
      _onStringMessage.add(RemoteDataTrackStringMessageEvent(this, event.message));
    } else if (event is BufferMessage) {
      _onBufferMessage.add(RemoteDataTrackBufferMessageEvent(this, event.message));
    } else if (event is UnknownEvent) {
      TwilioProgrammableVideo._log('RemoteDataTrack($_sid) => Received unknown event with name: ${event.eventName}');
    }
  }
}
