package unofficial.twilio.flutter.twilio_unofficial_programmable_video

import com.twilio.video.CameraCapturer
import com.twilio.video.ConnectOptions
import com.twilio.video.LocalAudioTrack
import com.twilio.video.LocalAudioTrackPublication
import com.twilio.video.LocalParticipant
import com.twilio.video.LocalVideoTrack
import com.twilio.video.LocalVideoTrackPublication
import com.twilio.video.RemoteParticipant
import com.twilio.video.Room
import com.twilio.video.TwilioException
import com.twilio.video.VideoCapturer

class RoomListener(private var internalId: Int, var connectOptions: ConnectOptions) : BaseListener(), Room.Listener {
    var room: Room? = null

    override fun onConnectFailure(room: Room, e: TwilioException) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onConnectFailure => room sid is '${room.sid}', exception is $e")
        sendEvent("connectFailure", mapOf("room" to roomToMap(room)), e)
    }

    override fun onConnected(room: Room) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onConnected => room sid is '${room.sid}'")
        sendEvent("connected", mapOf("room" to roomToMap(room)))
        room.remoteParticipants.forEach { it.setListener(TwilioUnofficialProgrammableVideoPlugin.remoteParticipantListener) }
    }

    override fun onDisconnected(room: Room, e: TwilioException?) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onDisconnected => room sid is '${room.sid}', exception is $e")
        sendEvent("disconnected", mapOf("room" to roomToMap(room)), e)
    }

    override fun onParticipantConnected(room: Room, remoteParticipant: RemoteParticipant) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onParticipantConnected => room sid is '${room.sid}', remoteParticipant sid is '${remoteParticipant.sid}'")
        sendEvent("participantConnected", mapOf("room" to roomToMap(room), "remoteParticipant" to RemoteParticipantListener.remoteParticipantToMap(remoteParticipant)))
        remoteParticipant.setListener(TwilioUnofficialProgrammableVideoPlugin.remoteParticipantListener)
    }

    override fun onParticipantDisconnected(room: Room, remoteParticipant: RemoteParticipant) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onParticipantDisconnected => room sid is '${room.sid}', participant sid is '${remoteParticipant.sid}'")
        sendEvent("participantDisconnected", mapOf("room" to roomToMap(room), "remoteParticipant" to RemoteParticipantListener.remoteParticipantToMap(remoteParticipant)))
    }

    override fun onReconnected(room: Room) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onReconnected => room sid is '${room.sid}'")
        sendEvent("reconnected", mapOf("room" to roomToMap(room)))
    }

    override fun onReconnecting(room: Room, e: TwilioException) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onReconnecting => room sid is '${room.sid}', exception is $e")
        sendEvent("connected", mapOf("room" to roomToMap(room)), e)
    }

    override fun onRecordingStarted(room: Room) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onRecordingStarted => room sid is '${room.sid}'")
        sendEvent("recordingStarted", mapOf("room" to roomToMap(room)))
    }

    override fun onRecordingStopped(room: Room) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onRecordingStopped => room sid is '${room.sid}'")
        sendEvent("recordingStopped", mapOf("room" to roomToMap(room)))
    }

    private fun remoteParticipantsToList(remoteParticipants: List<RemoteParticipant>): List<Map<String, Any?>> {
        return remoteParticipants.map { RemoteParticipantListener.remoteParticipantToMap(it) }
    }

    private fun roomToMap(room: Room): Map<String, Any?> {
        return mapOf(
                "sid" to room.sid,
                "name" to room.name,
                "state" to room.state.toString(),
                "mediaRegion" to room.mediaRegion,
                "localParticipant" to localParticipantToMap(room.localParticipant),
                "remoteParticipants" to remoteParticipantsToList(room.remoteParticipants)
        )
    }

    private fun localParticipantToMap(localParticipant: LocalParticipant?): Map<String, Any?> {
        val localAudioTrackPublications = localParticipant?.localAudioTracks?.map { localAudioTrackPublicationToMap(it) }
//        val localDataTrackPublications = localParticipant?.localDataTracks?.map { localDataTrackPublicationToMap(it) }
        val localVideoTrackPublications = localParticipant?.localVideoTracks?.map { localVideoTrackPublicationToMap(it) }
        return mapOf(
                "identity" to localParticipant?.identity,
                "sid" to localParticipant?.sid,
                "signalingRegion" to localParticipant?.signalingRegion,
                "networkQualityLevel" to localParticipant?.networkQualityLevel.toString(),
                "localAudioTrackPublications" to localAudioTrackPublications,
                "localVideoTrackPublications" to localVideoTrackPublications
        )
    }

    private fun localAudioTrackPublicationToMap(localVideoTrackPublication: LocalAudioTrackPublication): Map<String, Any> {
        return mapOf(
                "sid" to localVideoTrackPublication.trackSid,
                "localAudioTrack" to localAudioTrackToMap(localVideoTrackPublication.localAudioTrack)
        )
    }

    private fun localAudioTrackToMap(localAudioTrack: LocalAudioTrack): Map<String, Any> {
        return mapOf(
                "name" to localAudioTrack.name,
                "enabled" to localAudioTrack.isEnabled
        )
    }

    private fun localVideoTrackPublicationToMap(localVideoTrackPublication: LocalVideoTrackPublication): Map<String, Any> {
        return mapOf(
                "sid" to localVideoTrackPublication.trackSid,
                "localVideoTrack" to localVideoTrackToMap(localVideoTrackPublication.localVideoTrack)
        )
    }

    private fun localVideoTrackToMap(localVideoTrack: LocalVideoTrack): Map<String, Any> {
        return mapOf(
                "name" to localVideoTrack.name,
                "enabled" to localVideoTrack.isEnabled,
                "videoCapturer" to videoCapturerToMap(localVideoTrack.videoCapturer)
        )
    }

    private fun videoCapturerToMap(videoCapturer: VideoCapturer): Map<String, Any> {
        if (videoCapturer is CameraCapturer) {
            return mapOf(
                    "type" to "CameraCapturer",
                    "cameraSource" to videoCapturer.cameraSource.toString()
            )
        }
        return mapOf(
                "type" to "Unknown",
                "isScreencast" to videoCapturer.isScreencast
        )
    }
}
