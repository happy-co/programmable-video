part of twilio_programmable_video;

abstract class DataTrack extends Track {
  @override
  String _name;

  bool _ordered;
  bool _reliable;
  int _maxPacketLifeTime;
  int _maxRetransmits;

  /// Returns true if data track guarantees in-order delivery of messages.
  bool get isOrdered => _ordered;

  /// Returns true if the data track guarantees reliable transmission of messages.
  bool get isReliable => _reliable;

  /// Returns the maximum period of time in milliseconds in which retransmissions will be sent.
  /// Returns `65535` if [DataTrackOptions.defaultMaxPacketLifeTime] was specified
  /// when building the data track.
  int get maxPacketLifeTime => _maxPacketLifeTime;

  /// Returns the maximum number of times to transmit a message before giving up.
  /// Returns `65535` if [DataTrackOptions.defaultMaxRetransmits] was specified when
  /// building the data track.
  int get maxRetransmits => _maxRetransmits;

  DataTrack() : super(true, '');
}
