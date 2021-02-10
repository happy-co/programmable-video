import Flutter
import Foundation
import TwilioVideo

class RoomListener: BaseListener, RoomDelegate {
    public var connectOptions: ConnectOptions

    public var room: Room?

    init(_ roomId: Int, _ connectOptions: ConnectOptions) {
        self.connectOptions = connectOptions
    }

    func roomDidFailToConnect(room: Room, error: Error) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.roomDidFailToConnect => room sid is '\(room.sid)', error is \(error)")
        sendEvent("connectFailure", data: [ "room": roomToDict(room) ], error: error)
    }

    func roomDidConnect(room: Room) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.roomDidConnect => room sid is '\(room.sid)'")
        sendEvent("connected", data: [ "room": roomToDict(room) ])

        for remoteParticipant in room.remoteParticipants {
            remoteParticipant.delegate = SwiftTwilioProgrammableVideoPlugin.remoteParticipantListener
        }
        room.localParticipant?.delegate = SwiftTwilioProgrammableVideoPlugin.localParticipantListener
    }

    func roomDidDisconnect(room: Room, error: Error?) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.roomDidDisconnect => room sid is '\(room.sid)', error is \(String(describing: error))")
        sendEvent("disconnected", data: [ "room": roomToDict(room) ], error: error)
    }

    func roomDidReconnect(room: Room) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.roomDidReconnect   => room sid is '\(room.sid)'")
        sendEvent("reconnected", data: [ "room": roomToDict(room) ])

        for remoteParticipant in room.remoteParticipants {
            remoteParticipant.delegate = SwiftTwilioProgrammableVideoPlugin.remoteParticipantListener
        }
    }

    func roomIsReconnecting(room: Room, error: Error) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.roomIsReconnecting => room sid is '\(room.sid)', error is \(error)")
        sendEvent("reconnecting", data: [ "room": roomToDict(room) ], error: error)
    }

    func roomDidStartRecording(room: Room) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.roomDidStartRecording => room sid is '\(room.sid)'")
        sendEvent("recordingStarted", data: [ "room": roomToDict(room) ])
    }

    func roomDidStopRecording(room: Room) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.roomDidStopRecording => room sid is '\(room.sid)'")
        sendEvent("recordingStopped", data: [ "room": roomToDict(room) ])
    }

    func participantDidConnect(room: Room, participant: RemoteParticipant) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.participantDidConnect => room sid is '\(room.sid)', remoteParticipant sid is '\(String(describing: participant.sid))'")
        sendEvent("participantConnected", data: [ "room": roomToDict(room) as Any, "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant) ])
        participant.delegate = SwiftTwilioProgrammableVideoPlugin.remoteParticipantListener
    }

    func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.participantDidDisconnect => room sid is '\(room.sid)', remoteParticipant sid is '\(String(describing: participant.sid))'")
        sendEvent("participantDisconnected", data: [ "room": roomToDict(room) as Any, "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant) as Any ])
    }

    func dominantSpeakerDidChange(room: Room, participant: RemoteParticipant?) {
        SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.dominantSpeakerDidChange => room sid is '\(room.sid)', dominantSpeaker sid is '\(participant != nil ? String(describing: participant!.sid) : "N/A")'")
        sendEvent("dominantSpeakerChanged", data: [ "room": roomToDict(room) as Any, "remoteParticipant": (participant != nil ? RemoteParticipantListener.remoteParticipantToDict(participant!) : nil) as Any])
    }

    private func remoteParticipantsToArray(_ remoteParticipants: [RemoteParticipant]) -> [[String: Any]] {
        return remoteParticipants.map({ (it) -> [String: Any] in
            return RemoteParticipantListener.remoteParticipantToDict(it)
        })
    }

    private func roomToDict(_ room: Room) -> [String: Any] {
        var roomState: String
        switch room.state {
            case Room.State.connecting:
                roomState = "CONNECTING"
            case Room.State.connected:
                roomState = "CONNECTED"
            case Room.State.reconnecting:
                roomState = "RECONNECTING"
            case Room.State.disconnected:
                roomState = "DISCONNECTED"
            default:
                roomState = "UNKNOWN"
        }

        var dict = [
           "sid": room.sid,
           "name": room.name,
           "state": roomState,
           "mediaRegion": room.mediaRegion as Any,
           "localParticipant": LocalParticipantListener.localParticipantToDict(room.localParticipant) as Any,
           "remoteParticipants": remoteParticipantsToArray(room.remoteParticipants)
       ]

       if room.dominantSpeaker != nil {
            dict["dominantSpeaker"] = RemoteParticipantListener.remoteParticipantToDict(room.dominantSpeaker!)
       }

       return dict
    }
}
