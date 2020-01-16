package unofficial.twilio.flutter.twilio_unofficial_programmable_video

import com.twilio.video.*

class RoomListener(private var internalId: Int, var connectOptions: ConnectOptions) : BaseListener(), Room.Listener {
    var room: Room? = null

    override fun onConnectFailure(room: Room, e: TwilioException) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onConnectFailure => room sid is '${room.sid}', exception is $e")
        sendEvent("connectFailure", mapOf("room" to roomToMap(room)), e)
    }

    override fun onConnected(room: Room) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onConnected => room sid is '${room.sid}'")
        sendEvent("connected", mapOf("room" to roomToMap(room), "localParticipant" to localParticipantToMap(room.localParticipant), "remoteParticipants" to remoteParticipantsToList(room.remoteParticipants)))
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
        sendEvent("reconnecting", mapOf("room" to roomToMap(room)), e)
    }

    override fun onRecordingStarted(room: Room) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onRecordingStarted => room sid is '${room.sid}'")
        sendEvent("recordingStarted", mapOf("room" to roomToMap(room)))
    }

    override fun onRecordingStopped(room: Room) {
        TwilioUnofficialProgrammableVideoPlugin.debug("RoomListener.onRecordingStopped => room sid is '${room.sid}'")
        sendEvent("recordingStopped", mapOf("room" to roomToMap(room)))
    }

    private fun remoteParticipantsToList(remoteParticipants: List<RemoteParticipant>): List<Map<String, Any>> {
        return remoteParticipants.map { RemoteParticipantListener.remoteParticipantToMap(it) }
    }

    private fun localParticipantToMap(localParticipant: LocalParticipant?): Map<String, Any?> {
        return mapOf("identity" to localParticipant?.identity, "sid" to localParticipant?.sid)
    }

    private fun roomToMap(room: Room): Map<String, String> {
        return mapOf("sid" to room.sid, "name" to room.name)
    }
}