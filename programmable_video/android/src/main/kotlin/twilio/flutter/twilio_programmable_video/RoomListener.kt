package twilio.flutter.twilio_programmable_video

import com.twilio.video.ConnectOptions
import com.twilio.video.RemoteParticipant
import com.twilio.video.Room
import com.twilio.video.TwilioException

class RoomListener(private var internalId: Int, var connectOptions: ConnectOptions) : BaseListener(), Room.Listener {
    private val TAG = "RoomListener"

    var room: Room? = null

    override fun onConnectFailure(room: Room, e: TwilioException) {
        debug("onConnectFailure => room sid is '${room.sid}', exception is $e")
        sendEvent("connectFailure", mapOf("room" to roomToMap(room)), e)
    }

    override fun onConnected(room: Room) {
        debug("onConnected => room sid is '${room.sid}'")
        sendEvent("connected", mapOf("room" to roomToMap(room)))
        room.remoteParticipants.forEach { it.setListener(TwilioProgrammableVideoPlugin.remoteParticipantListener) }
        room.localParticipant?.setListener(TwilioProgrammableVideoPlugin.localParticipantListener)
    }

    override fun onDisconnected(room: Room, e: TwilioException?) {
        debug("onDisconnected => room sid is '${room.sid}', exception is $e")
        sendEvent("disconnected", mapOf("room" to roomToMap(room)), e)
    }

    override fun onParticipantConnected(room: Room, remoteParticipant: RemoteParticipant) {
        debug("onParticipantConnected => room sid is '${room.sid}', remoteParticipant sid is '${remoteParticipant.sid}'")
        sendEvent("participantConnected", mapOf("room" to roomToMap(room), "remoteParticipant" to RemoteParticipantListener.remoteParticipantToMap(remoteParticipant)))
        remoteParticipant.setListener(TwilioProgrammableVideoPlugin.remoteParticipantListener)
    }

    override fun onParticipantDisconnected(room: Room, remoteParticipant: RemoteParticipant) {
        debug("onParticipantDisconnected => room sid is '${room.sid}', participant sid is '${remoteParticipant.sid}'")
        sendEvent("participantDisconnected", mapOf("room" to roomToMap(room), "remoteParticipant" to RemoteParticipantListener.remoteParticipantToMap(remoteParticipant)))
    }

    override fun onReconnected(room: Room) {
        debug("onReconnected => room sid is '${room.sid}'")
        sendEvent("reconnected", mapOf("room" to roomToMap(room)))
        room.remoteParticipants.forEach { it.setListener(TwilioProgrammableVideoPlugin.remoteParticipantListener) }
    }

    override fun onReconnecting(room: Room, e: TwilioException) {
        debug("onReconnecting => room sid is '${room.sid}', exception is $e")
        sendEvent("reconnecting", mapOf("room" to roomToMap(room)), e)
    }

    override fun onRecordingStarted(room: Room) {
        debug("onRecordingStarted => room sid is '${room.sid}'")
        sendEvent("recordingStarted", mapOf("room" to roomToMap(room)))
    }

    override fun onRecordingStopped(room: Room) {
        debug("onRecordingStopped => room sid is '${room.sid}'")
        sendEvent("recordingStopped", mapOf("room" to roomToMap(room)))
    }

    override fun onDominantSpeakerChanged(room: Room, remoteParticipant: RemoteParticipant?) {
        debug("onDominantSpeakerChanged => room sid is '${room.sid}'")
        sendEvent("dominantSpeakerChanged", mapOf("room" to roomToMap(room), "remoteParticipant" to if (remoteParticipant != null) RemoteParticipantListener.remoteParticipantToMap(remoteParticipant) else null))
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
                "localParticipant" to LocalParticipantListener.localParticipantToMap(room.localParticipant),
                "remoteParticipants" to remoteParticipantsToList(room.remoteParticipants),
                "dominantSpeaker" to if (room.dominantSpeaker != null) RemoteParticipantListener.remoteParticipantToMap(room.dominantSpeaker as RemoteParticipant) else null
        )
    }

    internal fun debug(msg: String) {
        TwilioProgrammableVideoPlugin.debug("$TAG::$msg")
    }
}
