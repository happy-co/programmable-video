package twilio.flutter.twilio_programmable_video

import android.content.Context
import android.hardware.Camera
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import com.twilio.video.Camera2Capturer
import com.twilio.video.CameraCapturer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.Exception
import tvi.webrtc.Camera2Enumerator
import tvi.webrtc.VideoCapturer

class VideoCapturerHandler {
    companion object {
        private val TAG = "VideoCapturerHandler"

        @JvmStatic
        fun initializeCapturer(videoCapturerMap: Map<*, *>, result: MethodChannel.Result) {
            if (TwilioProgrammableVideoPlugin.camera2IsSupported) {
                initializeCamera2Capturer(videoCapturerMap, result)
            } else {
                initializeCameraCapturer(videoCapturerMap, result)
            }
        }

        @JvmStatic
        fun setTorch(call: MethodCall, result: MethodChannel.Result) {
            debug("setTorch => called")
            val enableTorch = call.argument<Boolean>("enable")
                    ?: return result.error("MISSING_PARAMS", "The parameter 'enable' was not given", null)

            return if (hasTorch()) {
                when (TwilioProgrammableVideoPlugin.cameraCapturer) {
                    null -> result.error("FAILED", "Could not setTorch to enabled: $enableTorch, cameraCapturer is not defined", null)
                    is Camera2Capturer -> setTorchCamera2Capturer(enableTorch, result)
                    is CameraCapturer -> setTorchCameraCapturer(enableTorch, result)
                    else -> result.error("FAILED", "Method `setTorch` not supported for ${TwilioProgrammableVideoPlugin.cameraCapturer?.javaClass}", null)
                }
            } else {
                result.error("FAILED", "Current camera does not have a flash", null)
            }
        }

        private fun initializeCameraCapturer(videoCapturerMap: Map<*, *>, result: MethodChannel.Result) {
            val listener = object : CameraCapturer.Listener {
                override fun onError(errorCode: Int) {
                    TwilioProgrammableVideoPlugin.handler.post {
                        debug("CameraCapturer.onError => code: $errorCode")
                        TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("cameraError", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer!!)), Exception(errorCode.toString()))
                    }
                }

                override fun onFirstFrameAvailable() {
                    TwilioProgrammableVideoPlugin.handler.post {
                        debug("CameraCapturer.onFirstFrameAvailable")
                        TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("firstFrameAvailable", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer!!)), null)
                    }
                }

                override fun onCameraSwitched(newCameraId: String) {
                    TwilioProgrammableVideoPlugin.handler.post {
                        debug("CameraCapturer.onCameraSwitched => newCameraId: $newCameraId")
                        TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("cameraSwitched", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer!!, newCameraId)), null)
                    }
                }
            }

            val source = videoCapturerMap["source"] as Map<String, Any?>
            val cameraId = source["cameraId"] as String?

            // Check type because we may want to add support for ScreenCapturer
            val videoCapturer: VideoCapturer = if (TwilioProgrammableVideoPlugin.cameraEnumerator.deviceNames.contains(cameraId))
                CameraCapturer(TwilioProgrammableVideoPlugin.pluginHandler.applicationContext, cameraId!!, listener)
            else
                return result.error("MISSING_CAMERA", "No camera found for $cameraId.", null)

            if (videoCapturer is CameraCapturer) {
                TwilioProgrammableVideoPlugin.cameraCapturer = videoCapturer
            }
        }

        @JvmStatic
        private fun initializeCamera2Capturer(videoCapturerMap: Map<*, *>, result: MethodChannel.Result) {
            val source = videoCapturerMap["source"] as Map<String, Any?>
            val cameraId = source["cameraId"] as String?
            if (!TwilioProgrammableVideoPlugin.cameraEnumerator.deviceNames.contains(cameraId))
                return result.error("MISSING_CAMERA", "No camera found for $cameraId.", null)

            // Check type because we may want to add support for ScreenCapturer
            val videoCapturer: VideoCapturer = Camera2Capturer(
                    TwilioProgrammableVideoPlugin.pluginHandler.applicationContext,
                    normalizeCameraId(cameraId!!),
                    object : Camera2Capturer.Listener {
                        override fun onError(camera2CapturerException: Camera2Capturer.Exception) {
                            debug("Camera2Capturer.onError => $camera2CapturerException")
                            TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("cameraError", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer!!)), camera2CapturerException)
                        }

                        override fun onFirstFrameAvailable() {
                            debug("Camera2Capturer.onFirstFrameAvailable")
                            TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("firstFrameAvailable", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer!!)), null)
                        }

                        override fun onCameraSwitched(newCameraId: String) {
                            debug("Camera2Capturer.onCameraSwitched => newCameraId: $newCameraId")
                            TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("cameraSwitched", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer!!)), null)
                        }
                    }
            )
            if (videoCapturer is Camera2Capturer) {
                TwilioProgrammableVideoPlugin.cameraCapturer = videoCapturer
            }
        }

        private fun getCameraManager(): CameraManager {
            return TwilioProgrammableVideoPlugin.pluginHandler.applicationContext.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        }

        private fun hasTorchCameraCapturer(): Boolean {
            debug("hasTorchCameraCapturer")
            if (TwilioProgrammableVideoPlugin.cameraCapturer == null || TwilioProgrammableVideoPlugin.cameraCapturer !is CameraCapturer) return false
            val cameraManager: CameraManager = getCameraManager()
            val capturer = TwilioProgrammableVideoPlugin.cameraCapturer as CameraCapturer
            return cameraManager.getCameraCharacteristics(normalizeCameraId(capturer.cameraId))[CameraCharacteristics.FLASH_INFO_AVAILABLE]
                    ?: false
        }

        private fun hasTorchCamera2Capturer(): Boolean {
            debug("hasTorchCamera2Capturer")
            if (TwilioProgrammableVideoPlugin.cameraCapturer == null || TwilioProgrammableVideoPlugin.cameraCapturer !is Camera2Capturer) return false
            val cameraManager: CameraManager = getCameraManager()
            val capturer = TwilioProgrammableVideoPlugin.cameraCapturer as Camera2Capturer
            return cameraManager.getCameraCharacteristics(normalizeCameraId(capturer.cameraId))[CameraCharacteristics.FLASH_INFO_AVAILABLE]
                    ?: false
        }

        private fun hasTorch(): Boolean {
            return when (TwilioProgrammableVideoPlugin.cameraCapturer) {
                null -> false
                is Camera2Capturer -> hasTorchCamera2Capturer()
                is CameraCapturer -> hasTorchCameraCapturer()
                else -> false
            }
        }

        private fun setTorchCameraCapturer(enableTorch: Boolean, result: MethodChannel.Result) {
            val capturer = TwilioProgrammableVideoPlugin.cameraCapturer as CameraCapturer
            val scheduled = capturer.updateCameraParameters {
                val newFlashMode = if (enableTorch) Camera.Parameters.FLASH_MODE_TORCH else Camera.Parameters.FLASH_MODE_OFF
                if (it.flashMode != null) {
                    it.flashMode = newFlashMode
                }
            }

            return if (scheduled) {
                result.success(null)
            } else {
                result.error("FAILED", "Failed to schedule updateCaptureRequest", null)
            }
        }

        private fun setTorchCamera2Capturer(enableTorch: Boolean, result: MethodChannel.Result) {
            val capturer = TwilioProgrammableVideoPlugin.cameraCapturer as Camera2Capturer
            val scheduled = capturer.updateCaptureRequest {
                val flashMode: Int = if (enableTorch) {
                    CaptureRequest.FLASH_MODE_TORCH
                } else {
                    CaptureRequest.FLASH_MODE_OFF
                }

                it.set(CaptureRequest.FLASH_MODE, flashMode)
            }

            return if (scheduled) {
                result.success(null)
            } else {
                result.error("FAILED", "Failed to schedule updateCaptureRequest", null)
            }
        }

        @JvmStatic
        fun cameraIdToMap(cameraId: String): Map<String, Any> {
            val cameraManager: CameraManager = getCameraManager()
            val hasTorch = cameraManager.getCameraCharacteristics(normalizeCameraId(cameraId))[CameraCharacteristics.FLASH_INFO_AVAILABLE]
                    ?: false

            return mapOf(
                    "isFrontFacing" to TwilioProgrammableVideoPlugin.cameraEnumerator.isFrontFacing(cameraId),
                    "isBackFacing" to TwilioProgrammableVideoPlugin.cameraEnumerator.isBackFacing(cameraId),
                    "hasTorch" to hasTorch,
                    "cameraId" to cameraId
            )
        }

        @JvmStatic
        fun normalizeCameraId(cameraId: String): String {
            return when (TwilioProgrammableVideoPlugin.cameraEnumerator is Camera2Enumerator) {
                true -> cameraId
                false -> {
                    val match = Regex("""Camera (\d+)""").find(cameraId)
                    val groupValues = match?.groupValues
                    groupValues?.getOrNull(1)
                }
            } ?: cameraId
        }

        fun videoCapturerToMap(videoCapturer: VideoCapturer, cameraId: String? = null): Map<String, Any> {
            if (videoCapturer is Camera2Capturer) {
                var id = videoCapturer.cameraId
                if (cameraId != null) {
                    id = cameraId.toString()
                }
                return mapOf(
                        "type" to "CameraCapturer",
                        "source" to cameraIdToMap(id)
                )
            } else if (videoCapturer is CameraCapturer) {
                var id = videoCapturer.cameraId
                if (cameraId != null) {
                    id = cameraId
                }
                return mapOf(
                        "type" to "CameraCapturer",
                        "source" to cameraIdToMap(id)
                )
            }
            return mapOf(
                    "type" to "Unknown",
                    "isScreencast" to videoCapturer.isScreencast
            )
        }

        internal fun debug(msg: String) {
            TwilioProgrammableVideoPlugin.debug("$TAG::$msg")
        }
    }
}
