package twilio.flutter.twilio_programmable_video

import com.twilio.video.VideoTrack
import com.twilio.video.VideoView
import io.flutter.plugin.platform.PlatformView

class ParticipantView(private var videoView: VideoView, videoTrack: VideoTrack) : PlatformView {

    init {
        videoTrack.addSink(videoView)
    }

    override fun getView(): VideoView {
        return videoView
    }

    override fun dispose() {
        TwilioProgrammableVideoPlugin.debug("Disposing ParticipantView")
    }
}
