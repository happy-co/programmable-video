package twilio.flutter.twilio_programmable_video

import com.twilio.video.VideoTrack
import com.twilio.video.VideoView
import io.flutter.plugin.platform.PlatformView

class ParticipantView : PlatformView {
    private var videoView: VideoView

    private var videoTrack: VideoTrack

    constructor(videoView: VideoView, videoTrack: VideoTrack) {
        this.videoView = videoView
        this.videoTrack = videoTrack
        videoTrack.addRenderer(videoView)
    }

    override fun getView(): VideoView {
        return videoView
    }

    override fun dispose() {
        TwilioProgrammableVideoPlugin.debug("Disposing ParticipantView")
    }
}
