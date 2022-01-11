import Flutter
import Foundation
import TwilioVideo

class LocalParticipantListener: BaseListener, LocalParticipantDelegate {
    let TAG = "LocalParticipantListener"

    func localParticipantDidPublishAudioTrack(participant: LocalParticipant, audioTrackPublication: LocalAudioTrackPublication) {
        debug("didPublishAudioTrack => " +
            "trackSid: \(audioTrackPublication.trackSid), " +
            "isTrackEnabled: \(audioTrackPublication.isTrackEnabled)"
        )
        sendEvent("audioTrackPublished", data: [
            "localParticipant": LocalParticipantListener.localParticipantToDict(participant) as Any,
            "localAudioTrackPublication": LocalParticipantListener.localAudioTrackPublicationToDict(audioTrackPublication)
        ])
    }

    func localParticipantDidFailToPublishAudioTrack(participant: LocalParticipant, audioTrack: LocalAudioTrack, error: Error) {
        debug("didFailToPublishAudioTrack => \(error)")
        sendEvent("audioTrackPublicationFailed", data: [
            "localParticipant": LocalParticipantListener.localParticipantToDict(participant) as Any,
            "localAudioTrack": LocalParticipantListener.localAudioTrackToDict(audioTrack) as Any
        ], error: error)
    }

    func localParticipantDidPublishDataTrack(participant: LocalParticipant, dataTrackPublication: LocalDataTrackPublication) {
        debug("didPublishDataTrack => " +
            "trackSid: \(dataTrackPublication.trackSid), " +
            "isTrackEnabled: \(dataTrackPublication.isTrackEnabled)"
        )
        sendEvent("dataTrackPublished", data: [
            "localParticipant": LocalParticipantListener.localParticipantToDict(participant) as Any,
            "localDataTrackPublication": LocalParticipantListener.localDataTrackPublicationToDict(dataTrackPublication)
        ])
    }

    func localParticipantDidFailToPublishDataTrack(participant: LocalParticipant, dataTrack: LocalDataTrack, error: Error) {
        debug("didFailToPublishDataTrack => \(error)")
        sendEvent("dataTrackPublicationFailed", data: [
            "localParticipant": LocalParticipantListener.localParticipantToDict(participant) as Any,
            "localDataTrack": LocalParticipantListener.localDataTrackToDict(dataTrack) as Any
        ], error: error)
    }

    func localParticipantDidPublishVideoTrack(participant: LocalParticipant, videoTrackPublication: LocalVideoTrackPublication) {
        debug("didPublishVideoTrack => " +
            "trackSid: \(videoTrackPublication.trackSid), " +
            "isTrackEnabled: \(videoTrackPublication.isTrackEnabled)"
        )
        sendEvent("videoTrackPublished", data: [
            "localParticipant": LocalParticipantListener.localParticipantToDict(participant) as Any,
            "localVideoTrackPublication": LocalParticipantListener.localVideoTrackPublicationToDict(videoTrackPublication)
        ])
    }

    func localParticipantDidFailToPublishVideoTrack(participant: LocalParticipant, videoTrack: LocalVideoTrack, error: Error) {
        debug("didFailToPublishVideoTrack => \(error)")
        sendEvent("videoTrackPublicationFailed", data: [
            "localParticipant": LocalParticipantListener.localParticipantToDict(participant) as Any,
            "localVideoTrack": LocalParticipantListener.localVideoTrackToDict(videoTrack) as Any
        ], error: error)
    }

    func localParticipantNetworkQualityLevelDidChange(participant: LocalParticipant, networkQualityLevel: NetworkQualityLevel) {
        debug("didChangeNetworkQualityLevel =>" +
                "sid: \(participant.sid ?? "")")
        sendEvent("networkQualityLevelChanged", data: [
            "localParticipant": LocalParticipantListener.localParticipantToDict(participant) as Any,
            "networkQualityLevel": Mapper.networkQualityLevelToString(networkQualityLevel) as Any
        ])
    }

    public static func localParticipantToDict(_ localParticipant: LocalParticipant?) -> [String: Any]? {
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
                return LocalParticipantListener.localAudioTrackPublicationToDict(it)
            })

            let localDataTrackPublications = localParticipant.localDataTracks.map({ (it) -> [String: Any] in
                return LocalParticipantListener.localDataTrackPublicationToDict(it)
            })

            let localVideoTrackPublications = localParticipant.localVideoTracks.map({ (it) -> [String: Any] in
                return LocalParticipantListener.localVideoTrackPublicationToDict(it)
            })

            return [
                "identity": localParticipant.identity,
                "sid": localParticipant.sid as Any,
                "signalingRegion": localParticipant.signalingRegion,
                "networkQualityLevel": networkQualityLevel,
                "localAudioTrackPublications": localAudioTrackPublications,
                "localDataTrackPublications": localDataTrackPublications,
                "localVideoTrackPublications": localVideoTrackPublications
            ]
        }
        return nil
    }

    private static func localAudioTrackPublicationToDict(_ localAudioTrackPublication: LocalAudioTrackPublication) -> [String: Any] {
        return [
            "sid": localAudioTrackPublication.trackSid,
            "localAudioTrack": LocalParticipantListener.localAudioTrackToDict(localAudioTrackPublication.localTrack) as Any
        ]
    }

    private static func localAudioTrackToDict(_ localAudioTrack: LocalAudioTrack?) -> [String: Any]? {
        if let localAudioTrack = localAudioTrack {
            return [
                "name": localAudioTrack.name,
                "enabled": localAudioTrack.isEnabled
            ]
        }
        return nil
    }

    private static func localDataTrackPublicationToDict(_ localDataTrackPublication: LocalDataTrackPublication) -> [String: Any] {
        return [
            "sid": localDataTrackPublication.trackSid,
            "localDataTrack": LocalParticipantListener.localDataTrackToDict(localDataTrackPublication.localTrack) as Any
        ]
    }

    private static func localDataTrackToDict(_ localDataTrack: LocalDataTrack?) -> [String: Any]? {
        if let localDataTrack = localDataTrack {
            return [
                "name": localDataTrack.name,
                "enabled": localDataTrack.isEnabled,
                "ordered": localDataTrack.isOrdered,
                "reliable": localDataTrack.isReliable,
                "maxPacketLifeTime": localDataTrack.maxPacketLifeTime,
                "maxRetransmits": localDataTrack.maxRetransmits
            ]
        }
        return nil
    }

    private static func localVideoTrackPublicationToDict(_ localVideoTrackPublication: LocalVideoTrackPublication) -> [String: Any] {
        return [
            "sid": localVideoTrackPublication.trackSid,
            "localVideoTrack": LocalParticipantListener.localVideoTrackToDict(localVideoTrackPublication.localTrack) as Any
        ]
    }

    private static func localVideoTrackToDict(_ localVideoTrack: LocalVideoTrack?) -> [String: Any]? {
        if let localVideoTrack = localVideoTrack {
            return [
                "name": localVideoTrack.name,
                "enabled": localVideoTrack.isEnabled,
                "videoCapturer": SwiftTwilioProgrammableVideoPlugin.pluginHandler.videoSourceToDict(localVideoTrack.source, newCameraSource: nil) as Any
            ]
        }
        return nil
    }

    func debug(_ msg: String) {
        SwiftTwilioProgrammableVideoPlugin.debug("\(TAG)::\(msg)")
    }
}
