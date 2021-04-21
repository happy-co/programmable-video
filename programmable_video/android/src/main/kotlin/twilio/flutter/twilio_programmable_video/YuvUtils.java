package twilio.flutter.twilio_programmable_video;

import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.opengl.EGL14;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.twilio.video.I420Frame;

import java.io.ByteArrayOutputStream;
import java.lang.reflect.Field;
import java.nio.ByteBuffer;

import tvi.webrtc.EglBase;
import tvi.webrtc.JavaI420Buffer;
import tvi.webrtc.RendererCommon;
import tvi.webrtc.SurfaceTextureHelper;
import tvi.webrtc.VideoFrame;
import tvi.webrtc.YuvHelper;

public class YuvUtils {
    private static final int I420_Y = 0;
    private static final int I420_U = 1;
    private static final int I420_V = 2;

    /**
     * Creates an NV21 buffer from an I420 buffer.<br/>
     * Code taken from https://chromium.googlesource.com/external/webrtc/+/refs/heads/master/sdk/android/instrumentationtests/src/org/webrtc/VideoFrameBufferTest.java
     * @param i420Buffer An I420Buffer from WebRTC.
     * @return A byte array containing NV21 data.
     */
    @NonNull
    static byte[] createNV21Data(@NonNull VideoFrame.I420Buffer i420Buffer) {
        final int width = i420Buffer.getWidth();
        final int height = i420Buffer.getHeight();
        final int chromaStride = width;
        final int chromaWidth = (width + 1) / 2;
        final int chromaHeight = (height + 1) / 2;
        final int ySize = width * height;
        final ByteBuffer nv21Buffer = ByteBuffer.allocateDirect(ySize + chromaStride * chromaHeight);
        final byte[] nv21Data = nv21Buffer.array();
        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                final byte yValue = i420Buffer.getDataY().get(y * i420Buffer.getStrideY() + x);
                nv21Data[y * width + x] = yValue;
            }
        }
        for (int y = 0; y < chromaHeight; ++y) {
            for (int x = 0; x < chromaWidth; ++x) {
                final byte uValue = i420Buffer.getDataU().get(y * i420Buffer.getStrideU() + x);
                final byte vValue = i420Buffer.getDataV().get(y * i420Buffer.getStrideV() + x);
                nv21Data[ySize + y * chromaStride + 2 * x + 0] = vValue;
                nv21Data[ySize + y * chromaStride + 2 * x + 1] = uValue;
            }
        }
        return nv21Data;
    }

    @Nullable
    static VideoFrame.I420Buffer createI420Buffer(@NonNull I420Frame frame) {
        if (frame.yuvPlanes != null && frame.yuvStrides != null) {
            ByteBuffer dstY = ByteBuffer.allocateDirect(frame.yuvPlanes[I420_Y].capacity());
            ByteBuffer dstU = ByteBuffer.allocateDirect(frame.yuvPlanes[I420_U].capacity());
            ByteBuffer dstV = ByteBuffer.allocateDirect(frame.yuvPlanes[I420_V].capacity());
            int dstStrideY = frame.yuvStrides[I420_Y];
            int dstStrideU = frame.yuvStrides[I420_U];
            int dstStrideV = frame.yuvStrides[I420_V];
            YuvHelper.I420Copy(
                    frame.yuvPlanes[I420_Y],
                    frame.yuvStrides[I420_Y],
                    frame.yuvPlanes[I420_U],
                    frame.yuvStrides[I420_U],
                    frame.yuvPlanes[I420_V],
                    frame.yuvStrides[I420_V],
                    dstY,
                    dstStrideY,
                    dstU,
                    dstStrideU,
                    dstV,
                    dstStrideV,
                    frame.width,
                    frame.height
            );
            return JavaI420Buffer.wrap(
                    frame.width,
                    frame.height,
                    dstY,
                    dstStrideY,
                    dstU,
                    dstStrideU,
                    dstV,
                    dstStrideV,
                    null
            );
        } else if (frame.samplingMatrix != null && frame.textureId > 0) {
            SurfaceTextureHelper surfaceTextureHelper = getSurfaceTextureHelper();
            if (surfaceTextureHelper != null) {
                Matrix matrix = RendererCommon.convertMatrixToAndroidGraphicsMatrix(frame.samplingMatrix);
                VideoFrame.TextureBuffer textureBuffer = new DataOnlyTextureBuffer(frame.width, frame.height, VideoFrame.TextureBuffer.Type.OES, matrix, frame.textureId);
                return surfaceTextureHelper.textureToYuv(textureBuffer);
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    @NonNull
    static byte[] createJPEGData(@NonNull byte[] nv21Data, int width, int height, int quality) {
        YuvImage yuvImage = new YuvImage(nv21Data, ImageFormat.NV21, width, height,null);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        yuvImage.compressToJpeg(new Rect(0, 0, width, height), quality, out);
        return out.toByteArray();
    }

    private static SurfaceTextureHelper getSurfaceTextureHelper() {
        try {
            Field f = TwilioProgrammableVideoPlugin.cameraCapturer.getClass().getDeclaredField("surfaceTextureHelper");
            f.setAccessible(true);
            return (SurfaceTextureHelper) f.get(TwilioProgrammableVideoPlugin.cameraCapturer);
        } catch (Exception e) {
            TwilioProgrammableVideoPlugin.debug("Unable to access surfaceTextureHelper");
        }
        return null;
    }
}
