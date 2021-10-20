// swiftlint:disable type_body_length
import Flutter
import Foundation
import TwilioVideo

class RemoteParticipantListener: BaseListener, RemoteParticipantDelegate {
    let TAG = "RemoteParticipantListener"

    func remoteParticipantDidDisableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        debug("remoteParticipantDidDisableAudioTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled)"
        )
        sendEvent("audioTrackDisabled", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteAudioTrackPublication": RemoteParticipantListener.remoteAudioTrackPublicationToDict(publication)
        ])
    }

    func remoteParticipantDidEnableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        debug("remoteParticipantDidEnableAudioTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled)"
        )
        sendEvent("audioTrackEnabled", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteAudioTrackPublication": RemoteParticipantListener.remoteAudioTrackPublicationToDict(publication)
        ])
    }

    func remoteParticipantDidPublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        debug("remoteParticipantDidPublishAudioTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("audioTrackPublished", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteAudioTrackPublication": RemoteParticipantListener.remoteAudioTrackPublicationToDict(publication)
        ])
    }

    func remoteParticipantDidUnpublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        debug("remoteParticipantDidUnpublishAudioTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("audioTrackUnpublished", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteAudioTrackPublication": RemoteParticipantListener.remoteAudioTrackPublicationToDict(publication)
        ])
    }

    func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        debug("didSubscribeToAudioTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("audioTrackSubscribed", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteAudioTrackPublication": RemoteParticipantListener.remoteAudioTrackPublicationToDict(publication)
        ])
    }

    func didFailToSubscribeToAudioTrack(publication: RemoteAudioTrackPublication, error: Error, participant: RemoteParticipant) {
        debug("didFailToSubscribeToAudioTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("audioTrackSubscribedFailed", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteAudioTrackPublication": RemoteParticipantListener.remoteAudioTrackPublicationToDict(publication)
        ], error: error)
    }

    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        debug("didUnsubscribeFromAudioTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("audioTrackUnsubscribed", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteAudioTrackPublication": RemoteParticipantListener.remoteAudioTrackPublicationToDict(publication),
            "remoteAudioTrack": RemoteParticipantListener.remoteAudioTrackToDict(audioTrack) as Any
        ])
    }

    func remoteParticipantDidPublishDataTrack(participant: RemoteParticipant, publication: RemoteDataTrackPublication) {
        debug("remoteParticipantDidPublishDataTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("dataTrackPublished", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteDataTrackPublication": RemoteParticipantListener.remoteDataTrackPublicationToDict(publication)
        ])
    }

    func remoteParticipantDidUnpublishDataTrack(participant: RemoteParticipant, publication: RemoteDataTrackPublication) {
        debug("remoteParticipantDidUnpublishDataTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("dataTrackUnpublished", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteDataTrackPublication": RemoteParticipantListener.remoteDataTrackPublicationToDict(publication)
        ])
    }

    func remoteParticipantNetworkQualityLevelDidChange(participant: RemoteParticipant, networkQualityLevel: NetworkQualityLevel) {
        debug("didChangeNetworkQualityLevel =>"  +
                                                    "sid: \(participant.sid ?? "")")
        sendEvent("networkQualityLevelChanged", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "networkQualityLevel": Mapper.networkQualityLevelToString(networkQualityLevel) as Any
        ])
    }

    func didSubscribeToDataTrack(dataTrack: RemoteDataTrack, publication: RemoteDataTrackPublication, participant: RemoteParticipant) {
        debug("didSubscribeToDataTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("dataTrackSubscribed", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteDataTrackPublication": RemoteParticipantListener.remoteDataTrackPublicationToDict(publication)
        ])
        publication.remoteTrack?.delegate = SwiftTwilioProgrammableVideoPlugin.remoteDataTrackListener
    }

    func didFailToSubscribeToDataTrack(publication: RemoteDataTrackPublication, error: Error, participant: RemoteParticipant) {
        debug("didFailToSubscribeToDataTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("dataTrackSubscriptionFailed", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteDataTrackPublication": RemoteParticipantListener.remoteDataTrackPublicationToDict(publication)
        ], error: error)
    }

    func didUnsubscribeFromDataTrack(dataTrack: RemoteDataTrack, publication: RemoteDataTrackPublication, participant: RemoteParticipant) {
        debug("remoteParticipantDidUnpublishDataTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("dataTrackUnsubscribed", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteDataTrackPublication": RemoteParticipantListener.remoteDataTrackPublicationToDict(publication),
            "remoteDataTrack": RemoteDataTrackListener.remoteDataTrackToDict(dataTrack)
        ])
    }

    func remoteParticipantDidDisableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        debug("remoteParticipantDidDisableVideoTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled)"
        )
        sendEvent("videoTrackDisabled", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteVideoTrackPublication": RemoteParticipantListener.remoteVideoTrackPublicationToDict(publication)
        ])
    }

    func remoteParticipantDidEnableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        debug("remoteParticipantDidEnableVideoTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled)"
        )
        sendEvent("videoTrackEnabled", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteVideoTrackPublication": RemoteParticipantListener.remoteVideoTrackPublicationToDict(publication)
        ])
    }

    func remoteParticipantDidPublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        debug("remoteParticipantDidPublishVideoTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("videoTrackPublished", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteVideoTrackPublication": RemoteParticipantListener.remoteVideoTrackPublicationToDict(publication)
        ])
    }

    func remoteParticipantDidUnpublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        debug("remoteParticipantDidUnpublishVideoTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("videoTrackUnpublished", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteVideoTrackPublication": RemoteParticipantListener.remoteVideoTrackPublicationToDict(publication)
        ])
    }

    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        debug("didSubscribeToVideoTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("videoTrackSubscribed", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteVideoTrackPublication": RemoteParticipantListener.remoteVideoTrackPublicationToDict(publication)
        ])
    }

    func didFailToSubscribeToVideoTrack(publication: RemoteVideoTrackPublication, error: Error, participant: RemoteParticipant) {
        debug("didFailToSubscribeToVideoTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("videoTrackSubscribedFailed", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteVideoTrackPublication": RemoteParticipantListener.remoteVideoTrackPublicationToDict(publication)
        ], error: error)
    }

    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        debug("didUnsubscribeFromVideoTrack => " +
            "trackSid: \(publication.trackSid), " +
            "isTrackEnabled: \(publication.isTrackEnabled), " +
            "isTrackSubscribed: \(publication.isTrackSubscribed)"
        )
        sendEvent("videoTrackUnsubscribed", data: [
            "remoteParticipant": RemoteParticipantListener.remoteParticipantToDict(participant, noTracks: true),
            "remoteVideoTrackPublication": RemoteParticipantListener.remoteVideoTrackPublicationToDict(publication),
            "remoteVideoTrack": RemoteParticipantListener.remoteVideoTrackToDict(videoTrack) as Any
        ])
    }

    public static func remoteParticipantToDict(_ remoteParticipant: RemoteParticipant, noTracks: Bool = false) -> [String: Any] {
        let remoteAudioTrackPublications: Any? = noTracks ? nil : remoteParticipant.remoteAudioTracks.map { (it) -> [String: Any] in
            return RemoteParticipantListener.remoteAudioTrackPublicationToDict(it)
        }
        let remoteVideoTrackPublications: Any? = noTracks ? nil : remoteParticipant.remoteVideoTracks.map({ (it) -> [String: Any] in
            return remoteVideoTrackPublicationToDict(it)
        })

        return [
            "identity": remoteParticipant.identity,
            "sid": remoteParticipant.sid as Any,
            "remoteAudioTrackPublications": remoteAudioTrackPublications as Any,
            "remoteVideoTrackPublications": remoteVideoTrackPublications as Any
        ]
    }

    static func remoteAudioTrackPublicationToDict(_ remoteAudioTrackPublication: RemoteAudioTrackPublication) -> [String: Any] {
        return [
            "sid": remoteAudioTrackPublication.trackSid,
            "name": remoteAudioTrackPublication.trackName,
            "enabled": remoteAudioTrackPublication.isTrackEnabled,
            "subscribed": remoteAudioTrackPublication.isTrackSubscribed,
            "remoteAudioTrack": remoteAudioTrackToDict(remoteAudioTrackPublication.remoteTrack) as Any
        ]
    }

    static func remoteAudioTrackToDict(_ remoteAudioTrack: RemoteAudioTrack?) -> [String: Any]? {
        if let remoteAudioTrack = remoteAudioTrack {
            return [
                "sid": remoteAudioTrack.sid,
                "name": remoteAudioTrack.name,
                "enabled": remoteAudioTrack.isEnabled
            ]
        }
        return nil
    }

    static func remoteDataTrackPublicationToDict(_ remoteDataTrackPublication: RemoteDataTrackPublication) -> [String: Any] {
        return [
            "sid": remoteDataTrackPublication.trackSid,
            "name": remoteDataTrackPublication.trackName,
            "enabled": remoteDataTrackPublication.isTrackEnabled,
            "subscribed": remoteDataTrackPublication.isTrackSubscribed,
            "remoteDataTrack": RemoteDataTrackListener.remoteDataTrackToDict(remoteDataTrackPublication.remoteTrack) as Any
        ]
    }

    static func remoteVideoTrackPublicationToDict(_ remoteVideoTrackPublication: RemoteVideoTrackPublication) -> [String: Any] {
        return [
            "sid": remoteVideoTrackPublication.trackSid,
            "name": remoteVideoTrackPublication.trackName,
            "enabled": remoteVideoTrackPublication.isTrackEnabled,
            "subscribed": remoteVideoTrackPublication.isTrackSubscribed,
            "remoteVideoTrack": remoteVideoTrackToDict(remoteVideoTrackPublication.remoteTrack) as Any
        ]
    }

    static func remoteVideoTrackToDict(_ remoteVideoTrack: RemoteVideoTrack?) -> [String: Any]? {
        if let remoteAudioTrack = remoteVideoTrack {
            return [
                "sid": remoteAudioTrack.sid,
                "name": remoteAudioTrack.name,
                "enabled": remoteAudioTrack.isEnabled
            ]
        }
        return nil
    }

    func debug(_ msg: String) {
        SwiftTwilioProgrammableVideoPlugin.debug("\(TAG)::\(msg)")
    }
}
