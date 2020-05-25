part of twilio_programmable_video;

/// Represents a local data track.
class LocalDataTrack extends DataTrack {
  final DataTrackOptions _dataTrackOptions; // ignore: unused_field

  LocalDataTrack([this._dataTrackOptions]) : super();

  /// Construct from a [DataTrackModel].
  factory LocalDataTrack._fromModel(DataTrackModel model) {
    var localDataTrack = LocalDataTrack();
    localDataTrack._updateFromModel(model);
    return localDataTrack;
  }

  Future<void> send(String message) async {
    return ProgrammableVideoPlatform.instance.sendMessage(name: name, message: message);
  }

  Future<void> sendBuffer(ByteBuffer message) async {
    return ProgrammableVideoPlatform.instance.sendBuffer(name: name, message: message);
  }

  /// Create [DataTrackModel] from properties.
  DataTrackModel _toModel() {
    return DataTrackModel(
      reliable: _reliable,
      name: _name,
      enabled: _enabled,
      maxPacketLifeTime: _maxPacketLifeTime,
      maxRetransmits: _maxRetransmits,
      ordered: _ordered,
    );
  }
}
