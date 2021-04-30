package twilio.flutter.twilio_programmable_video

import com.twilio.video.LocalAudioTrackStats
import com.twilio.video.LocalVideoTrackStats
import com.twilio.video.RemoteAudioTrackStats
import com.twilio.video.RemoteVideoTrackStats
import com.twilio.video.StatsReport

class StatsMapper {

    companion object {

        @JvmStatic
        fun statsReportsToMap(statsReports: List<StatsReport>): Map<String, Any?> {
            return statsReports.map { it.peerConnectionId to statsReportToMap(it) }.toMap()
        }

        @JvmStatic
        fun statsReportToMap(statsReport: StatsReport): Map<String, Any?> {
            val remoteAudioTrackStats = statsReport.remoteAudioTrackStats.map { remoteAudioTrackStatsToMap(it) }
            val localAudioTrackStats = statsReport.localAudioTrackStats.map { localAudioTrackStatsToMap(it) }

            val remoteVideoTrackStats = statsReport.remoteVideoTrackStats.map { remoteVideoTrackStatsToMap(it) }
            val localVideoTrackStats = statsReport.localVideoTrackStats.map { localVideoTrackStatsToMap(it) }

            return mapOf(
                "peerConnectionId" to statsReport.peerConnectionId,
                "remoteAudioTrackStats" to remoteAudioTrackStats,
                "localAudioTrackStats" to localAudioTrackStats,
                "remoteVideoTrackStats" to remoteVideoTrackStats,
                "localVideoTrackStats" to localVideoTrackStats
            )
        }

        @JvmStatic
        fun localAudioTrackStatsToMap(localAudioTrackStats: LocalAudioTrackStats): Map<String, Any> {
            return mapOf(
                "trackSid" to localAudioTrackStats.trackSid,
                "packetsLost" to localAudioTrackStats.packetsLost,
                "codec" to localAudioTrackStats.codec,
                "ssrc" to localAudioTrackStats.ssrc,
                "timestamp" to localAudioTrackStats.timestamp,
                "bytesSent" to localAudioTrackStats.bytesSent,
                "packetsSent" to localAudioTrackStats.packetsSent,
                "roundTripTime" to localAudioTrackStats.roundTripTime,
                "audioLevel" to localAudioTrackStats.audioLevel,
                "jitter" to localAudioTrackStats.jitter
            )
        }

        @JvmStatic
        fun remoteAudioTrackStatsToMap(remoteAudioTrackStats: RemoteAudioTrackStats): Map<String, Any> {
            return mapOf(
                "trackSid" to remoteAudioTrackStats.trackSid,
                "packetsLost" to remoteAudioTrackStats.packetsLost,
                "codec" to remoteAudioTrackStats.codec,
                "ssrc" to remoteAudioTrackStats.ssrc,
                "timestamp" to remoteAudioTrackStats.timestamp,
                "bytesReceived" to remoteAudioTrackStats.bytesReceived,
                "packetsReceived" to remoteAudioTrackStats.packetsReceived,
                "audioLevel" to remoteAudioTrackStats.audioLevel,
                "jitter" to remoteAudioTrackStats.jitter
            )
        }

        @JvmStatic
        fun localVideoTrackStatsToMap(localVideoTrackStats: LocalVideoTrackStats): Map<String, Any> {
            return mapOf(
                "trackSid" to localVideoTrackStats.trackSid,
                "packetsLost" to localVideoTrackStats.packetsLost,
                "codec" to localVideoTrackStats.codec,
                "ssrc" to localVideoTrackStats.ssrc,
                "timestamp" to localVideoTrackStats.timestamp,
                "bytesSent" to localVideoTrackStats.bytesSent,
                "packetsSent" to localVideoTrackStats.packetsSent,
                "roundTripTime" to localVideoTrackStats.roundTripTime,
                "capturedFrameRate" to localVideoTrackStats.capturedFrameRate,
                "captureDimensionsHeight" to localVideoTrackStats.captureDimensions.height,
                "captureDimensionsWidth" to localVideoTrackStats.captureDimensions.width,
                "dimensionsHeight" to localVideoTrackStats.dimensions.height,
                "dimensionsWidth" to localVideoTrackStats.dimensions.width,
                "frameRate" to localVideoTrackStats.frameRate
            )
        }

        @JvmStatic
        fun remoteVideoTrackStatsToMap(remoteVideoTrackStats: RemoteVideoTrackStats): Map<String, Any> {
            return mapOf(
                "trackSid" to remoteVideoTrackStats.trackSid,
                "packetsLost" to remoteVideoTrackStats.packetsLost,
                "codec" to remoteVideoTrackStats.codec,
                "ssrc" to remoteVideoTrackStats.ssrc,
                "timestamp" to remoteVideoTrackStats.timestamp,
                "bytesReceived" to remoteVideoTrackStats.bytesReceived,
                "packetsReceived" to remoteVideoTrackStats.packetsReceived,
                "frameRate" to remoteVideoTrackStats.frameRate,
                "dimensionsHeight" to remoteVideoTrackStats.dimensions.height,
                "dimensionsWidth" to remoteVideoTrackStats.dimensions.width
            )
        }
    }
}
