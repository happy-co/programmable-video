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
        if let participant = participant {
            SwiftTwilioProgrammableVideoPlugin.debug("RoomListener.dominantSpeakerDidChange => room sid is '\(room.sid)', dominantSpeaker sid is '\(String(describing: participant.sid))'")
            sendEvent("dominantSpeakerChanged", data: [ "room": roomToDict(room) as Any, "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant) as Any ])
        }
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
           "localParticipant": localParticipantToDict(room.localParticipant) as Any,
           "remoteParticipants": remoteParticipantsToArray(room.remoteParticipants)
       ]

       if room.dominantSpeaker != nil {
            dict["dominantSpeaker"] = RemoteParticipantListener.remoteParticipantToDict(room.dominantSpeaker!)
       }

       return dict
    }

    private func localParticipantToDict(_ localParticipant: LocalParticipant?) -> [String: Any]? {
        if let localParticipant = localParticipant {
            var networkQualityLevel: String
            switch localParticipant.networkQualityLevel {
                case NetworkQualityLevel.zero:
                    networkQualityLevel = "NETWORK_QUALITY_LEVEL_ZERO"
                case NetworkQualityLevel.one:
                    networkQualityLevel = "NETWORK_QUALITY_LEVEL_ONE"
                case NetworkQualityLevel.two:
                    networkQualityLevel = "NETWORK_QUALITY_LEVEL_TWO"
                case NetworkQualityLevel.three:
                    networkQualityLevel = "NETWORK_QUALITY_LEVEL_THREE"
                case NetworkQualityLevel.four:
                    networkQualityLevel = "NETWORK_QUALITY_LEVEL_FOUR"
                case NetworkQualityLevel.five:
                    networkQualityLevel = "NETWORK_QUALITY_LEVEL_FIVE"
                default: // or NetworkQualityLevel.unknown
                    networkQualityLevel = "NETWORK_QUALITY_LEVEL_UNKNOWN"
            }

            let localAudioTrackPublications = localParticipant.localAudioTracks.map({ (it) -> [String: Any] in
                return localAudioTrackPublicationToDict(it)
            })

            let localVideoTrackPublications = localParticipant.localVideoTracks.map({ (it) -> [String: Any] in
                return localVideoTrackPublicationToDict(it)
            })

            return [
                "identity": localParticipant.identity,
                "sid": localParticipant.sid as Any,
                "signalingRegion": localParticipant.signalingRegion,
                "networkQualityLevel": networkQualityLevel,
                "localAudioTrackPublications": localAudioTrackPublications,
                "localVideoTrackPublications": localVideoTrackPublications
            ]
        }
        return nil
    }

    private func localAudioTrackPublicationToDict(_ localAudioTrackPublication: LocalAudioTrackPublication) -> [String: Any] {
        return [
            "sid": localAudioTrackPublication.trackSid,
            "localAudioTrack": localAudioTrackToDict(localAudioTrackPublication.localTrack) as Any
        ]
    }

    private func localAudioTrackToDict(_ localAudioTrack: LocalAudioTrack?) -> [String: Any]? {
        if let localAudioTrack = localAudioTrack {
            return [
                "name": localAudioTrack.name,
                "enabled": localAudioTrack.isEnabled
            ]
        }
        return nil
    }

    private func localVideoTrackPublicationToDict(_ localVideoTrackPublication: LocalVideoTrackPublication) -> [String: Any] {
        return [
            "sid": localVideoTrackPublication.trackSid,
            "localVideoTrack": localVideoTrackToDict(localVideoTrackPublication.localTrack) as Any
        ]
    }

    private func localVideoTrackToDict(_ localVideoTrack: LocalVideoTrack?) -> [String: Any]? {
        if let localVideoTrack = localVideoTrack {
            return [
                "name": localVideoTrack.name,
                "enabled": localVideoTrack.isEnabled,
                "videoCapturer": RoomListener.videoSourceToDict(localVideoTrack.source)
            ]
        }
        return nil
    }

    public static func videoSourceToDict(_ videoSource: VideoSource?) -> [String: Any] {
        if let cameraSource = videoSource as? CameraSource {
            var cameraSourceType: String
            switch cameraSource.device?.position {
                case .front:
                    cameraSourceType = "FRONT_CAMERA"
                case .back:
                    cameraSourceType = "BACK_CAMERA"
                default:
                    cameraSourceType = "UNKNOWN"
            }

            return [
                "type": "CameraCapturer",
                "cameraSource": cameraSourceType
            ]
        }
        return [
            "type": "Unknown",
            "isScreenCast": videoSource?.isScreencast ?? false
        ]
    }
}
