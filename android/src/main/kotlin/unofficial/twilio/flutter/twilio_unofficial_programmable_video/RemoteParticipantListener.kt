package unofficial.twilio.flutter.twilio_unofficial_programmable_video

import com.twilio.video.*
import io.flutter.plugin.common.EventChannel.EventSink

class RemoteParticipantListener : BaseListener(), RemoteParticipant.Listener {
    override fun onAudioTrackDisabled(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackEnabled(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackPublished(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackSubscribed(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication, remoteAudioTrack: RemoteAudioTrack) {
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackSubscriptionFailed(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication, twilioException: TwilioException) {
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackUnpublished(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onAudioTrackUnsubscribed(remoteParticipant: RemoteParticipant, remoteAudioTrackPublication: RemoteAudioTrackPublication, remoteAudioTrack: RemoteAudioTrack) {
        // NOT IMPLEMENTED
    }

    override fun onDataTrackPublished(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onDataTrackSubscribed(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication, remoteDataTrack: RemoteDataTrack) {
        // NOT IMPLEMENTED
    }

    override fun onDataTrackSubscriptionFailed(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication, twilioException: TwilioException) {
        // NOT IMPLEMENTED
    }

    override fun onDataTrackUnpublished(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onDataTrackUnsubscribed(remoteParticipant: RemoteParticipant, remoteDataTrackPublication: RemoteDataTrackPublication, remoteDataTrack: RemoteDataTrack) {
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackDisabled(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackEnabled(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackPublished(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackSubscribed(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication, remoteVideoTrack: RemoteVideoTrack) {
        // TODO: Refactor this to maps.
        sendEvent("videoTrackSubscribed", mapOf("remoteParticipantSid" to remoteParticipant.sid, "remoteVideoTrackSid" to remoteVideoTrack.sid))
    }

    override fun onVideoTrackSubscriptionFailed(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication, twilioException: TwilioException) {
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackUnpublished(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication) {
        // NOT IMPLEMENTED
    }

    override fun onVideoTrackUnsubscribed(remoteParticipant: RemoteParticipant, remoteVideoTrackPublication: RemoteVideoTrackPublication, remoteVideoTrack: RemoteVideoTrack) {
        // TODO: Refactor this to maps.
        sendEvent("videoTrackUnsubscribed", mapOf("remoteParticipantSid" to remoteParticipant.sid, "remoteVideoTrackSid" to remoteVideoTrack.sid))
    }
    
    companion object {
        @JvmStatic
        fun remoteParticipantToMap(remoteParticipant: RemoteParticipant): Map<String, Any> {
            val remoteVideoTracks = remoteParticipant.remoteVideoTracks.map { remoteVideoTrackPublicationToMap(it) }
            return mapOf("identity" to remoteParticipant.identity, "sid" to remoteParticipant.sid, "remoteVideoTracks" to remoteVideoTracks)
        }

        @JvmStatic
        fun remoteVideoTrackPublicationToMap(remoteVideoTrackPublication: RemoteVideoTrackPublication): Map<String, Any> {
            return mapOf("sid" to remoteVideoTrackPublication.trackSid)
        }
    }
    
}