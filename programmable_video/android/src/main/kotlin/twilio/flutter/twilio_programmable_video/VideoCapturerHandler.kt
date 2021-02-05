package twilio.flutter.twilio_programmable_video

import android.content.Context
import android.hardware.Camera
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.hardware.camera2.CaptureRequest
import com.twilio.video.Camera2Capturer
import com.twilio.video.CameraCapturer
import com.twilio.video.VideoCapturer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VideoCapturerHandler {
    companion object {
        @JvmStatic
        fun initializeCapturer(videoCapturerMap: Map<*, *>, result: MethodChannel.Result) {
            if (Camera2Capturer.isSupported(TwilioProgrammableVideoPlugin.pluginHandler.applicationContext)) {
                initializeCamera2Capturer(videoCapturerMap, result)
            } else {
                initializeCameraCapturer(videoCapturerMap, result)
            }
        }

        @JvmStatic
        fun switchCamera(call: MethodCall, result: MethodChannel.Result) {
            if (TwilioProgrammableVideoPlugin.cameraCapturer != null && TwilioProgrammableVideoPlugin.cameraCapturer is Camera2Capturer) {
                return switchCamera2Capturer(call, result)
            } else if (TwilioProgrammableVideoPlugin.cameraCapturer != null && TwilioProgrammableVideoPlugin.cameraCapturer is CameraCapturer) {
                return switchCameraCapturer(call, result)
            }
            return result.error("NOT_FOUND", "No CameraCapturer has been initialized yet, try connecting first.", null)
        }

        @JvmStatic
        fun hasTorch(result: MethodChannel.Result) {
            var hasTorch = hasTorch()
            TwilioProgrammableVideoPlugin.debug("VideoCapturerHandler::hasTorch => check: $hasTorch")

            result.success(hasTorch)
        }

        @JvmStatic
        fun setTorch(call: MethodCall, result: MethodChannel.Result) {
            TwilioProgrammableVideoPlugin.debug("VideoCapturerHandler.setTorch => called")
            val enableTorch = call.argument<Boolean>("enable")
                ?: return result.error("MISSING_PARAMS", "The parameter 'enable' was not given", null)

            if (hasTorch() == true) {
                if (TwilioProgrammableVideoPlugin.cameraCapturer == null) return result.error("FAILED", "Could not setTorch to enabled: $enableTorch, cameraCapturer is not defined", null)
                else if (TwilioProgrammableVideoPlugin.cameraCapturer is Camera2Capturer) return setTorchCamera2Capturer(enableTorch, result)
                else if (TwilioProgrammableVideoPlugin.cameraCapturer is CameraCapturer) return setTorchCameraCapturer(enableTorch, result)
                else return result.error("FAILED", "Method `setTorch` not supported for ${TwilioProgrammableVideoPlugin.cameraCapturer.javaClass}", null)
            } else {
                return result.error("FAILED", "Current camera does not have a flash", null)
            }
        }

        private fun initializeCameraCapturer(videoCapturerMap: Map<*, *>, result: MethodChannel.Result) {
            val listener = object : CameraCapturer.Listener {
                override fun onError(errorCode: Int) {
                    TwilioProgrammableVideoPlugin.handler.post {
                        TwilioProgrammableVideoPlugin.debug("CameraCapturer.onError => code: $errorCode")
                        TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("cameraError", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer)), null)
                    }
                }

                override fun onFirstFrameAvailable() {
                    TwilioProgrammableVideoPlugin.handler.post {
                        TwilioProgrammableVideoPlugin.debug("CameraCapturer.onFirstFrameAvailable")
                        TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("firstFrameAvailable", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer)), null)
                    }
                }

                override fun onCameraSwitched() {
                    TwilioProgrammableVideoPlugin.handler.post {
                        val cameraSource = (TwilioProgrammableVideoPlugin.cameraCapturer as CameraCapturer).cameraSource
                        TwilioProgrammableVideoPlugin.debug("CameraCapturer.onCameraSwitched => newCameraSource: $cameraSource")
                        TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("cameraSwitched", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer)), null)
                    }
                }
            }
            val videoCapturer: VideoCapturer = when (videoCapturerMap["cameraSource"] as String) {
                "BACK_CAMERA" -> CameraCapturer(TwilioProgrammableVideoPlugin.pluginHandler.applicationContext, CameraCapturer.CameraSource.BACK_CAMERA, listener)
                else -> CameraCapturer(TwilioProgrammableVideoPlugin.pluginHandler.applicationContext, CameraCapturer.CameraSource.FRONT_CAMERA, listener)
            }

            if (videoCapturer is CameraCapturer) {
                TwilioProgrammableVideoPlugin.cameraCapturer = videoCapturer
            }
        }

        @JvmStatic
        private fun initializeCamera2Capturer(videoCapturerMap: Map<*, *>, result: MethodChannel.Result) {
            // Check type because we may want to add support for ScreenCapturer
            val cameraId = when (videoCapturerMap["cameraSource"] as String) {
                "BACK_CAMERA" -> getCameraId(CameraMetadata.LENS_FACING_BACK)
                else -> getCameraId(CameraMetadata.LENS_FACING_FRONT)
            } ?: return result.error("MISSING_CAMERA", "No camera found for ${videoCapturerMap["cameraSource"]}.", null)

            val videoCapturer: VideoCapturer = Camera2Capturer(
                    TwilioProgrammableVideoPlugin.pluginHandler.applicationContext,
                    cameraId,
                    object : Camera2Capturer.Listener {
                        override fun onError(camera2CapturerException: Camera2Capturer.Exception) {
                            TwilioProgrammableVideoPlugin.debug("Camera2Capturer.onError => $camera2CapturerException")
                            TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("cameraError", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer)), camera2CapturerException)
                        }

                        override fun onFirstFrameAvailable() {
                            TwilioProgrammableVideoPlugin.debug("Camera2Capturer.onFirstFrameAvailable")
                            TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("firstFrameAvailable", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer)), null)
                        }

                        override fun onCameraSwitched(newCameraId: String) {
                            TwilioProgrammableVideoPlugin.debug("Camera2Capturer.onCameraSwitched => newCameraId: $newCameraId")
                            TwilioProgrammableVideoPlugin.pluginHandler.sendCameraEvent("cameraSwitched", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer)), null)
                        }
                    }
            )
            if (videoCapturer is Camera2Capturer) {
                TwilioProgrammableVideoPlugin.cameraCapturer = videoCapturer
            }
        }

        private fun switchCameraCapturer(call: MethodCall, result: MethodChannel.Result) {
            val capturer = TwilioProgrammableVideoPlugin.cameraCapturer as CameraCapturer
            val source = if (capturer.cameraSource == CameraCapturer.CameraSource.FRONT_CAMERA) {
                CameraCapturer.CameraSource.BACK_CAMERA
            } else {
                CameraCapturer.CameraSource.FRONT_CAMERA
            }
            capturer.switchCamera()

            return result.success(videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer, source))
        }

        private fun switchCamera2Capturer(call: MethodCall, result: MethodChannel.Result) {
            val newCameraId: String?
            val newCameraSource: CameraCapturer.CameraSource
            val capturer = TwilioProgrammableVideoPlugin.cameraCapturer as Camera2Capturer
            if (getCameraDirection(capturer.cameraId) == CameraMetadata.LENS_FACING_FRONT) {
                newCameraId = getCameraId(CameraMetadata.LENS_FACING_BACK)
                newCameraSource = CameraCapturer.CameraSource.BACK_CAMERA
            } else {
                newCameraId = getCameraId(CameraMetadata.LENS_FACING_FRONT)
                newCameraSource = CameraCapturer.CameraSource.FRONT_CAMERA
            }

            if (newCameraId != null) {
                capturer.switchCamera(newCameraId)
                return result.success(videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer, newCameraSource))
            } else {
                return result.error("MISSING_CAMERA", "Could not find another camera to switch to", null)
            }
        }

        private fun getCameraManager(): CameraManager {
            return TwilioProgrammableVideoPlugin.pluginHandler.applicationContext.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        }

        private fun getCameraId(cameraDirection: Int): String? {
            val cameraManager: CameraManager = getCameraManager()
            return cameraManager.cameraIdList.firstOrNull { cameraId -> cameraManager.getCameraCharacteristics(cameraId)[CameraCharacteristics.LENS_FACING] == cameraDirection }
        }

        private fun getCameraDirection(cameraId: String): Int? {
            if (TwilioProgrammableVideoPlugin.cameraCapturer == null) return null
            val cameraManager: CameraManager = getCameraManager()
            return cameraManager.getCameraCharacteristics(cameraId)[CameraCharacteristics.LENS_FACING]
        }

        private fun getCameraDirectionAsString(direction: Int?): String {
            when (direction) {
                CameraMetadata.LENS_FACING_FRONT -> return "FRONT_CAMERA"
                CameraMetadata.LENS_FACING_BACK -> return "BACK_CAMERA"
                else -> return "UNKNOWN"
            }
        }

        private fun cameraIdCorrespondsToActiveCamera(capturer: CameraCapturer, id: String): Boolean {
            var cameraInfo = Camera.CameraInfo()
            Camera.getCameraInfo(id.toInt(), cameraInfo)
            return if (capturer?.cameraSource == null)
                false
            else if (capturer.cameraSource == CameraCapturer.CameraSource.FRONT_CAMERA)
                cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_FRONT
            else
                cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_BACK
        }

        private fun hasTorchCameraCapturer(): Boolean {
            TwilioProgrammableVideoPlugin.debug("VideoCapturerHandler::hasTorchCameraCapturer")
            if (TwilioProgrammableVideoPlugin.cameraCapturer == null || TwilioProgrammableVideoPlugin.cameraCapturer !is CameraCapturer) return false
            val cameraManager: CameraManager = getCameraManager()
            val capturer = TwilioProgrammableVideoPlugin.cameraCapturer as CameraCapturer
            val ids = cameraManager.cameraIdList
            val activeCameraId = ids.firstOrNull {
                cameraIdCorrespondsToActiveCamera(capturer, it)
            } ?: return false
            return cameraManager.getCameraCharacteristics(activeCameraId)[CameraCharacteristics.FLASH_INFO_AVAILABLE]
        }

        private fun hasTorchCamera2Capturer(): Boolean {
            TwilioProgrammableVideoPlugin.debug("VideoCapturerHandler::hasTorchCamera2Capturer")
            if (TwilioProgrammableVideoPlugin.cameraCapturer == null || TwilioProgrammableVideoPlugin.cameraCapturer !is Camera2Capturer) return false
            val cameraManager: CameraManager = getCameraManager()
            val capturer = TwilioProgrammableVideoPlugin.cameraCapturer as Camera2Capturer
            return cameraManager.getCameraCharacteristics(capturer.cameraId)[CameraCharacteristics.FLASH_INFO_AVAILABLE]
        }

        private fun hasTorch(): Boolean {
            if (TwilioProgrammableVideoPlugin.cameraCapturer == null) return false
            else if (TwilioProgrammableVideoPlugin.cameraCapturer is Camera2Capturer) return hasTorchCamera2Capturer()
            else if (TwilioProgrammableVideoPlugin.cameraCapturer is CameraCapturer) return hasTorchCameraCapturer()
            else return false
        }

        private fun setTorchCameraCapturer(enableTorch: Boolean, result: MethodChannel.Result) {
            val capturer = TwilioProgrammableVideoPlugin.cameraCapturer as CameraCapturer
            val scheduled = capturer.updateCameraParameters {
                val newFlashMode = if (enableTorch) Camera.Parameters.FLASH_MODE_TORCH else Camera.Parameters.FLASH_MODE_OFF
                if (it.flashMode != null) {
                    it.flashMode = newFlashMode
                }
            }

            if (scheduled) {
                return result.success(null)
            } else {
                return result.error("FAILED", "Failed to schedule updateCaptureRequest", null)
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

            if (scheduled) {
                return result.success(null)
            } else {
                return result.error("FAILED", "Failed to schedule updateCaptureRequest", null)
            }
        }

        fun videoCapturerToMap(videoCapturer: VideoCapturer, cameraSource: CameraCapturer.CameraSource? = null): Map<String, Any> {
            if (videoCapturer is Camera2Capturer) {
                var source = getCameraDirectionAsString(getCameraDirection(videoCapturer.cameraId))
                if (cameraSource != null) {
                    source = cameraSource.toString()
                }
                return mapOf(
                        "type" to "CameraCapturer",
                        "cameraSource" to source
                )
            } else if (videoCapturer is CameraCapturer) {
                var source = videoCapturer.cameraSource.toString()
                if (cameraSource != null) {
                    source = cameraSource.toString()
                }
                return mapOf(
                        "type" to "CameraCapturer",
                        "cameraSource" to source
                )
            }
            return mapOf(
                    "type" to "Unknown",
                    "isScreencast" to videoCapturer.isScreencast
            )
        }
    }
}
