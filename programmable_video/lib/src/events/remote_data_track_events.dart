part of twilio_programmable_video;

class RemoteDataTrackStringMessageEvent {
  /// The remote data track
  final RemoteDataTrack remoteDataTrack;

  /// The string message received
  final String message;

  RemoteDataTrackStringMessageEvent(
    this.remoteDataTrack,
    this.message,
  );
}

class RemoteDataTrackBufferMessageEvent {
  /// The remote data track
  final RemoteDataTrack remoteDataTrack;

  /// The ByteBuffer message received
  final ByteBuffer message;

  RemoteDataTrackBufferMessageEvent(
    this.remoteDataTrack,
    this.message,
  );
}
