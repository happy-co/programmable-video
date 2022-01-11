part of twilio_programmable_video;

/// Represents a local data track.
class LocalDataTrack extends DataTrack {
  final DataTrackOptions _dataTrackOptions;

  LocalDataTrack(this._dataTrackOptions) : super(_dataTrackOptions.name);

  /// Construct from a [LocalDataTrackModel].
  factory LocalDataTrack._fromModel(LocalDataTrackModel model) {
    final localDataTrack = LocalDataTrack(DataTrackOptions(
      name: model.name,
      maxPacketLifeTime: model.maxPacketLifeTime,
      maxRetransmits: model.maxRetransmits,
      ordered: model.ordered,
    ));
    localDataTrack._updateFromModel(model);
    return localDataTrack;
  }

  /// Sends a [String] message over this data track.
  ///
  /// Can throw a [MissingParameterException], [NotFoundException], or a [TwilioException].
  Future<void> send(String message) async {
    try {
      return ProgrammableVideoPlatform.instance.sendMessage(message, name);
    } on PlatformException catch (err) {
      throw TwilioProgrammableVideo._convertException(err);
    }
  }

  /// Sends a [ByteBuffer] message over this data track.
  ///
  /// Can throw a [MissingParameterException], [NotFoundException], or a [TwilioException].
  Future<void> sendBuffer(ByteBuffer message) async {
    try {
      return ProgrammableVideoPlatform.instance.sendBuffer(message, name);
    } on PlatformException catch (err) {
      throw TwilioProgrammableVideo._convertException(err);
    }
  }

  /// Create [DataTrackModel] from properties.
  LocalDataTrackModel _toModel() {
    return LocalDataTrackModel(
      name: _dataTrackOptions.name,
      maxPacketLifeTime: _dataTrackOptions.maxPacketLifeTime,
      maxRetransmits: _dataTrackOptions.maxRetransmits,
      ordered: _dataTrackOptions.ordered,
    );
  }

  /// Update properties from a [LocalDataTrackModel].
  @override
  void _updateFromModel(TrackModel model) {
    if (model is LocalDataTrackModel) {
      super._updateFromModel(model);
      _ordered = model.ordered;
      _reliable = model.reliable;
      _maxPacketLifeTime = model.maxPacketLifeTime;
      _maxRetransmits = model.maxRetransmits;
    }
  }
}
