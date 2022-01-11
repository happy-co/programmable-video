import Flutter
import Foundation
import TwilioVideo

class StatsMapper {
    static func statsReportsToDict(_ statsReports: [StatsReport]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: statsReports.map { ($0.peerConnectionId, statsReportToDict($0)) })
    }

    static func statsReportToDict(_ statsReport: StatsReport) -> [String: Any] {
        let remoteAudioTrackStats = statsReport.remoteAudioTrackStats.map { remoteAudioTrackStatsToMap($0) }
        let localAudioTrackStats = statsReport.localAudioTrackStats.map { localAudioTrackStatsToMap($0) }

        let remoteVideoTrackStats = statsReport.remoteVideoTrackStats.map { remoteVideoTrackStatsToMap($0) }
        let localVideoTrackStats = statsReport.localVideoTrackStats.map { localVideoTrackStatsToMap($0) }

        return [
            "peerConnectionId": statsReport.peerConnectionId,
            "remoteAudioTrackStats": remoteAudioTrackStats,
            "localAudioTrackStats": localAudioTrackStats,
            "remoteVideoTrackStats": remoteVideoTrackStats,
            "localVideoTrackStats": localVideoTrackStats
        ]
    }

    static func localAudioTrackStatsToMap(_ localAudioTrackStats: LocalAudioTrackStats) -> [String: Any] {
        return [
            "trackSid": localAudioTrackStats.trackSid,
            "packetsLost": localAudioTrackStats.packetsLost,
            "codec": localAudioTrackStats.codec,
            "ssrc": localAudioTrackStats.ssrc,
            "timestamp": localAudioTrackStats.timestamp,
            "bytesSent": localAudioTrackStats.bytesSent,
            "packetsSent": localAudioTrackStats.packetsSent,
            "roundTripTime": localAudioTrackStats.roundTripTime,
            "audioLevel": localAudioTrackStats.audioLevel,
            "jitter": localAudioTrackStats.jitter
        ]
    }

    static func remoteAudioTrackStatsToMap(_ remoteAudioTrackStats: RemoteAudioTrackStats) -> [String: Any] {
        return [
            "trackSid": remoteAudioTrackStats.trackSid,
            "packetsLost": remoteAudioTrackStats.packetsLost,
            "codec": remoteAudioTrackStats.codec,
            "ssrc": remoteAudioTrackStats.ssrc,
            "timestamp": remoteAudioTrackStats.timestamp,
            "bytesReceived": remoteAudioTrackStats.bytesReceived,
            "packetsReceived": remoteAudioTrackStats.packetsReceived,
            "audioLevel": remoteAudioTrackStats.audioLevel,
            "jitter": remoteAudioTrackStats.jitter
        ]
    }

    static func localVideoTrackStatsToMap(_ localVideoTrackStats: LocalVideoTrackStats) -> [String: Any] {
        return [
            "trackSid": localVideoTrackStats.trackSid,
            "packetsLost": localVideoTrackStats.packetsLost,
            "codec": localVideoTrackStats.codec,
            "ssrc": localVideoTrackStats.ssrc,
            "timestamp": localVideoTrackStats.timestamp,
            "bytesSent": localVideoTrackStats.bytesSent,
            "packetsSent": localVideoTrackStats.packetsSent,
            "roundTripTime": localVideoTrackStats.roundTripTime,
            "capturedFrameRate": localVideoTrackStats.captureFrameRate,
            "captureDimensionsHeight": localVideoTrackStats.captureDimensions.height,
            "captureDimensionsWidth": localVideoTrackStats.captureDimensions.width,
            "dimensionsHeight": localVideoTrackStats.dimensions.height,
            "dimensionsWidth": localVideoTrackStats.dimensions.width,
            "frameRate": localVideoTrackStats.frameRate
        ]
    }

    static func remoteVideoTrackStatsToMap(_ remoteVideoTrackStats: RemoteVideoTrackStats) -> [String: Any] {
        return [
            "trackSid": remoteVideoTrackStats.trackSid,
            "packetsLost": remoteVideoTrackStats.packetsLost,
            "codec": remoteVideoTrackStats.codec,
            "ssrc": remoteVideoTrackStats.ssrc,
            "timestamp": remoteVideoTrackStats.timestamp,
            "bytesReceived": remoteVideoTrackStats.bytesReceived,
            "packetsReceived": remoteVideoTrackStats.packetsReceived,
            "frameRate": remoteVideoTrackStats.frameRate,
            "dimensionsHeight": remoteVideoTrackStats.dimensions.height,
            "dimensionsWidth": remoteVideoTrackStats.dimensions.width
        ]
    }
}
