package unofficial.twilio.flutter.twilio_unofficial_programmable_video

import com.twilio.video.RemoteAudioTrack
import com.twilio.video.RemoteAudioTrackPublication
import com.twilio.video.RemoteDataTrack
import com.twilio.video.RemoteDataTrackPublication
import com.twilio.video.RemoteParticipant
import com.twilio.video.RemoteVideoTrack
import com.twilio.video.RemoteVideoTrackPublication
import com.twilio.video.TwilioException

class RemoteParticipantListener : BaseListener(), RemoteParticipant.Listener {
    override fun onAudioTrackDisabled(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onAudioTrackDisabled NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackEnabled(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onAudioTrackEnabled NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackPublished(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onAudioTrackPublished NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackSubscribed(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication, remoteAudioTrack: RemoteAudioTrack) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onAudioTrackSubscribed NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackSubscriptionFailed(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication, twilioException: TwilioException) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onAudioTrackSubscriptionFailed NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackUnpublished(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onAudioTrackUnpublished NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackUnsubscribed(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication, remoteAudioTrack: RemoteAudioTrack) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onAudioTrackUnsubscribed NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onDataTrackPublished(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onDataTrackPublished NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onDataTrackSubscribed(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication, remoteDataTrack: RemoteDataTrack) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onDataTrackSubscribed NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onDataTrackSubscriptionFailed(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication, twilioException: TwilioException) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onDataTrackSubscriptionFailed NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onDataTrackUnpublished(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onDataTrackUnpublished NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onDataTrackUnsubscribed(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication, remoteDataTrack: RemoteDataTrack) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onDataTrackUnsubscribed NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackDisabled(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onVideoTrackDisabled NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackEnabled(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onVideoTrackEnabled NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackPublished(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onVideoTrackPublished NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackSubscribed(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication, remoteVideoTrack: RemoteVideoTrack) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onVideoTrackSubscribed => trackSid: ${remoteVideoTrackPublication.trackSid}, isTrackEnabled: ${remoteVideoTrackPublication.isTrackEnabled}, isTrackSubscribed: ${remoteVideoTrackPublication.isTrackSubscribed}")
        sendEvent("videoTrackSubscribed", mapOf(
                "remoteParticipant" to remoteParticipantToMap(remoteParticipant, true),
                "remoteVideoTrackPublication" to remoteVideoTrackPublicationToMap(remoteVideoTrackPublication)
        ))
    }

    override fun onVideoTrackSubscriptionFailed(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication, twilioException: TwilioException) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onVideoTrackSubscriptionFailed NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackUnpublished(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onVideoTrackUnpublished NOT IMPLEMENTED")
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackUnsubscribed(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication, remoteVideoTrack: RemoteVideoTrack) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantListener.onVideoTrackUnsubscribed => " +
                "trackSid: ${remoteVideoTrackPublication.trackSid}, " +
                "isTrackEnabled: ${remoteVideoTrackPublication.isTrackEnabled}, " +
                "isTrackSubscribed: ${remoteVideoTrackPublication.isTrackSubscribed}")

        sendEvent("videoTrackUnsubscribed", mapOf(
                "remoteParticipant" to remoteParticipantToMap(remoteParticipant, true),
                "remoteVideoTrackPublication" to remoteVideoTrackPublicationToMap(remoteVideoTrackPublication),
                "remoteVideoTrack" to remoteVideoTrackToMap(remoteVideoTrack))
        )
    }

    companion object {
        @JvmStatic
        fun remoteParticipantToMap(remoteParticipant: RemoteParticipant, noTracks: Boolean = false): Map<String, Any?> {
            val remoteAudioTrackPublications = if (!noTracks) remoteParticipant.remoteAudioTracks.map { remoteAudioTrackPublicationToMap(it) } else null
            val remoteVideoTrackPublications = if (!noTracks) remoteParticipant.remoteVideoTracks.map { remoteVideoTrackPublicationToMap(it) } else null

            return mapOf(
                    "identity" to remoteParticipant.identity,
                    "sid" to remoteParticipant.sid,
                    "remoteVideoTrackPublications" to remoteVideoTrackPublications
            )
        }

        @JvmStatic
        fun remoteAudioTrackPublicationToMap(remoteAudioTrackPublication: RemoteAudioTrackPublication): Map<String, Any?> {
            return mapOf(
                    "sid" to remoteAudioTrackPublication.trackSid,
                    "name" to remoteAudioTrackPublication.trackName,
                    "enabled" to remoteAudioTrackPublication.isTrackEnabled,
                    "subscribed" to remoteAudioTrackPublication.isTrackSubscribed,
                    "remoteAudioTrack" to remoteAudioTrackToMap(remoteAudioTrackPublication.remoteAudioTrack)
            )
        }

        @JvmStatic
        fun remoteAudioTrackToMap(remoteAudioTrack: RemoteAudioTrack?): Map<String, Any>? {
            if (remoteAudioTrack != null) {
                return mapOf(
                        "sid" to remoteAudioTrack.sid,
                        "name" to remoteAudioTrack.name,
                        "enabled" to remoteAudioTrack.isEnabled
                )
            }
            return null
        }

        @JvmStatic
        fun remoteVideoTrackPublicationToMap(remoteVideoTrackPublication: RemoteVideoTrackPublication): Map<String, Any?> {
            return mapOf(
                    "sid" to remoteVideoTrackPublication.trackSid,
                    "name" to remoteVideoTrackPublication.trackName,
                    "enabled" to remoteVideoTrackPublication.isTrackEnabled,
                    "subscribed" to remoteVideoTrackPublication.isTrackSubscribed,
                    "remoteVideoTrack" to remoteVideoTrackToMap(remoteVideoTrackPublication.remoteVideoTrack)
            )
        }

        @JvmStatic
        fun remoteVideoTrackToMap(remoteVideoTrack: RemoteVideoTrack?): Map<String, Any>? {
            if (remoteVideoTrack != null) {
                return mapOf(
                        "sid" to remoteVideoTrack.sid,
                        "name" to remoteVideoTrack.name,
                        "enabled" to remoteVideoTrack.isEnabled
                )
            }
            return null
        }
    }
}
