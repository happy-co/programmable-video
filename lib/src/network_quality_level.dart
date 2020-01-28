enum NetworkQualityLevel {
  /// The Network Quality Level cannot be determined or the Network Quality API has not been enabled.
  NETWORK_QUALITY_LEVEL_UNKNOWN,

  /// The network connection has failed
  NETWORK_QUALITY_LEVEL_ZERO,

  /// The Network Quality is Very Bad.
  NETWORK_QUALITY_LEVEL_ONE,

  /// The Network Quality is Bad.
  NETWORK_QUALITY_LEVEL_TWO,

  /// The Network Quality is Good.
  NETWORK_QUALITY_LEVEL_THREE,

  /// The Network Quality is Very Good.
  NETWORK_QUALITY_LEVEL_FOUR,

  /// The Network Quality is Excellent.
  NETWORK_QUALITY_LEVEL_FIVE
}
