package twilio.flutter.twilio_programmable_video

import android.content.Context
import com.twilio.video.VideoTrack
import com.twilio.video.VideoView
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class ParticipantViewFactory(createArgsCodec: MessageCodec<Any>, private val plugin: PluginHandler) : PlatformViewFactory(createArgsCodec) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView? {
        var videoTrack: VideoTrack? = null

        if (args != null) {
            val params = args as Map<String, Any>
            if (params.containsKey("isLocal")) {
                TwilioProgrammableVideoPlugin.debug("ParticipantViewFactory.create => constructing local view")
                val localParticipant = plugin.getLocalParticipant()
                if (localParticipant != null && localParticipant.localVideoTracks != null && localParticipant.localVideoTracks?.size != 0) {
                    videoTrack = localParticipant.localVideoTracks!![0].localVideoTrack
                }
            } else {
                TwilioProgrammableVideoPlugin.debug("ParticipantViewFactory.create => constructing view with params: '${params.values.joinToString(", ")}'")
                if (params.containsKey("remoteParticipantSid") && params.containsKey("remoteVideoTrackSid")) {
                    val remoteParticipant = plugin.getRemoteParticipant(params["remoteParticipantSid"] as String)
                    val remoteVideoTrack = remoteParticipant?.remoteVideoTracks?.find { it.trackSid == params["remoteVideoTrackSid"] }
                    if (remoteParticipant != null && remoteVideoTrack != null) {
                        videoTrack = remoteVideoTrack.remoteVideoTrack
                    }
                }
            }

            if (videoTrack != null) {
                val videoView = VideoView(context)
                videoView.mirror = params["mirror"] as Boolean
                return ParticipantView(videoView, videoTrack)
            }
        }

        return null
    }
}
