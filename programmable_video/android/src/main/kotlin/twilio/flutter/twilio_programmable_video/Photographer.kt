package twilio.flutter.twilio_programmable_video

import java.util.concurrent.atomic.AtomicReference
import tvi.webrtc.VideoFrame
import tvi.webrtc.VideoProcessor
import tvi.webrtc.VideoSink

typealias PictureListener = (ByteArray?) -> Unit

class Photographer : VideoProcessor {
    private val pictureRequest = AtomicReference<PictureListener?>(null)
    private var videoSink: VideoSink? = null

    override fun onCapturerStopped() {}
    override fun onCapturerStarted(success: Boolean) {}

    override fun setSink(videoSink: VideoSink?) {
        this.videoSink = videoSink
    }

    override fun onFrameCaptured(frame: VideoFrame?) {
        if (frame != null) {
            videoSink?.onFrame(frame)
        }
    }

    override fun onFrameCaptured(
            videoFrame: VideoFrame?,
            parameters: VideoProcessor.FrameAdaptationParameters?
    ) {
        if (videoFrame != null) {
            videoFrame.retain()

            pictureRequest.getAndSet(null)?.invoke(videoFrame.toJpeg())

            val adaptedFrame = VideoProcessor.applyFrameAdaptationParameters(videoFrame, parameters)
            this.onFrameCaptured(adaptedFrame)
            adaptedFrame?.release()

            videoFrame.release()
        }
    }

    fun takePicture(pictureListener: PictureListener) {
        this.pictureRequest.set(pictureListener)
    }
}
