part of twilio_programmable_video;

class DataTrackOptions {
  /// Default value for max packet life time.
  static const int defaultMaxPacketLifeTime = -1;

  /// Default value for max retransmits
  static const int defaultMaxRetransmits = -1;

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
    this.name,
  })  : assert(ordered != null),
        assert(maxPacketLifeTime != null),
        assert(maxRetransmits != null),
        assert((maxRetransmits == DataTrackOptions.defaultMaxRetransmits && maxPacketLifeTime == DataTrackOptions.defaultMaxPacketLifeTime) ||
            (maxRetransmits != DataTrackOptions.defaultMaxRetransmits && maxPacketLifeTime == DataTrackOptions.defaultMaxPacketLifeTime) ||
            (maxRetransmits == DataTrackOptions.defaultMaxRetransmits && maxPacketLifeTime != DataTrackOptions.defaultMaxPacketLifeTime));
}
