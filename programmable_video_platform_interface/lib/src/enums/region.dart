/// Twilio's Programmable Video SDKs must communicate with Twilio's cloud in order to function.
///
/// This enum is a list of all possible regions at the moment.
/// See https://www.twilio.com/docs/video/ip-address-whitelisting#signaling-communication for more information.
enum Region {
  /// Global Low Latency (default).
  gll,

  /// Australia.
  au1,

  /// Brazil.
  br1,

  /// Germany.
  de1,

  /// Ireland.
  ie1,

  /// India.
  in1,

  /// Japan.
  jp1,

  /// Singapore.
  sg1,

  /// US East Coast (Virginia)
  us1,

  /// US West Coast (Oregon)
  us2
}
