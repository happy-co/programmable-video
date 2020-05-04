package twilio.flutter.twilio_programmable_video

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import androidx.annotation.NonNull
import com.twilio.video.AudioCodec
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

class PluginHandler : MethodCallHandler, ActivityAware {
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
            else -> result.notImplemented()
        }
    }

    private fun switchCamera(call: MethodCall, result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.debug("PluginHandler.switchCamera => called")
        if (TwilioProgrammableVideoPlugin.cameraCapturer != null) {
            val source = if (TwilioProgrammableVideoPlugin.cameraCapturer.cameraSource == CameraCapturer.CameraSource.FRONT_CAMERA) {
                CameraCapturer.CameraSource.BACK_CAMERA
            } else {
                CameraCapturer.CameraSource.FRONT_CAMERA
            }
            TwilioProgrammableVideoPlugin.cameraCapturer.switchCamera()

            return result.success(RoomListener.videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer, source))
        }
        return result.error("NOT FOUND", "No CameraCapturer has been initialized yet natively", null)
    }

    private fun localVideoTrackEnable(call: MethodCall, result: MethodChannel.Result) {
        val localVideoTrackName = call.argument<String>("name")
        val localVideoTrackEnable = call.argument<Boolean>("enable")
        TwilioProgrammableVideoPlugin.debug("PluginHandler.localVideoTrackEnable => called for $localVideoTrackName, enable=$localVideoTrackEnable")
        if (localVideoTrackName != null && localVideoTrackEnable != null) {
            val localVideoTrack = getLocalParticipant()?.localVideoTracks?.firstOrNull { it.trackName == localVideoTrackName }
            if (localVideoTrack != null) {
                localVideoTrack.localVideoTrack.enable(localVideoTrackEnable)
                return result.success(true)
            }
            return result.error("NOT_FOUND", "No LocalVideoTrack found with the name '$localVideoTrackName'", null)
        }
        return result.error("MISSING_PARAMS", "The parameters 'name' and 'enable' were not given", null)
    }

    private fun localAudioTrackEnable(call: MethodCall, result: MethodChannel.Result) {
        val localAudioTrackName = call.argument<String>("name")
        val localAudioTrackEnable = call.argument<Boolean>("enable")
        TwilioProgrammableVideoPlugin.debug("PluginHandler.localAudioTrackEnable => called for $localAudioTrackName, enable=$localAudioTrackEnable")
        if (localAudioTrackName != null && localAudioTrackEnable != null) {
            val localAudioTrack = TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localAudioTracks?.firstOrNull { it.trackName == localAudioTrackName }
            if (localAudioTrack != null) {
                localAudioTrack.localAudioTrack.enable(localAudioTrackEnable)
                return result.success(true)
            }
            return result.error("NOT_FOUND", "No LocalAudioTrack found with the name '$localAudioTrackName'", null)
        }
        return result.error("MISSING_PARAMS", "The parameters 'name' and 'enable' were not given", null)
    }

    private fun localDataTrackSendString(call: MethodCall, result: MethodChannel.Result) {
        val localDataTrackName = call.argument<String>("name")
        val localDataTrackMessage = call.argument<String>("message")
        TwilioProgrammableVideoPlugin.debug("PluginHandler.localDataTrackSendString => called for $localDataTrackName")
        if (localDataTrackName != null && localDataTrackMessage != null) {
            val localDataTrack = TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localDataTracks?.firstOrNull { it.trackName == localDataTrackName }
            if (localDataTrack != null) {
                localDataTrack.localDataTrack.send(localDataTrackMessage)
                return result.success(null)
            }
            return result.error("NOT_FOUND", "No LocalDataTrack found with the name '$localDataTrackName'", null)
        }
        return result.error("MISSING_PARAMS", "The parameters 'name' and 'message' were not given", null)
    }

    private fun localDataTrackSendByteBuffer(call: MethodCall, result: MethodChannel.Result) {
        val localDataTrackName = call.argument<String>("name")
        val localDataTrackMessage = call.argument<ByteArray>("message")
        TwilioProgrammableVideoPlugin.debug("PluginHandler.localDataTrackSendByteBuffer => called for $localDataTrackName")
        if (localDataTrackName != null && localDataTrackMessage != null) {
            val localDataTrack = TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localDataTracks?.firstOrNull { it.trackName == localDataTrackName }
            if (localDataTrack != null) {
                localDataTrack.localDataTrack.send(ByteBuffer.wrap(localDataTrackMessage))
                return result.success(null)
            }
            return result.error("NOT_FOUND", "No LocalDataTrack found with the name '$localDataTrackName'", null)
        }
        return result.error("MISSING_PARAMS", "The parameters 'name' and 'message' were not given", null)
    }

    private fun setSpeakerphoneOn(call: MethodCall, result: MethodChannel.Result) {
        val on = call.argument<Boolean>("on")
        if (on != null) {
            audioManager.isSpeakerphoneOn = on
            return result.success(on)
        }
        return result.error("MISSING_PARAMS", "The parameter 'on' was not given", null)
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

        setAudioFocus(true)
        val optionsObj = call.argument<Map<String, Any>>("connectOptions")
        if (optionsObj != null) {
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

                        val videoCapturer: VideoCapturer = when (videoCapturerMap["type"] as String) {
                            "CameraCapturer" -> when (videoCapturerMap["cameraSource"] as String) {
                                "FRONT_CAMERA" -> CameraCapturer(this.applicationContext, CameraCapturer.CameraSource.FRONT_CAMERA)
                                "BACK_CAMERA" -> CameraCapturer(this.applicationContext, CameraCapturer.CameraSource.BACK_CAMERA)
                                else -> CameraCapturer(this.applicationContext, CameraCapturer.CameraSource.FRONT_CAMERA)
                            }
                            else -> CameraCapturer(this.applicationContext, CameraCapturer.CameraSource.FRONT_CAMERA)
                        }
                        if (videoCapturer is CameraCapturer) {
                            TwilioProgrammableVideoPlugin.cameraCapturer = videoCapturer
                        }
                        videoTracks.add(LocalVideoTrack.create(this.applicationContext, videoTrack["enable"] as Boolean, videoCapturer, videoTrack["name"] as String))
                    }
                    TwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting videoTracks to '${videoTracks.joinToString(", ")}'")
                    optionsBuilder.videoTracks(videoTracks)
                }

                optionsBuilder.enableDominantSpeaker(if (optionsObj["enableDominantSpeaker"] != null) optionsObj["enableDominantSpeaker"] as Boolean else false)

                val roomId = 1 // Future preparation, for when we might want to support multiple rooms.
                TwilioProgrammableVideoPlugin.roomListener = RoomListener(roomId, optionsBuilder.build())
                result.success(roomId)
            } catch (e: Exception) {
                result.error("INIT_ERROR", e.toString(), e)
            }
        } else {
            result.error("INIT_ERROR", "Missing 'connectOptions' parameter", null)
        }
    }

    private fun debug(call: MethodCall, result: MethodChannel.Result) {
        val enableNative = call.argument<Boolean>("native")
        if (enableNative != null) {
            TwilioProgrammableVideoPlugin.nativeDebug = enableNative
            result.success(enableNative)
        } else {
            result.error("MISSING_PARAMS", "Missing 'native' parameter", null)
        }
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
