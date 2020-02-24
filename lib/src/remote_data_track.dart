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

  /// Construct from a map.
  factory RemoteDataTrack._fromMap(Map<String, dynamic> map) {
    if (map == null) {
      return null;
    }
    var remoteDataTrack = RemoteDataTrack(map['sid']);
    remoteDataTrack._updateFromMap(map);
    return remoteDataTrack;
  }

  void _parseEvents(dynamic event) {
    final String eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);

    final remoteDataTrackMap = Map<String, dynamic>.from(data['remoteDataTrack']);
    _updateFromMap(remoteDataTrackMap);

    switch (eventName) {
      case 'stringMessage':
        _onStringMessage.add(RemoteDataTrackStringMessageEvent(this, data['message'] as String));
        break;
      case 'bufferMessage':
        // Although data['message'] technically is of type Uint8List, we still need to create a new
        // `Uint8List.fromList(data['message']` in order to get the buffer output right.
        //
        // If we directly get the buffer from data['message'] in either one of the following ways,
        // the buffer contains wrong data! Don't know why, but it does...
        //
        // - data['message'].buffer
        // - (data['message'] as Uint8List).buffer
        //
        _onBufferMessage.add(RemoteDataTrackBufferMessageEvent(this, Uint8List.fromList(data['message']).buffer));
        break;
      default:
        TwilioProgrammableVideo._log('RemoteDataTrack($_sid) => Received unknown event with name: $eventName');
        break;
    }
  }
}
