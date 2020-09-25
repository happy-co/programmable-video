package twilio.flutter.twilio_programmable_video

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.hardware.camera2.CaptureRequest
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import androidx.annotation.NonNull
import com.twilio.video.AudioCodec
import com.twilio.video.Camera2Capturer
import com.twilio.video.Camera2Capturer.Listener
import com.twilio.video.CameraCapturer
import com.twilio.video.ConnectOptions
import com.twilio.video.DataTrackOptions
import com.twilio.video.G722Codec
import com.twilio.video.H264Codec
import com.twilio.video.IsacCodec
import com.twilio.video.LocalAudioTrack
import com.twilio.video.LocalDataTrack
import com.twilio.video.LocalParticipant
import com.twilio.video.LocalVideoTrack
import com.twilio.video.OpusCodec
import com.twilio.video.PcmaCodec
import com.twilio.video.PcmuCodec
import com.twilio.video.RemoteParticipant
import com.twilio.video.VideoCapturer
import com.twilio.video.VideoCodec
import com.twilio.video.Vp8Codec
import com.twilio.video.Vp9Codec
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.nio.ByteBuffer
import tvi.webrtc.voiceengine.WebRtcAudioUtils

class PluginHandler : MethodCallHandler, ActivityAware, BaseListener {
    private var previousAudioMode: Int = 0

    private var previousMicrophoneMute: Boolean = false

    private var audioFocusRequest: AudioFocusRequest? = null

    private var previousVolumeControlStream: Int = 0

    private var activity: Activity? = null

    private var applicationContext: Context

    private var myNoisyAudioStreamReceiver: BecomingNoisyReceiver? = null

    private var audioManager: AudioManager

    @Suppress("ConvertSecondaryConstructorToPrimary")
    constructor(applicationContext: Context) {
        this.applicationContext = applicationContext
        audioManager = applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        this.activity = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
    }

    private val remoteParticipants: List<RemoteParticipant>?
        get() {
            return TwilioProgrammableVideoPlugin.roomListener.room?.remoteParticipants?.toList()
        }

    fun getRemoteParticipant(sid: String?): RemoteParticipant? {
        return remoteParticipants?.first { it.sid == sid }
    }

    fun getLocalParticipant(): LocalParticipant? {
        return TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.debug("PluginHandler.onMethodCall => received ${call.method}")
        when (call.method) {
            "debug" -> debug(call, result)
            "connect" -> connect(call, result)
            "disconnect" -> disconnect(call, result)
            "setSpeakerphoneOn" -> setSpeakerphoneOn(call, result)
            "getSpeakerphoneOn" -> getSpeakerphoneOn(result)
            "LocalAudioTrack#enable" -> localAudioTrackEnable(call, result)
            "LocalDataTrack#sendString" -> localDataTrackSendString(call, result)
            "LocalDataTrack#sendByteBuffer" -> localDataTrackSendByteBuffer(call, result)
            "LocalVideoTrack#enable" -> localVideoTrackEnable(call, result)
            "CameraCapturer#switchCamera" -> switchCamera(call, result)
            "CameraCapturer#hasTorch" -> hasTorch(result)
            "CameraCapturer#setTorch" -> setTorch(call, result)
            else -> result.notImplemented()
        }
    }

    private fun switchCamera(call: MethodCall, result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.debug("PluginHandler.switchCamera => called")
        if (TwilioProgrammableVideoPlugin.cameraCapturer != null) {
            val newCameraId: String?
            val newCameraSource: CameraCapturer.CameraSource
            if (getCameraDirection(TwilioProgrammableVideoPlugin.cameraCapturer.cameraId) == CameraMetadata.LENS_FACING_FRONT) {
                newCameraId = getCameraId(CameraMetadata.LENS_FACING_BACK)
                newCameraSource = CameraCapturer.CameraSource.BACK_CAMERA
            } else {
                newCameraId = getCameraId(CameraMetadata.LENS_FACING_FRONT)
                newCameraSource = CameraCapturer.CameraSource.FRONT_CAMERA
            }

            if (newCameraId != null) {
                TwilioProgrammableVideoPlugin.cameraCapturer.switchCamera(newCameraId)
                return result.success(videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer, newCameraSource))
            } else {
                return result.error("MISSING_CAMERA", "Could not find another camera to switch to", null)
            }
        }
        return result.error("NOT_FOUND", "No CameraCapturer has been initialized yet, try connecting first.", null)
    }

    private fun hasTorch(): Boolean {
        if (TwilioProgrammableVideoPlugin.cameraCapturer == null) return false
        val cameraManager: CameraManager = getCameraManager()
        return cameraManager.getCameraCharacteristics(TwilioProgrammableVideoPlugin.cameraCapturer.cameraId)[CameraCharacteristics.FLASH_INFO_AVAILABLE]
    }

    private fun hasTorch(result: MethodChannel.Result) {
        result.success(hasTorch())
    }

    private fun setTorch(call: MethodCall, result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.debug("PluginHandler.setTorch => called")
        val enableTorch = call.argument<Boolean>("enable")
            ?: return result.error("MISSING_PARAMS", "The parameter 'enable' was not given", null)

        if (hasTorch()) {
            val scheduled = TwilioProgrammableVideoPlugin.cameraCapturer.updateCaptureRequest {
                val flashMode: Int = if (enableTorch) {
                    CaptureRequest.FLASH_MODE_TORCH
                } else {
                    CaptureRequest.FLASH_MODE_OFF
                }

                it.set(CaptureRequest.FLASH_MODE, flashMode)
            }
            TwilioProgrammableVideoPlugin.debug("PluginHandler.setTorch => scheduled: $scheduled flashState: ")
            if (scheduled) {
                return result.success(null)
            } else {
                return result.error("FAILED", "Failed to schedule updateCaptureRequest", null)
            }
        } else {
            return result.error("FAILED", "Current camera does not have a flash", null)
        }
    }

    private fun localVideoTrackEnable(call: MethodCall, result: MethodChannel.Result) {
        val localVideoTrackName = call.argument<String>("name")
            ?: return result.error("MISSING_PARAMS", "The parameter 'name' was not given", null)
        val localVideoTrackEnable = call.argument<Boolean>("enable")
            ?: return result.error("MISSING_PARAMS", "The parameter 'enable' was not given", null)

        TwilioProgrammableVideoPlugin.debug("PluginHandler.localVideoTrackEnable => called for $localVideoTrackName, enable=$localVideoTrackEnable")

        val localVideoTrack = getLocalParticipant()?.localVideoTracks?.firstOrNull { it.trackName == localVideoTrackName }
        if (localVideoTrack != null) {
            localVideoTrack.localVideoTrack.enable(localVideoTrackEnable)
            return result.success(null)
        }
        return result.error("NOT_FOUND", "No LocalVideoTrack found with the name '$localVideoTrackName'", null)
    }

    private fun localAudioTrackEnable(call: MethodCall, result: MethodChannel.Result) {
        val localAudioTrackName = call.argument<String>("name")
            ?: return result.error("MISSING_PARAMS", "The parameter 'name' was not given", null)
        val localAudioTrackEnable = call.argument<Boolean>("enable")
            ?: return result.error("MISSING_PARAMS", "The parameter 'enable' was not given", null)

        TwilioProgrammableVideoPlugin.debug("PluginHandler.localAudioTrackEnable => called for $localAudioTrackName, enable=$localAudioTrackEnable")

        val localAudioTrack = TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localAudioTracks?.firstOrNull { it.trackName == localAudioTrackName }
        if (localAudioTrack != null) {
            localAudioTrack.localAudioTrack.enable(localAudioTrackEnable)
            return result.success(null)
        }
        return result.error("NOT_FOUND", "No LocalAudioTrack found with the name '$localAudioTrackName'", null)
    }

    private fun localDataTrackSendString(call: MethodCall, result: MethodChannel.Result) {
        val localDataTrackName = call.argument<String>("name")
            ?: return result.error("MISSING_PARAMS", "The parameter 'name' was not given", null)
        val localDataTrackMessage = call.argument<String>("message")
            ?: return result.error("MISSING_PARAMS", "The parameter 'message' was not given", null)

        TwilioProgrammableVideoPlugin.debug("PluginHandler.localDataTrackSendString => called for $localDataTrackName")

        val localDataTrack = TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localDataTracks?.firstOrNull { it.trackName == localDataTrackName }
            ?: return result.error("NOT_FOUND", "No LocalDataTrack found with the name '$localDataTrackName'", null)

        localDataTrack.localDataTrack.send(localDataTrackMessage)
        return result.success(null)
    }

    private fun localDataTrackSendByteBuffer(call: MethodCall, result: MethodChannel.Result) {
        val localDataTrackName = call.argument<String>("name")
            ?: return result.error("MISSING_PARAMS", "The parameter 'name' was not given", null)
        val localDataTrackMessage = call.argument<ByteArray>("message")
            ?: return result.error("MISSING_PARAMS", "The parameter 'message' was not given", null)

        TwilioProgrammableVideoPlugin.debug("PluginHandler.localDataTrackSendByteBuffer => called for $localDataTrackName")

        val localDataTrack = TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localDataTracks?.firstOrNull { it.trackName == localDataTrackName }
            ?: return result.error("NOT_FOUND", "No LocalDataTrack found with the name '$localDataTrackName'", null)

        localDataTrack.localDataTrack.send(ByteBuffer.wrap(localDataTrackMessage))
        return result.success(null)
    }

    private fun setSpeakerphoneOn(call: MethodCall, result: MethodChannel.Result) {
        val on = call.argument<Boolean>("on")
            ?: return result.error("MISSING_PARAMS", "The parameter 'on' was not given", null)

        audioManager.isSpeakerphoneOn = on
        return result.success(on)
    }

    private fun getSpeakerphoneOn(result: MethodChannel.Result) {
        return result.success(audioManager.isSpeakerphoneOn())
    }

    private fun disconnect(call: MethodCall, result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.debug("PluginHandler.disconnect => called")
        TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localVideoTracks?.forEach { it.localVideoTrack.release() }
        TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localAudioTracks?.forEach { it.localAudioTrack.release() }
        TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localDataTracks?.forEach { it.localDataTrack.release() }
        TwilioProgrammableVideoPlugin.roomListener.room?.disconnect()
        setAudioFocus(false)
        result.success(true)
    }

    private fun connect(call: MethodCall, result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => called, Build.MODEL: '${Build.MODEL}'")
        if (TwilioProgrammableVideoPlugin.HARDWARE_AEC_BLACKLIST.contains(Build.MODEL) && !WebRtcAudioUtils.useWebRtcBasedAcousticEchoCanceler()) {
            TwilioProgrammableVideoPlugin.debug("WebRtcAudioUtils.setWebRtcBasedAcousticEchoCanceler => true")
            WebRtcAudioUtils.setWebRtcBasedAcousticEchoCanceler(true)
        }
        val optionsObj = call.argument<Map<String, Any>>("connectOptions")
            ?: return result.error("MISSING_PARAMS", "Missing 'connectOptions' parameter", null)

        setAudioFocus(true)

        try {
            val optionsBuilder = ConnectOptions.Builder(optionsObj["accessToken"] as String)

            // Set the room name if it has been passed.
            if (optionsObj["roomName"] != null) {
                TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting roomName to '${optionsObj["roomName"]}'")
                optionsBuilder.roomName(optionsObj["roomName"] as String)
            }

            // Set the region if it has been passed.
            if (optionsObj["region"] != null) {
                TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting region to '${optionsObj["region"]}'")
                optionsBuilder.region(optionsObj["region"] as String)
            }

            // Set the preferred audio codecs if it has been passed.
            if (optionsObj["preferredAudioCodecs"] != null) {
                val preferredAudioCodecs = optionsObj["preferredAudioCodecs"] as Map<*, *>

                val audioCodecs = ArrayList<AudioCodec>()
                for ((audioCodec) in preferredAudioCodecs) {
                    when (audioCodec) {
                        IsacCodec.NAME -> audioCodecs.add(IsacCodec())
                        OpusCodec.NAME -> audioCodecs.add(OpusCodec())
                        PcmaCodec.NAME -> audioCodecs.add(PcmaCodec())
                        PcmuCodec.NAME -> audioCodecs.add(PcmuCodec())
                        G722Codec.NAME -> audioCodecs.add(G722Codec())
                        else -> audioCodecs.add(OpusCodec())
                    }
                }
                TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting audioCodecs to '${audioCodecs.joinToString(", ")}'")
                optionsBuilder.preferAudioCodecs(audioCodecs)
            }

            // Set the preferred video codecs if it has been passed.
            if (optionsObj["preferredVideoCodecs"] != null) {
                val preferredVideoCodecs = optionsObj["preferredVideoCodecs"] as Map<*, *>

                val videoCodecs = ArrayList<VideoCodec>()
                for ((videoCodec) in preferredVideoCodecs) {
                    when (videoCodec) {
                        Vp8Codec.NAME -> videoCodecs.add(Vp8Codec()) // TODO(WLFN): It has an optional parameter, need to figure out for what: https://github.com/twilio/video-quickstart-android/blob/master/quickstartKotlin/src/main/java/com/twilio/video/quickstart/kotlin/VideoActivity.kt#L106
                        Vp9Codec.NAME -> videoCodecs.add(Vp9Codec())
                        H264Codec.NAME -> videoCodecs.add(H264Codec())
                        else -> videoCodecs.add(Vp8Codec())
                    }
                }
                TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting videoCodecs to '${videoCodecs.joinToString(", ")}'")
                optionsBuilder.preferVideoCodecs(videoCodecs)
            }

            // Set the local audio tracks if it has been passed.
            if (optionsObj["audioTracks"] != null) {
                val audioTrackOptions = optionsObj["audioTracks"] as Map<*, *>

                val audioTracks = ArrayList<LocalAudioTrack?>()
                for ((audioTrack) in audioTrackOptions) {
                    audioTrack as Map<*, *> // Ensure right type.
                    audioTracks.add(LocalAudioTrack.create(this.applicationContext, audioTrack["enable"] as Boolean, audioTrack["name"] as String))
                }
                TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting audioTracks to '${audioTracks.joinToString(", ")}'")
                optionsBuilder.audioTracks(audioTracks)
            }

            // Set the local data tracks if it has been passed.
            if (optionsObj["dataTracks"] != null) {
                val dataTrackMap = optionsObj["dataTracks"] as Map<*, *>

                val dataTracks = ArrayList<LocalDataTrack?>()
                for ((dataTrack) in dataTrackMap) {
                    dataTrack as Map<*, *> // Ensure right type.
                    if (dataTrack["dataTrackOptions"] != null) {
                        val dataTrackOptionsMap = dataTrack["dataTrackOptions"] as Map<*, *>

                        val dataTrackOptionsBuilder = DataTrackOptions.Builder()
                        if (dataTrackOptionsMap["ordered"] != null) {
                            dataTrackOptionsBuilder.ordered(dataTrackOptionsMap["ordered"] as Boolean)
                        }
                        if (dataTrackOptionsMap["maxPacketLifeTime"] != null) {
                            dataTrackOptionsBuilder.maxPacketLifeTime(dataTrackOptionsMap["maxPacketLifeTime"] as Int)
                        }
                        if (dataTrackOptionsMap["maxRetransmits"] != null) {
                            dataTrackOptionsBuilder.maxRetransmits(dataTrackOptionsMap["maxRetransmits"] as Int)
                        }
                        if (dataTrackOptionsMap["name"] != null) {
                            dataTrackOptionsBuilder.name(dataTrackOptionsMap["name"] as String)
                        }
                        dataTracks.add(LocalDataTrack.create(this.applicationContext, dataTrackOptionsBuilder.build()))
                    } else {
                        dataTracks.add(LocalDataTrack.create(this.applicationContext))
                    }
                }
                TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting dataTracks to '${dataTracks.joinToString(", ")}'")
                optionsBuilder.dataTracks(dataTracks)
            }

            // Set the local video tracks if it has been passed.
            if (optionsObj["videoTracks"] != null) {
                val videoTrackOptions = optionsObj["videoTracks"] as Map<*, *>

                val videoTracks = ArrayList<LocalVideoTrack?>()
                for ((videoTrack) in videoTrackOptions) {
                    videoTrack as Map<*, *> // Ensure right type.
                    val videoCapturerMap = videoTrack["videoCapturer"] as Map<*, *>
                    // Check type because we may want to add support for ScreenCapturer
                    val cameraId = when (videoCapturerMap["type"] as String) {
                        "CameraCapturer" -> when (videoCapturerMap["cameraSource"] as String) {
                            "BACK_CAMERA" -> getCameraId(CameraMetadata.LENS_FACING_BACK)
                            else -> getCameraId(CameraMetadata.LENS_FACING_FRONT)
                        }
                        else -> getCameraId(CameraMetadata.LENS_FACING_FRONT)
                    } ?: return result.error("MISSING_CAMERA", "No camera found for ${videoCapturerMap["cameraSource"]}", null)

                    val videoCapturer: VideoCapturer = Camera2Capturer(
                        this.applicationContext,
                        cameraId,
                        object : Listener {
                            override fun onError(camera2CapturerException: Camera2Capturer.Exception) {
                                TwilioProgrammableVideoPlugin.debug("Camera2Capturer.onError => $camera2CapturerException")
                                sendEvent("cameraError", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer)), camera2CapturerException)
                            }

                            override fun onFirstFrameAvailable() {
                                TwilioProgrammableVideoPlugin.debug("Camera2Capturer.onFirstFrameAvailable")
                                sendEvent("firstFrameAvailable", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer)), null)
                            }

                            override fun onCameraSwitched(newCameraId: String) {
                                TwilioProgrammableVideoPlugin.debug("Camera2Capturer.onCameraSwitched => newCameraId: $newCameraId")
                                sendEvent("cameraSwitched", mapOf("capturer" to videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer)), null)
                            }
                        }
                    )
                    if (videoCapturer is Camera2Capturer) {
                        TwilioProgrammableVideoPlugin.cameraCapturer = videoCapturer
                    }
                    videoTracks.add(LocalVideoTrack.create(this.applicationContext, videoTrack["enable"] as Boolean, videoCapturer, videoTrack["name"] as String))
                }
                TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting videoTracks to '${videoTracks.joinToString(", ")}'")
                optionsBuilder.videoTracks(videoTracks)
            }

            optionsBuilder.enableDominantSpeaker(if (optionsObj["enableDominantSpeaker"] != null) optionsObj["enableDominantSpeaker"] as Boolean else false)
            optionsBuilder.enableAutomaticSubscription(if (optionsObj["enableAutomaticSubscription"] != null) optionsObj["enableAutomaticSubscription"] as Boolean else true)

            val roomId = 1 // Future preparation, for when we might want to support multiple rooms.
            TwilioProgrammableVideoPlugin.roomListener = RoomListener(roomId, optionsBuilder.build())
            result.success(roomId)
        } catch (e: Exception) {
            result.error("INIT_ERROR", e.toString(), e)
        }
    }

    private fun getCameraManager(): CameraManager {
        return this.applicationContext.getSystemService(Context.CAMERA_SERVICE) as CameraManager
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
        }
        return mapOf(
                "type" to "Unknown",
                "isScreencast" to videoCapturer.isScreencast
        )
    }

    private fun debug(call: MethodCall, result: MethodChannel.Result) {
        val enableNative = call.argument<Boolean>("native")
            ?: return result.error("MISSING_PARAMS", "Missing 'native' parameter", null)

        TwilioProgrammableVideoPlugin.nativeDebug = enableNative
        result.success(enableNative)
    }

    private fun setAudioFocus(focus: Boolean) {
        if (focus) {
            previousAudioMode = audioManager.mode
            val volumeControlStream = this.activity?.volumeControlStream
            if (volumeControlStream != null) {
                previousVolumeControlStream = volumeControlStream
            }
            previousMicrophoneMute = audioManager.isMicrophoneMute

            // Request audio focus
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val playbackAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                        .setAudioAttributes(playbackAttributes)
                        .setAcceptsDelayedFocusGain(true)
                        .setOnAudioFocusChangeListener { }
                        .build()
                audioManager.requestAudioFocus(audioFocusRequest)
            } else {
                audioManager.requestAudioFocus(null, AudioManager.STREAM_VOICE_CALL,
                        AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
            }
            /*
             * Use MODE_IN_COMMUNICATION as the default audio mode. It is required
             * to be in this mode when playout and/or recording starts for the best
             * possible VoIP performance. Some devices have difficulties with
             * speaker mode if this is not set.
             */
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION

            /*
             * Always disable microphone mute during a WebRTC call.
             */

            audioManager.isMicrophoneMute = false
            this.activity?.volumeControlStream = AudioManager.STREAM_VOICE_CALL

            myNoisyAudioStreamReceiver = BecomingNoisyReceiver(audioManager, applicationContext)
            applicationContext.registerReceiver(myNoisyAudioStreamReceiver, IntentFilter(Intent.ACTION_HEADSET_PLUG))
            applicationContext.registerReceiver(myNoisyAudioStreamReceiver, IntentFilter(BluetoothAdapter.ACTION_CONNECTION_STATE_CHANGED))
            applicationContext.registerReceiver(myNoisyAudioStreamReceiver, IntentFilter(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED))
        } else {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                audioManager.abandonAudioFocus(null)
            } else if (audioFocusRequest != null) {
                audioManager.abandonAudioFocusRequest(audioFocusRequest)
            }
            audioManager.setSpeakerphoneOn(false)
            audioManager.mode = previousAudioMode
            audioManager.isMicrophoneMute = previousMicrophoneMute
            this.activity?.volumeControlStream = previousVolumeControlStream
            try {
                applicationContext.unregisterReceiver(myNoisyAudioStreamReceiver)
                myNoisyAudioStreamReceiver?.dispose()
                myNoisyAudioStreamReceiver = null
            } catch (e: java.lang.Exception) {
                TwilioProgrammableVideoPlugin.debug("${e.message}")
                e.printStackTrace()
            }
        }
    }
}
