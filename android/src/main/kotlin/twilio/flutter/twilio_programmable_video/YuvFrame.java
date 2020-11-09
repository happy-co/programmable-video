package twilio.flutter.twilio_programmable_video;

import android.graphics.Bitmap;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.twilio.video.I420Frame;

import java.nio.ByteBuffer;

public class YuvFrame {
    private static final int PROCESSING_NONE = 0x00;
    private static final int PROCESSING_CROP_TO_SQUARE = 0x01;
    // Constants for indexing I420Frame information, for readability.
    private static final int I420_Y = 0;
    private static final int I420_V = 1;
    private static final int I420_U = 2;
    private final Object planeLock = new Object();
    private int width;
    private int height;
    private byte[] yPlane;
    private byte[] uPlane;
    private byte[] vPlane;
    private int rotationDegree;

    /**
     * Creates a YuvFrame from the provided I420Frame. Does no processing, and uses the current time as a timestamp.
     *
     * @param i420Frame Source I420Frame.
     */
    @SuppressWarnings("unused")
    public YuvFrame(final I420Frame i420Frame) {
        fromI420Frame(i420Frame);
    }

    /**
     * Replaces the data in this YuvFrame with the data from the provided frame. Will create new byte arrays to hold pixel data if necessary,
     * or will reuse existing arrays if they're already the correct size.
     *
     * @param i420Frame       Source I420Frame.
     */
    private void fromI420Frame(final I420Frame i420Frame) {
        synchronized (planeLock) {
            try {
                // Copy YUV stride information
                int[] yuvStrides = new int[i420Frame.yuvStrides.length];
                System.arraycopy(i420Frame.yuvStrides, 0, yuvStrides, 0, i420Frame.yuvStrides.length);
                // Copy rotation information
                rotationDegree = i420Frame.rotationDegree;  // Just save rotation info for now, doing actual rotation can wait until per-pixel processing.
                copyPlanes(i420Frame);
            } catch (Throwable t) {
                dispose();
            }
        }
    }

    private void dispose() {
        yPlane = null;
        vPlane = null;
        uPlane = null;
    }

    public boolean hasData() {
        return yPlane != null && vPlane != null && uPlane != null;
    }

    /**
     * Copy the Y, V, and U planes from the source I420Frame.
     * Sets width and height.
     *
     * @param i420Frame Source frame.
     */
    private void copyPlanes(final I420Frame i420Frame) {
        synchronized (planeLock) {
            // Copy the Y, V, and U ByteBuffers to their corresponding byte arrays.
            // Existing byte arrays are passed in for possible reuse.
            yPlane = copyByteBuffer(yPlane, i420Frame.yuvPlanes[I420_Y]);
            vPlane = copyByteBuffer(vPlane, i420Frame.yuvPlanes[I420_V]);
            uPlane = copyByteBuffer(uPlane, i420Frame.yuvPlanes[I420_U]);

            // Set the width and height of the frame.
            width = i420Frame.width;
            height = i420Frame.height;
        }
    }

    /**
     * Copies the entire contents of a ByteBuffer into a byte array.
     * If the byte array exists, and is the correct size, it will be reused.
     * If the byte array is null, or isn't properly sized, a new byte array will be created.
     *
     * @param dst A byte array to copy the ByteBuffer contents to. Can be null.
     * @param src A ByteBuffer to copy data from.
     * @return A byte array containing the contents of the ByteBuffer. If the provided dst was non-null and the correct size,
     * it will be returned. If not, a new byte array will be created.
     */
    private byte[] copyByteBuffer(@Nullable byte[] dst, @NonNull final ByteBuffer src) {
        // Create a new byte array if necessary.
        byte[] out;
        if ((null == dst) || (dst.length != src.capacity())) {
            out = new byte[src.capacity()];
        } else {
            out = dst;
        }

        // Copy the ByteBuffer's contents to the byte array.
        src.get(out);

        return out;
    }

    /**
     * Converts this YUV frame to an ARGB_8888 Bitmap. Applies stored rotation.
     * Remaining code based on http://stackoverflow.com/a/12702836 by rics (http://stackoverflow.com/users/21047/rics)
     *
     * @return A new Bitmap containing the converted frame.
     */
    public Bitmap getBitmap() {
        // Calculate the size of the frame
        final int size = width * height;

        // Allocate an array to hold the ARGB pixel data
        final int[] argb = new int[size];

        if (rotationDegree == 90 || rotationDegree == -270) {
            convertYuvToArgbRot90(argb);

            // Create Bitmap from ARGB pixel data.
            // noinspection SuspiciousNameCombination (Rotating image swaps width/height, name mismatch is fine, Lint.)
            return Bitmap.createBitmap(argb, height, width, Bitmap.Config.ARGB_8888);
        } else if (rotationDegree == 180 || rotationDegree == -180) {
            convertYuvToArgbRot180(argb);

            // Create Bitmap from ARGB pixel data.
            return Bitmap.createBitmap(argb, width, height, Bitmap.Config.ARGB_8888);
        } else if (rotationDegree == 270 || rotationDegree == -90) {
            convertYuvToArgbRot270(argb);

            // Create Bitmap from ARGB pixel data.
            // noinspection SuspiciousNameCombination (Rotating image swaps width/height, name mismatch is fine, Lint.)
            return Bitmap.createBitmap(argb, height, width, Bitmap.Config.ARGB_8888);
        } else {
            convertYuvToArgbRot0(argb);

            // Create Bitmap from ARGB pixel data.
            return Bitmap.createBitmap(argb, width, height, Bitmap.Config.ARGB_8888);
        }
    }

    private void convertYuvToArgbRot0(final int[] outputArgb) {
        synchronized (planeLock) {
            // Calculate the size of the frame
            int size = width * height;

            // Each U/V cell is overlaid on a 2x2 block of Y cells.
            // Loop through the size of the U/V planes, and manage the 2x2 Y block on each iteration.
            int u, v;
            int y1, y2, y3, y4;
            int p1, p2, p3, p4;
            int rowOffset = 0;  // Y and RGB array position is offset by an extra row width each iteration, since they're handled as 2x2 sections.

            final int uvSize = size / 4;   // U/V plane is one quarter the total size of the frame.
            final int uvWidth = width / 2;  // U/V plane width is half the width of the frame.

            for (int i = 0; i < uvSize; i++) {
                // At the end of each row, increment the Y/RGB row offset by an extra frame width
                if (i != 0 && (i % (uvWidth)) == 0) {
                    rowOffset += width;
                }

                // Calculate the 2x2 grid indices
                p1 = rowOffset + (i * 2);
                p2 = p1 + 1;
                p3 = p1 + width;
                p4 = p3 + 1;

                // Get the U and V values from the source.
                u = uPlane[i] & 0xff;
                v = vPlane[i] & 0xff;
                u = u - 128;
                v = v - 128;

                // Get the Y values for the matching 2x2 pixel block
                y1 = yPlane[p1] & 0xff;
                y2 = yPlane[p2] & 0xff;
                y3 = yPlane[p3] & 0xff;
                y4 = yPlane[p4] & 0xff;

                // Convert each YUV pixel to RGB
                outputArgb[p1] = convertYuvToArgb(y1, u, v);
                outputArgb[p2] = convertYuvToArgb(y2, u, v);
                outputArgb[p3] = convertYuvToArgb(y3, u, v);
                outputArgb[p4] = convertYuvToArgb(y4, u, v);
            }
        }
    }

    private void convertYuvToArgbRot90(final int[] outputArgb) {
        synchronized (planeLock) {
            int u, v;
            int y1, y2, y3, y4;
            int p1, p2, p3, p4;
            int d1, d2, d3, d4;
            int uvIndex;

            final int uvWidth = width / 2;  // U/V plane width is half the width of the frame.
            final int uvHeight = height / 2;  // U/V plane height is half the height of the frame.

            int rotCol;
            int rotRow;

            // Each U/V cell is overlaid on a 2x2 block of Y cells.
            // Loop through the size of the U/V planes, and manage the 2x2 Y block on each iteration.
            for (int row = 0; row < uvHeight; row++) {
                // Calculate the column on the rotated image from the row on the source image
                rotCol = (uvHeight - 1) - row;

                for (int col = 0; col < uvWidth; col++) {
                    // Calculate the row on the rotated image from the column on the source image
                    rotRow = col;

                    // Calculate the 2x2 grid indices
                    p1 = (row * width * 2) + (col * 2);
                    p2 = p1 + 1;
                    p3 = p1 + width;
                    p4 = p3 + 1;

                    // Get the U and V values from the source.
                    uvIndex = (row * uvWidth) + col;
                    u = uPlane[uvIndex] & 0xff;
                    v = vPlane[uvIndex] & 0xff;
                    u = u - 128;
                    v = v - 128;

                    // Get the Y values for the matching 2x2 pixel block
                    y1 = yPlane[p1] & 0xff;
                    y2 = yPlane[p2] & 0xff;
                    y3 = yPlane[p3] & 0xff;
                    y4 = yPlane[p4] & 0xff;

                    // Calculate the destination 2x2 grid indices
                    d1 = (rotRow * height * 2) + (rotCol * 2) + 1;
                    d2 = d1 + height;
                    d3 = d1 - 1;
                    d4 = d3 + height;

                    // Convert each YUV pixel to RGB
                    outputArgb[d1] = convertYuvToArgb(y1, u, v);
                    outputArgb[d2] = convertYuvToArgb(y2, u, v);
                    outputArgb[d3] = convertYuvToArgb(y3, u, v);
                    outputArgb[d4] = convertYuvToArgb(y4, u, v);
                }
            }
        }
    }

    private void convertYuvToArgbRot180(final int[] outputArgb) {
        synchronized (planeLock) {
            // Calculate the size of the frame
            int size = width * height;

            // Each U/V cell is overlaid on a 2x2 block of Y cells.
            // Loop through the size of the U/V planes, and manage the 2x2 Y block on each iteration.
            int u, v;
            int y1, y2, y3, y4;
            int p1, p2, p3, p4;
            int rowOffset = 0;  // Y and RGB array position is offset by an extra row width each iteration, since they're handled as 2x2 sections.

            final int uvSize = size / 4;   // U/V plane is one quarter the total size of the frame.
            final int uvWidth = width / 2;  // U/V plane width is half the width of the frame.
            final int invertSize = size - 1;  // Store size - 1 so it doesn't have to be calculated 4x every iteration.

            for (int i = 0; i < uvSize; i++) {
                // At the end of each row, increment the Y/RGB row offset by an extra frame width
                if (i != 0 && (i % (uvWidth)) == 0) {
                    rowOffset += width;
                }

                // Calculate the 2x2 grid indices
                p1 = rowOffset + (i * 2);
                p2 = p1 + 1;
                p3 = p1 + width;
                p4 = p3 + 1;

                // Get the U and V values from the source.
                u = uPlane[i] & 0xff;
                v = vPlane[i] & 0xff;
                u = u - 128;
                v = v - 128;

                // Get the Y values for the matching 2x2 pixel block
                y1 = yPlane[p1] & 0xff;
                y2 = yPlane[p2] & 0xff;
                y3 = yPlane[p3] & 0xff;
                y4 = yPlane[p4] & 0xff;

                // Convert each YUV pixel to RGB
                outputArgb[invertSize - p1] = convertYuvToArgb(y1, u, v);
                outputArgb[invertSize - p2] = convertYuvToArgb(y2, u, v);
                outputArgb[invertSize - p3] = convertYuvToArgb(y3, u, v);
                outputArgb[invertSize - p4] = convertYuvToArgb(y4, u, v);
            }
        }
    }

    private void convertYuvToArgbRot270(final int[] outputArgb) {
        synchronized (planeLock) {
            // Calculate the size of the frame
            int size = width * height;

            int u, v;
            int y1, y2, y3, y4;
            int p1, p2, p3, p4;
            int d1, d2, d3, d4;
            int uvIndex;

            final int uvWidth = width / 2;  // U/V plane width is half the width of the frame.
            final int uvHeight = height / 2;  // U/V plane height is half the height of the frame.
            final int invertSize = size - 1;  // Store size - 1 so it doesn't have to be calculated 4x every iteration.

            int rotCol;
            int rotRow;

            // Each U/V cell is overlaid on a 2x2 block of Y cells.
            // Loop through the size of the U/V planes, and manage the 2x2 Y block on each iteration.
            for (int row = 0; row < uvHeight; row++) {
                // Calculate the column on the rotated image from the row on the source image
                rotCol = (uvHeight - 1) - row;

                for (int col = 0; col < uvWidth; col++) {
                    // Calculate the row on the rotated image from the column on the source image
                    rotRow = col;

                    // Calculate the 2x2 grid indices
                    p1 = (row * width * 2) + (col * 2);
                    p2 = p1 + 1;
                    p3 = p1 + width;
                    p4 = p3 + 1;

                    // Get the U and V values from the source.
                    uvIndex = (row * uvWidth) + col;
                    u = uPlane[uvIndex] & 0xff;
                    v = vPlane[uvIndex] & 0xff;
                    u = u - 128;
                    v = v - 128;

                    // Get the Y values for the matching 2x2 pixel block
                    y1 = yPlane[p1] & 0xff;
                    y2 = yPlane[p2] & 0xff;
                    y3 = yPlane[p3] & 0xff;
                    y4 = yPlane[p4] & 0xff;

                    // Calculate the destination 2x2 grid indices
                    d1 = (rotRow * height * 2) + (rotCol * 2) + 1;
                    d2 = d1 + height;
                    d3 = d1 - 1;
                    d4 = d3 + height;

                    // Convert each YUV pixel to RGB
                    outputArgb[invertSize - d1] = convertYuvToArgb(y1, u, v);
                    outputArgb[invertSize - d2] = convertYuvToArgb(y2, u, v);
                    outputArgb[invertSize - d3] = convertYuvToArgb(y3, u, v);
                    outputArgb[invertSize - d4] = convertYuvToArgb(y4, u, v);
                }
            }
        }
    }

    private int convertYuvToArgb(final int y, final int u, final int v) {
        int r, g, b;

        // Convert YUV to RGB
        r = y + (int) (1.402f * v);
        g = y - (int) (0.344f * u + 0.714f * v);
        b = y + (int) (1.772f * u);

        // Clamp RGB values to [0,255]
        r = (r > 255) ? 255 : Math.max(r, 0);
        g = (g > 255) ? 255 : Math.max(g, 0);
        b = (b > 255) ? 255 : Math.max(b, 0);

        // Shift the RGB values into position in the final ARGB pixel
        return 0xff000000 | (b << 16) | (g << 8) | r;
    }
}
