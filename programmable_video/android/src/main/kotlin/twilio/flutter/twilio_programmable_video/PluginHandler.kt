package twilio.flutter.twilio_programmable_video

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.twilio.video.*
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.util.Queue
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicLong
import tvi.webrtc.voiceengine.WebRtcAudioUtils

class PluginHandler : MethodCallHandler, ActivityAware, BaseListener {
    private data class TakePhotoRequest(val call: MethodCall, val result: MethodChannel.Result)

    private var previousAudioMode: Int = 0

    private var previousMicrophoneMute: Boolean = false

    private var audioFocusRequest: AudioFocusRequest? = null

    private var previousVolumeControlStream: Int = 0

    private var activity: Activity? = null

    var applicationContext: Context

    private var myNoisyAudioStreamReceiver: BecomingNoisyReceiver? = null

    private var audioManager: AudioManager

    private var frameCount: AtomicLong = AtomicLong(0)

    private lateinit var frameToKeep: I420Frame

    private val takePhotoQueue: Queue<TakePhotoRequest> = ConcurrentLinkedQueue<TakePhotoRequest>()

    private var allowCamera2 = false

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
            "LocalParticipant#resetVideo" -> localParticipantResetVideo(call, result)
            "LocalVideoTrack#enable" -> localVideoTrackEnable(call, result)
            "LocalVideoTrack#frameCount" -> localVideoTrackFrameCount(call, result)
            "RemoteAudioTrack#enablePlayback" -> remoteAudioTrackEnable(call, result)
            "RemoteAudioTrack#isPlaybackEnabled" -> isRemoteAudioTrackPlaybackEnabled(call, result)
            "CameraCapturer#switchCamera" -> switchCamera(call, result)
            "CameraCapturer#takePhoto" -> takePhoto(call, result)
            "CameraCapturer#hasTorch" -> hasTorch(result)
            "CameraCapturer#setTorch" -> setTorch(call, result)
            else -> result.notImplemented()
        }
    }

    private fun takePhoto(call: MethodCall, result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.debug("PluginHandler.takePhoto => called")
        if (allowCamera2) {
            takePhotoQueue.offer(TakePhotoRequest(call, result))
        } else {
            val imageCompression = call.argument<Int>("imageCompression") ?: 100
            return try {
                val yuvFrame = YuvFrame(frameToKeep)
                if (!yuvFrame.hasData()) {
                    result.error("ERROR", "Photo data is empty", null)
                }
                val bitmap = yuvFrame.bitmap
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, imageCompression, stream)
                val byteArray = stream.toByteArray()
                TwilioProgrammableVideoPlugin.debug("PluginHandler.takePhoto => Photo data size: ${byteArray.size}")
                bitmap.recycle()
                result.success(byteArray)
            } catch (e: java.lang.Exception) {
                result.error("ERROR", "Error taking photo", e)
            }
        }
    }

    /**
     * Called when the local video track renders a frame.
     * The frame is used for take photo requests.
     */
    fun onRenderFrame(frame: I420Frame) {
        Handler(Looper.getMainLooper()).post {
            frameCount.incrementAndGet()
            var request = takePhotoQueue.poll()
            while (request != null) {
                val (call, result) = request

                val i420Buffer = YuvUtils.createI420Buffer(frame)
                if (i420Buffer != null) {
                    val quality = call.argument<Int>("imageCompression") ?: 100
                    val nv21Data = YuvUtils.createNV21Data(i420Buffer)
                    val jpegData = YuvUtils.createJPEGData(nv21Data, i420Buffer.width, i420Buffer.height, quality)
                    TwilioProgrammableVideoPlugin.debug("PluginHandler.onRenderFrame => Photo data size: ${jpegData.size}")
                    result.success(jpegData)
                } else {
                    result.error("ERROR", "Photo data is empty", null)
                }

                request = takePhotoQueue.poll()
            }
        }
    }

    fun getAllowCamera2(): Boolean {
        return allowCamera2
    }

    private fun switchCamera(call: MethodCall, result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.debug("PluginHandler.switchCamera => called")
        VideoCapturerHandler.switchCamera(call, result)
    }

    private fun hasTorch(result: MethodChannel.Result) {
        VideoCapturerHandler.hasTorch(result)
    }

    private fun setTorch(call: MethodCall, result: MethodChannel.Result) {
        VideoCapturerHandler.setTorch(call, result)
    }

    private fun localParticipantResetVideo(call: MethodCall, result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.debug("PluginHandler.localParticipantResetVideo => called")
        val localVideoTrack = getLocalParticipant()?.localVideoTracks?.firstOrNull()
        if (localVideoTrack != null && localVideoTrack.isTrackEnabled) {
            getLocalParticipant()?.unpublishTrack(localVideoTrack.localVideoTrack)
            getLocalParticipant()?.publishTrack(localVideoTrack.localVideoTrack)
            return result.success(true)
        }
        TwilioProgrammableVideoPlugin.debug("No LocalVideoTrack found or LocalVideoTrack already released while resetting video")
        return result.success(false)
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

    private fun localVideoTrackFrameCount(call: MethodCall, result: MethodChannel.Result) {
        val localVideoTrack = getLocalParticipant()?.localVideoTracks?.firstOrNull()
        if (localVideoTrack == null) {
            TwilioProgrammableVideoPlugin.debug("PluginHandler.localVideoTrack#FrameCount => No video track found")
        }
        return result.success(frameCount.get())
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

    private fun remoteAudioTrackEnable(call: MethodCall, result: MethodChannel.Result) {
        val remoteAudioTrackSid = call.argument<String>("sid")
                ?: return result.error("MISSING_PARAMS", "The parameter 'sid' was not given", null)
        val enable = call.argument<Boolean>("enable")
                ?: return result.error("MISSING_PARAMS", "The parameter 'enable' was not given", null)
        TwilioProgrammableVideoPlugin.debug("PluginHandler.remoteAudioTrackEnable => sid: $remoteAudioTrackSid enable: $enable")
        val remoteAudioTrack = getRemoteAudioTrack(remoteAudioTrackSid)
                ?: return result.error("NOT_FOUND", "No RemoteAudioTrack found with sid $remoteAudioTrackSid", null)

        remoteAudioTrack.remoteAudioTrack?.enablePlayback(enable)
        return result.success(null)
    }

    private fun isRemoteAudioTrackPlaybackEnabled(call: MethodCall, result: MethodChannel.Result) {
        val remoteAudioTrackSid = call.argument<String>("sid")
                ?: return result.error("MISSING_PARAMS", "The parameter 'sid' was not given", null)
        TwilioProgrammableVideoPlugin.debug("PluginHandler.isRemoteAudioTrackPlaybackEnabled => sid: $remoteAudioTrackSid")
        val remoteAudioTrack = getRemoteAudioTrack(remoteAudioTrackSid)
                ?: return result.error("NOT_FOUND", "No RemoteAudioTrack found with sid $remoteAudioTrackSid", null)

        return result.success(remoteAudioTrack.remoteAudioTrack?.isPlaybackEnabled)
    }

    private fun getRemoteAudioTrack(sid: String): RemoteAudioTrackPublication? {
        val remoteParticipants = TwilioProgrammableVideoPlugin.roomListener?.room?.remoteParticipants
                ?: return null

        var remoteAudioTrack: RemoteAudioTrackPublication? = null
        for (remoteParticipant in remoteParticipants) {
            remoteAudioTrack = remoteParticipant.remoteAudioTracks.firstOrNull { it.trackSid.equals(sid) }
            if (remoteAudioTrack != null) return remoteAudioTrack
        }
        return null
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

            if (optionsObj["allowCamera2"] != null && optionsObj["allowCamera2"] is Boolean) {
                TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting allowCamera2 to '${optionsObj["allowCamera2"]}'")
                allowCamera2 = optionsObj["allowCamera2"] as Boolean
            }

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

            optionsBuilder.encodingParameters(EncodingParameters(16, 0))

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

                TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting enableNetworkQuality to '${optionsObj["enableNetworkQuality"]}'")
                optionsBuilder.enableNetworkQuality(optionsObj["enableNetworkQuality"] as Boolean)

                if (optionsObj["networkQualityConfiguration"] != null) {
                    val networkQualityConfigurationMap = optionsObj["networkQualityConfiguration"] as Map<*, *>
                    val local: NetworkQualityVerbosity = getNetworkQualityVerbosity(networkQualityConfigurationMap["local"] as String)
                    val remote: NetworkQualityVerbosity = getNetworkQualityVerbosity(networkQualityConfigurationMap["remote"] as String)
                    optionsBuilder.networkQualityConfiguration(NetworkQualityConfiguration(local, remote))
                }

                // Set the local video tracks if it has been passed.
                if (optionsObj["videoTracks"] != null) {
                    val videoTrackOptions = optionsObj["videoTracks"] as Map<*, *>

                val videoTracks = ArrayList<LocalVideoTrack?>()
                for ((videoTrack) in videoTrackOptions) {
                    videoTrack as Map<*, *> // Ensure right type.
                    val videoCapturerMap = videoTrack["videoCapturer"] as Map<*, *>

                    if ((videoCapturerMap["type"] as String).equals("CameraCapturer")) {
                        VideoCapturerHandler.initializeCapturer(videoCapturerMap, result, allowCamera2)
                    } else {
                        return result.error("INIT_ERROR", "VideoCapturer type ${videoCapturerMap["type"]} not yet supported.", null)
                    }

                    if (TwilioProgrammableVideoPlugin.cameraCapturer != null) {
                        if (allowCamera2) {
                            // Sorted by height, then width, then fps. Eg. 1440x1080, 1600x720, 1280×720, 800x600
                            val formats = TwilioProgrammableVideoPlugin.cameraCapturer.supportedFormats.sortedWith(compareBy(
                                    { it.dimensions.height },
                                    { it.dimensions.width },
                                    { it.framerate }
                            )).reversed()

                            TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => supported camera formats")
                            for (format in formats) {
                                TwilioProgrammableVideoPlugin.debug("${format.dimensions.width}x${format.dimensions.height} ${format.framerate}fps")
                            }

                            var highestDimensions = VideoDimensions.HD_720P_VIDEO_DIMENSIONS
                            val highestFPS = VideoConstraints.FPS_24
                            for (format in formats) {
                                // Find a format closest to 720p 24fps
                                if (format.dimensions.height >= VideoDimensions.HD_720P_VIDEO_HEIGHT && format.framerate >= VideoConstraints.FPS_24) {
                                    highestDimensions = format.dimensions
                                } else {
                                    // We don't want anything lower than 720p 24fps
                                    break
                                }
                            }
                            TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => selected camera format: ${highestDimensions.width}x${highestDimensions.height} ${highestFPS}fps")

                            val videoConstraints = VideoConstraints.Builder()
                                    .minVideoDimensions(highestDimensions)
                                    .maxVideoDimensions(highestDimensions)
                                    .maxFps(highestFPS)
                                    .minFps(highestFPS)
                                    .build()

                            frameCount.set(0)
                            videoTracks.add(LocalVideoTrack.create(this.applicationContext, videoTrack["enable"] as Boolean, TwilioProgrammableVideoPlugin.cameraCapturer, videoConstraints, videoTrack["name"] as String))
                        } else {
                            val formats = TwilioProgrammableVideoPlugin.cameraCapturer.supportedFormats
                            // Not all devices report the formats in the same order
                            formats.sortedWith(compareBy({ it.dimensions.width }, { it.dimensions.height }))

                            TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => support camera formats")
                            for(format in formats) {
                                TwilioProgrammableVideoPlugin.debug("${format.dimensions.width} x ${format.dimensions.height}")
                            }

                            val highestDimensions = formats.first().dimensions
                            var videoDimensions = VideoDimensions(VideoDimensions.HD_720P_VIDEO_WIDTH, VideoDimensions.HD_720P_VIDEO_HEIGHT)
                            if (highestDimensions.height < VideoDimensions.HD_720P_VIDEO_HEIGHT) {
                                videoDimensions = VideoDimensions(highestDimensions.width, highestDimensions.height)
                            }

                            val videoConstraints = VideoConstraints.Builder()
                                    .minVideoDimensions(videoDimensions)
                                    .maxVideoDimensions(videoDimensions)
                                    .maxFps(VideoConstraints.FPS_24)
                                    .minFps(VideoConstraints.FPS_24)
                                    .build()

                            val localVideoTrack = LocalVideoTrack.create(this.applicationContext, videoTrack["enable"] as Boolean, TwilioProgrammableVideoPlugin.cameraCapturer, videoConstraints, videoTrack["name"] as String)
                            // Reset the frame count and add a renderer to count frames
                            // Also hold on the current frame being processed for the take photo method
                            frameCount.set(0)
                            localVideoTrack?.addRenderer(fun(it: I420Frame) {
                                frameCount.incrementAndGet()
                                frameToKeep = it
                            })
                            videoTracks.add(localVideoTrack)
                        }
                    }
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

    private fun getNetworkQualityVerbosity(verbosity: String): NetworkQualityVerbosity {
        return when (verbosity) {
            "NETWORK_QUALITY_VERBOSITY_NONE" -> NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_NONE
            "NETWORK_QUALITY_VERBOSITY_MINIMAL" -> NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_MINIMAL
            else -> NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_NONE
        }
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

    fun sendCameraEvent(name: String, data: Any, e: TwilioException? = null) {
        sendEvent(name, data, e)
    }
}
