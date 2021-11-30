package twilio.flutter.twilio_programmable_video

import com.twilio.video.LocalAudioTrack
import com.twilio.video.LocalAudioTrackPublication
import com.twilio.video.LocalDataTrack
import com.twilio.video.LocalDataTrackPublication
import com.twilio.video.LocalParticipant
import com.twilio.video.LocalVideoTrack
import com.twilio.video.LocalVideoTrackPublication
import com.twilio.video.NetworkQualityLevel
import com.twilio.video.TwilioException

class LocalParticipantListener : BaseListener(), LocalParticipant.Listener {
    private val TAG = "LocalParticipantListener"

    override fun onVideoTrackPublicationFailed(localParticipant: LocalParticipant, localVideoTrack: LocalVideoTrack, twilioException: TwilioException) {
        debug("onVideoTrackPublicationFailed => $twilioException")
        sendEvent("videoTrackPublicationFailed", mapOf(
                "localParticipant" to localParticipantToMap(localParticipant),
                "localVideoTrack" to localVideoTrackToMap(localVideoTrack)
        ), twilioException)
    }

    override fun onDataTrackPublished(localParticipant: LocalParticipant, localDataTrackPublication: LocalDataTrackPublication) {
        debug("onDataTrackPublished => " +
                "trackSid: ${localDataTrackPublication.trackSid}")
        sendEvent("dataTrackPublished", mapOf(
                "localParticipant" to localParticipantToMap(localParticipant),
                "localDataTrackPublication" to localDataTrackPublicationToMap(localDataTrackPublication)
        ))
    }

    override fun onDataTrackPublicationFailed(localParticipant: LocalParticipant, localDataTrack: LocalDataTrack, twilioException: TwilioException) {
        debug("onDataTrackPublicationFailed => $twilioException")
        sendEvent("dataTrackPublicationFailed", mapOf(
                "localParticipant" to localParticipantToMap(localParticipant),
                "localDataTrack" to localDataTrackToMap(localDataTrack)
        ), twilioException)
    }

    override fun onNetworkQualityLevelChanged(localParticipant: LocalParticipant, networkQualityLevel: NetworkQualityLevel) {
        debug("onNetworkQualityLevelChanged => " +
                "sid: ${localParticipant.sid}")
        sendEvent("networkQualityLevelChanged", mapOf(
                "localParticipant" to localParticipantToMap(localParticipant),
                "networkQualityLevel" to networkQualityLevel.toString()
        ))
    }

    override fun onAudioTrackPublished(localParticipant: LocalParticipant, localAudioTrackPublication: LocalAudioTrackPublication) {
        debug("onAudioTrackPublished => " +
                "trackSid: ${localAudioTrackPublication.trackSid}")
        sendEvent("audioTrackPublished", mapOf(
                "localParticipant" to localParticipantToMap(localParticipant),
                "localAudioTrackPublication" to localAudioTrackPublicationToMap(localAudioTrackPublication)
        ))
    }

    override fun onAudioTrackPublicationFailed(localParticipant: LocalParticipant, localAudioTrack: LocalAudioTrack, twilioException: TwilioException) {
        debug("onAudioTrackPublicationFailed => $twilioException")
        sendEvent("audioTrackPublicationFailed", mapOf(
                "localParticipant" to localParticipantToMap(localParticipant),
                "localAudioTrack" to localAudioTrackToMap(localAudioTrack)
        ), twilioException)
    }

    override fun onVideoTrackPublished(localParticipant: LocalParticipant, localVideoTrackPublication: LocalVideoTrackPublication) {
        debug("onVideoTrackPublished => " +
                "trackSid: ${localVideoTrackPublication.trackSid}")
        sendEvent("videoTrackPublished", mapOf(
                "localParticipant" to localParticipantToMap(localParticipant),
                "localVideoTrackPublication" to localVideoTrackPublicationToMap(localVideoTrackPublication)
        ))
    }

    companion object {
        @JvmStatic
        fun localParticipantToMap(localParticipant: LocalParticipant?): Map<String, Any?>? {
            if (localParticipant != null) {
                val localAudioTrackPublications =
                        localParticipant.localAudioTracks?.map { localAudioTrackPublicationToMap(it) }
                val localDataTrackPublications =
                        localParticipant.localDataTracks?.map { localDataTrackPublicationToMap(it) }
                val localVideoTrackPublications =
                        localParticipant.localVideoTracks?.map { localVideoTrackPublicationToMap(it) }
                return mapOf(
                        "identity" to localParticipant.identity,
                        "sid" to localParticipant.sid,
                        "signalingRegion" to localParticipant.signalingRegion,
                        "networkQualityLevel" to localParticipant.networkQualityLevel.toString(),
                        "localAudioTrackPublications" to localAudioTrackPublications,
                        "localDataTrackPublications" to localDataTrackPublications,
                        "localVideoTrackPublications" to localVideoTrackPublications
                )
            }
            return null
        }

        @JvmStatic
        fun localAudioTrackPublicationToMap(localVideoTrackPublication: LocalAudioTrackPublication): Map<String, Any> {
            return mapOf(
                    "sid" to localVideoTrackPublication.trackSid,
                    "localAudioTrack" to localAudioTrackToMap(localVideoTrackPublication.localAudioTrack)
            )
        }

        @JvmStatic
        fun localAudioTrackToMap(localAudioTrack: LocalAudioTrack): Map<String, Any> {
            return mapOf(
                    "name" to localAudioTrack.name,
                    "enabled" to localAudioTrack.isEnabled
            )
        }

        @JvmStatic
        fun localDataTrackPublicationToMap(localDataTrackPublication: LocalDataTrackPublication): Map<String, Any> {
            return mapOf(
                    "sid" to localDataTrackPublication.trackSid,
                    "localDataTrack" to localDataTrackToMap(localDataTrackPublication.localDataTrack)
            )
        }

        @JvmStatic
        fun localDataTrackToMap(localDataTrack: LocalDataTrack): Map<String, Any> {
            return mapOf(
                    "name" to localDataTrack.name,
                    "enabled" to localDataTrack.isEnabled,
                    "ordered" to localDataTrack.isOrdered,
                    "reliable" to localDataTrack.isReliable,
                    "maxPacketLifeTime" to localDataTrack.maxPacketLifeTime,
                    "maxRetransmits" to localDataTrack.maxRetransmits
            )
        }

        @JvmStatic
        fun localVideoTrackPublicationToMap(localVideoTrackPublication: LocalVideoTrackPublication): Map<String, Any> {
            return mapOf(
                    "sid" to localVideoTrackPublication.trackSid,
                    "localVideoTrack" to localVideoTrackToMap(localVideoTrackPublication.localVideoTrack)
            )
        }

        @JvmStatic
        fun localVideoTrackToMap(localVideoTrack: LocalVideoTrack): Map<String, Any> {
            return mapOf(
                    "name" to localVideoTrack.name,
                    "enabled" to localVideoTrack.isEnabled,
                    "videoCapturer" to VideoCapturerHandler.videoCapturerToMap(localVideoTrack.videoCapturer)
            )
        }
    }

    internal fun debug(msg: String) {
        TwilioProgrammableVideoPlugin.debug("$TAG::$msg")
    }
}
