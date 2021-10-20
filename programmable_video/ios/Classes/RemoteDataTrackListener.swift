import Flutter
import Foundation
import TwilioVideo

class RemoteDataTrackListener: BaseListener, RemoteDataTrackDelegate {
    let TAG = "RemoteDataTrackListener"

    func remoteDataTrackDidReceiveData(remoteDataTrack: RemoteDataTrack, message: Data) {
        debug("didReceiveData => " +
            "sid: \(remoteDataTrack.sid), " +
            "message: \(message)"
        )
        sendEvent("bufferMessage", data: [
            "remoteDataTrack": RemoteDataTrackListener.remoteDataTrackToDict(remoteDataTrack) as Any,
            "message": message
        ])
    }

    func remoteDataTrackDidReceiveString(remoteDataTrack: RemoteDataTrack, message: String) {
        debug("didReceiveString => " +
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

    func debug(_ msg: String) {
        SwiftTwilioProgrammableVideoPlugin.debug("\(TAG)::\(msg)")
    }
}
