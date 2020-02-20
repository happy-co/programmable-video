part of twilio_unofficial_programmable_video;

/// Represents a local data track.
class LocalDataTrack extends DataTrack {
  final DataTrackOptions _dataTrackOptions;

  LocalDataTrack([this._dataTrackOptions]) : super();

  /// Construct from a map.
  factory LocalDataTrack._fromMap(Map<String, dynamic> map) {
    var localDataTrack = LocalDataTrack();
    localDataTrack._updateFromMap(map);
    return localDataTrack;
  }

  /// Create map from properties.
  Map<String, Object> _toMap() {
    return <String, Object>{
      'dataTrackOptions': _dataTrackOptions?._toMap(),
    };
  }

  Future<void> send(String message) async {
    return const MethodChannel('twilio_unofficial_programmable_video').invokeMethod('LocalDataTrack#sendString', <String, dynamic>{'name': name, 'message': message});
  }

  Future<void> sendBuffer(ByteBuffer message) async {
    // Platform Channel Data types don't support ByteBuffer at the moment, so we need to convert it to
    // a data type the channels do understand (https://flutter.dev/docs/development/platform-integration/platform-channels#codec)
    return const MethodChannel('twilio_unofficial_programmable_video').invokeMethod('LocalDataTrack#sendByteBuffer', <String, dynamic>{'name': name, 'message': message.asUint8List()});
  }
}
