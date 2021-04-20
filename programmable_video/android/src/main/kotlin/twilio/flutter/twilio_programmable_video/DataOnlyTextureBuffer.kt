package twilio.flutter.twilio_programmable_video

import android.graphics.Matrix
import tvi.webrtc.VideoFrame

class DataOnlyTextureBuffer(
        private val width: Int,
        private val height: Int,
        private val type: VideoFrame.TextureBuffer.Type,
        private val matrix: Matrix,
        private val textureId: Int
) : VideoFrame.TextureBuffer {
    override fun getTextureId(): Int {
        return textureId
    }

    override fun getHeight(): Int {
        return height
    }

    override fun getType(): VideoFrame.TextureBuffer.Type {
        return type
    }

    override fun getWidth(): Int {
        return width
    }

    override fun getTransformMatrix(): Matrix {
        return matrix
    }

    override fun toI420(): VideoFrame.I420Buffer { throw NotImplementedError() }

    override fun retain() { throw NotImplementedError() }

    override fun cropAndScale(p0: Int, p1: Int, p2: Int, p3: Int, p4: Int, p5: Int): VideoFrame.Buffer { throw NotImplementedError() }

    override fun release() { throw NotImplementedError() }
}
