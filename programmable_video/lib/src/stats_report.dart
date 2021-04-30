part of twilio_programmable_video;

/// This class holds the stats for a given room, currently supports local audio/video and remote audio/video stats.
/// There are additional Ice candidate pair stats available, but this is only for peer to peer -> which the plugin does not support.
class StatsReport {
  final String _peerConnectionId;
  final List<LocalAudioTrackStats> _localAudioTrackStats = <LocalAudioTrackStats>[];
  final List<LocalVideoTrackStats> _localVideoTrackStats = <LocalVideoTrackStats>[];
  final List<RemoteAudioTrackStats> _remoteAudioTrackStats = <RemoteAudioTrackStats>[];
  final List<RemoteVideoTrackStats> _remoteVideoTrackStats = <RemoteVideoTrackStats>[];

  StatsReport(this._peerConnectionId);

  /// Returns the id of peer connection related to this report.
  String get peerConnectionId => _peerConnectionId;

  /// Returns stats for all local audio tracks in the peer connection.
  List<LocalAudioTrackStats> get localAudioTrackStats => _localAudioTrackStats;

  /// Returns stats for all local video tracks in the peer connection.
  List<LocalVideoTrackStats> get localVideoTrackStats => _localVideoTrackStats;

  /// Returns stats for all remote audio tracks in the peer connection.
  List<RemoteAudioTrackStats> get remoteAudioTrackStats => _remoteAudioTrackStats;

  /// Returns stats for all remote video tracks in the peer connection.
  List<RemoteVideoTrackStats> get remoteVideoTrackStats => _remoteVideoTrackStats;

  void addLocalAudioTrackStats(LocalAudioTrackStats localAudioTrackStats) {
    this.localAudioTrackStats.add(localAudioTrackStats);
  }

  void addLocalVideoTrackStats(LocalVideoTrackStats localVideoTrackStats) {
    this.localVideoTrackStats.add(localVideoTrackStats);
  }

  void addAudioTrackStats(RemoteAudioTrackStats remoteAudioTrackStats) {
    this.remoteAudioTrackStats.add(remoteAudioTrackStats);
  }

  void addVideoTrackStats(RemoteVideoTrackStats remoteVideoTrackStats) {
    this.remoteVideoTrackStats.add(remoteVideoTrackStats);
  }
}

class RemoteVideoTrackStats extends RemoteTrackStats {
  /// Received frame dimensions.
  final VideoDimensions dimensions;

  /// Received frame rate.
  final int frameRate;

  RemoteVideoTrackStats(
    String trackSid,
    int packetsLost,
    String codec,
    String ssrc,
    double timestamp,
    int bytesReceived,
    int packetsReceived,
    this.dimensions,
    this.frameRate,
  ) : super(
          trackSid,
          packetsLost,
          codec,
          ssrc,
          timestamp,
          bytesReceived,
          packetsReceived,
        );
}

class RemoteAudioTrackStats extends RemoteTrackStats {
  /// The audio input level.
  final int audioLevel;

  /// Packet jitter measured in milliseconds.
  final int jitter;

  RemoteAudioTrackStats(
    String trackSid,
    int packetsLost,
    String codec,
    String ssrc,
    double timestamp,
    int bytesReceived,
    int packetsReceived,
    this.audioLevel,
    this.jitter,
  ) : super(
          trackSid,
          packetsLost,
          codec,
          ssrc,
          timestamp,
          bytesReceived,
          packetsReceived,
        );
}

class LocalAudioTrackStats extends LocalTrackStats {
  /// The audio input level.
  final int audioLevel;

  /// Packet jitter measured in milliseconds.
  final int jitter;

  LocalAudioTrackStats(
    String trackSid,
    int packetsLost,
    String codec,
    String ssrc,
    double timestamp,
    int bytesSent,
    int packetsSent,
    int roundTripTime,
    this.audioLevel,
    this.jitter,
  ) : super(
          trackSid,
          packetsLost,
          codec,
          ssrc,
          timestamp,
          bytesSent,
          packetsSent,
          roundTripTime,
        );
}

class LocalVideoTrackStats extends LocalTrackStats {
  /// The captured frame dimensions.
  final VideoDimensions captureDimensions;

  /// The captured frame rate.
  final int capturedFrameRate;

  /// The frame dimensions that are sent.
  final VideoDimensions dimensions;

  /// The frame rate that is being sent.
  final int frameRate;

  LocalVideoTrackStats(
    String trackSid,
    int packetsLost,
    String codec,
    String ssrc,
    double timestamp,
    int bytesSent,
    int packetsSent,
    int roundTripTime,
    this.captureDimensions,
    this.dimensions,
    this.capturedFrameRate,
    this.frameRate,
  ) : super(
          trackSid,
          packetsLost,
          codec,
          ssrc,
          timestamp,
          bytesSent,
          packetsSent,
          roundTripTime,
        );
}

class VideoDimensions {
  final int height;

  final int width;

  VideoDimensions(this.height, this.width);
}

abstract class RemoteTrackStats extends BaseTrackStats {
  /// Total number of packets received
  final int bytesReceived;

  /// Total number of packets received
  final int packetsReceived;

  RemoteTrackStats(
    String trackSid,
    int packetsLost,
    String codec,
    String ssrc,
    double timestamp,
    this.bytesReceived,
    this.packetsReceived,
  ) : super(trackSid, packetsLost, codec, ssrc, timestamp);
}

abstract class LocalTrackStats extends BaseTrackStats {
  /// Total number of bytes sent for this SSRC
  final int bytesSent;

  /// Total number of RTP packets sent for this SSRC
  final int packetsSent;

  /// Estimated round trip time for this SSRC based on the RTCP timestamps. Measured in
  /// milliseconds.
  final int roundTripTime;

  LocalTrackStats(
    String trackSid,
    int packetsLost,
    String codec,
    String ssrc,
    double timestamp,
    this.bytesSent,
    this.packetsSent,
    this.roundTripTime,
  ) : super(trackSid, packetsLost, codec, ssrc, timestamp);
}

abstract class BaseTrackStats {
  /// Track server identifier
  final String trackSid;

  /// Total number of RTP packets lost for this SSRC since the beginning of the reception
  final int packetsLost;

  /// Name of codec used for this track
  final String codec;

  /// The SSRC identifier of the source
  final String ssrc;

  /// Unix timestamp in milliseconds
  final double timestamp;

  BaseTrackStats(
    this.trackSid,
    this.packetsLost,
    this.codec,
    this.ssrc,
    this.timestamp,
  );
}
