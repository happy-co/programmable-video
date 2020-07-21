import Flutter
import Foundation
import TwilioVideo

class RemoteDataTrackListener: BaseListener, RemoteDataTrackDelegate {
    func remoteDataTrackDidReceiveData(remoteDataTrack: RemoteDataTrack, message: Data) {
        SwiftTwilioProgrammableVideoPlugin.debug("RemoteDataTrackListener.didReceiveData => " +
            "sid: \(remoteDataTrack.sid), " +
            "message: \(message)"
        )
        sendEvent("bufferMessage", data: [
            "remoteDataTrack": RemoteDataTrackListener.remoteDataTrackToDict(remoteDataTrack) as Any,
            "message": message
        ])
    }

    func remoteDataTrackDidReceiveString(remoteDataTrack: RemoteDataTrack, message: String) {
        SwiftTwilioProgrammableVideoPlugin.debug("RemoteDataTrackListener.didReceiveString => " +
            "sid: \(remoteDataTrack.sid), " +
            "message: \(message)"
        )
        sendEvent("stringMessage", data: [
            "remoteDataTrack": RemoteDataTrackListener.remoteDataTrackToDict(remoteDataTrack) as Any,
            "message": message
        ])
    }

    static func remoteDataTrackToDict(_ remoteDataTrack: RemoteDataTrack?) -> [String: Any]? {
        if let remoteDataTrack = remoteDataTrack {
            return [
                "sid": remoteDataTrack.sid,
                "name": remoteDataTrack.name,
                "enabled": remoteDataTrack.isEnabled,
                "ordered": remoteDataTrack.isOrdered,
                "reliable": remoteDataTrack.isReliable,
                "maxPacketLifeTime": remoteDataTrack.maxPacketLifeTime,
                "maxRetransmits": remoteDataTrack.maxRetransmits
            ]
        }
        return nil
    }
}
