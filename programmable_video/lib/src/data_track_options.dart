part of twilio_programmable_video;

class DataTrackOptions {
  /// Default value for max packet life time.
  static const int defaultMaxPacketLifeTime = -1;

  /// Default value for max retransmits
  static const int defaultMaxRetransmits = -1;

  /// The maximum period of time in milliseconds in which retransmissions will be sent.
  static const int defaultMaxPacketLifeTimeValue = 65535;

  /// The maximum number of times to transmit a message before giving up.
  static const int defaultMaxRetransmitsValue = 65535;

  /// Ordered transmission of messages. Default is `true`.
  final bool ordered;

  /// Maximum retransmit time in milliseconds. Default is [DataTrackOptions.defaultMaxPacketLifeTime]
  final int maxPacketLifeTime;

  /// Maximum number of retransmitted messages. Default is [DataTrackOptions.defaultMaxRetransmits]
  final int maxRetransmits;

  /// Data track name.
  final String name;

  /// [maxPacketLifeTime] time and [maxRetransmits] are mutually exclusive. This means
  /// that only one of these values can be set to a non default value at a time.
  DataTrackOptions({
    this.ordered = true,
    this.maxPacketLifeTime = DataTrackOptions.defaultMaxPacketLifeTime,
    this.maxRetransmits = DataTrackOptions.defaultMaxRetransmits,
    required this.name,
  }) : assert((maxRetransmits == DataTrackOptions.defaultMaxRetransmits && maxPacketLifeTime == DataTrackOptions.defaultMaxPacketLifeTime) ||
            (maxRetransmits != DataTrackOptions.defaultMaxRetransmits && maxPacketLifeTime == DataTrackOptions.defaultMaxPacketLifeTime) ||
            (maxRetransmits == DataTrackOptions.defaultMaxRetransmits && maxPacketLifeTime != DataTrackOptions.defaultMaxPacketLifeTime) ||
            (maxRetransmits == DataTrackOptions.defaultMaxRetransmitsValue && maxPacketLifeTime == defaultMaxPacketLifeTimeValue));
}
