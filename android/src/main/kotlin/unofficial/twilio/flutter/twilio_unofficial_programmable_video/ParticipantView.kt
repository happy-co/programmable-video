package unofficial.twilio.flutter.twilio_unofficial_programmable_video

import com.twilio.video.VideoView
import io.flutter.plugin.platform.PlatformView

class ParticipantView(private var videoView: VideoView) : PlatformView {
    override fun getView(): VideoView {
        return videoView
    }

    override fun dispose() {
    }
}
