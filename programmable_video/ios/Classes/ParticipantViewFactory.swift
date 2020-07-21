import Flutter
import Foundation
import TwilioVideo

class ParticipantViewFactory: NSObject, FlutterPlatformViewFactory {
    private var plugin: PluginHandler

    init(_ plugin: PluginHandler) {
        self.plugin = plugin
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let localParticipant = plugin.getLocalParticipant()!
        var shouldMirror = false
        var videoTrack: VideoTrack = localParticipant.localVideoTracks[0].localTrack!

        if let params = args as? [String: Any] {
            shouldMirror = params["mirror"] as? Bool ?? false
            if let remoteParticipantSid = params["remoteParticipantSid"] as? String, let remoteVideoTrackSid = params["remoteVideoTrackSid"] as? String {
                SwiftTwilioProgrammableVideoPlugin.debug("ParticipantViewFactory.create => constructing view with: '\(params)'")
                if let remoteParticipant = plugin.getRemoteParticipant(remoteParticipantSid) {
                    if let remoteVideoTrack = remoteParticipant.remoteVideoTracks.first(where: { $0.trackSid == remoteVideoTrackSid }) {
                        videoTrack = remoteVideoTrack.remoteTrack!
                    }
                }
            } else {
                SwiftTwilioProgrammableVideoPlugin.debug("ParticipantViewFactory.create => constructing local view")
           }
        }

        let videoView = VideoView.init(frame: frame)
        videoView.shouldMirror = shouldMirror
        videoView.contentMode = .scaleAspectFill
        return ParticipantView(videoView, videoTrack: videoTrack)
    }
}
