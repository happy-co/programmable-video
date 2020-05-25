import Flutter
import Foundation
import TwilioVideo

class ParticipantView: NSObject, FlutterPlatformView {
    private var videoView: VideoView

    private var videoTrack: VideoTrack

    init(_ videoView: VideoView, videoTrack: VideoTrack) {
        self.videoView = videoView
        self.videoTrack = videoTrack
        videoTrack.addRenderer(videoView)
    }

    public func view() -> UIView {
        return videoView
    }
}
