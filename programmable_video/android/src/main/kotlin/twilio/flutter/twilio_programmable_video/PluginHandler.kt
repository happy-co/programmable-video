package twilio.flutter.twilio_programmable_video

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.twilio.video.AudioCodec
import com.twilio.video.Camera2Capturer
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
import com.twilio.video.NetworkQualityConfiguration
import com.twilio.video.NetworkQualityVerbosity
import com.twilio.video.OpusCodec
import com.twilio.video.PcmaCodec
import com.twilio.video.PcmuCodec
import com.twilio.video.RemoteAudioTrackPublication
import com.twilio.video.RemoteParticipant
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
    private val TAG = "PluginHandler"

    private var previousAudioMode: Int? = null

    private var previousMicrophoneMute: Boolean = false

    private var audioFocusRequest: AudioFocusRequest? = null

    private var previousVolumeControlStream: Int = 0

    private var activity: Activity? = null

    var applicationContext: Context

    internal var audioManager: AudioManager

    internal var audioSettings: AudioSettings = AudioSettings()

    private var photographer: Photographer? = null

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
        // `getStats`, if called repeatedly to drive an animation, is quite noisy
        if (call.method != "getStats") {
            debug("onMethodCall => received ${call.method}")
        }
        when (call.method) {
            "debug" -> debug(call, result)
            "connect" -> connect(call, result)
            "disconnect" -> disconnect(call, result)
            "setAudioSettings" -> setAudioSettings(call, result)
            "getAudioSettings" -> getAudioSettings(call, result)
            "disableAudioSettings" -> disableAudioSettings(call, result)
            "setSpeakerphoneOn" -> setSpeakerphoneOn(call, result)
            "getSpeakerphoneOn" -> getSpeakerphoneOn(result)
            "deviceHasReceiver" -> deviceHasReceiver(result)
            "getStats" -> getStats(result)
            "LocalAudioTrack#enable" -> localAudioTrackEnable(call, result)
            "LocalDataTrack#sendString" -> localDataTrackSendString(call, result)
            "LocalDataTrack#sendByteBuffer" -> localDataTrackSendByteBuffer(call, result)
            "LocalVideoTrack#enable" -> localVideoTrackEnable(call, result)
            "RemoteAudioTrack#enablePlayback" -> remoteAudioTrackEnable(call, result)
            "RemoteAudioTrack#isPlaybackEnabled" -> isRemoteAudioTrackPlaybackEnabled(call, result)
            "CameraCapturer#switchCamera" -> switchCamera(call, result)
            "CameraCapturer#takePhoto" -> takePhoto(result)
            "CameraCapturer#setTorch" -> setTorch(call, result)
            "CameraSource#getSources" -> getSources(call, result)
            else -> result.notImplemented()
        }
    }

    private fun takePhoto(result: MethodChannel.Result) {
        val photographer = this.photographer
        if (photographer != null) {
            photographer.takePicture { jpeg: ByteArray? ->
                if (jpeg != null) {
                    result.success(jpeg)
                } else {
                    result.error("ERROR", "Error converting video frame to JPEG", null)
                }
            }
        } else {
            result.error("NOT_FOUND", "No LocalVideoTrack initialised to capture photo", null)
        }
    }

    private fun getSources(call: MethodCall, result: MethodChannel.Result) {
        debug("getSources => called")
        return result.success(TwilioProgrammableVideoPlugin.cameraEnumerator.deviceNames.map {
            VideoCapturerHandler.cameraIdToMap(it)
        })
    }

    private fun switchCamera(call: MethodCall, result: MethodChannel.Result) {
        debug("switchCamera => called")
        val newCameraId = call.argument<String>("cameraId")
                ?: return result.error("MISSING_PARAMS", missingParameterMessage("cameraId"), null)

        val capturer = TwilioProgrammableVideoPlugin.cameraCapturer
        if (capturer is Camera2Capturer)
            capturer.switchCamera(newCameraId)
        else if (capturer is CameraCapturer)
            capturer.switchCamera(newCameraId)

        return result.success(VideoCapturerHandler.videoCapturerToMap(TwilioProgrammableVideoPlugin.cameraCapturer!!, newCameraId))
    }

    private fun setTorch(call: MethodCall, result: MethodChannel.Result) {
        VideoCapturerHandler.setTorch(call, result)
    }

    private fun localVideoTrackEnable(call: MethodCall, result: MethodChannel.Result) {
        val localVideoTrackName = call.argument<String>("name")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("name"), null)
        val localVideoTrackEnable = call.argument<Boolean>("enable")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("enable"), null)

        debug("localVideoTrackEnable => called for $localVideoTrackName, enable=$localVideoTrackEnable")

        val localVideoTrack = getLocalParticipant()?.localVideoTracks?.firstOrNull { it.trackName == localVideoTrackName }
        if (localVideoTrack != null) {
            localVideoTrack.localVideoTrack.enable(localVideoTrackEnable)
            return result.success(null)
        }
        return result.error("NOT_FOUND", "No LocalVideoTrack found with the name '$localVideoTrackName'", null)
    }

    private fun localAudioTrackEnable(call: MethodCall, result: MethodChannel.Result) {
        val localAudioTrackName = call.argument<String>("name")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("name"), null)
        val localAudioTrackEnable = call.argument<Boolean>("enable")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("enable"), null)

        debug("localAudioTrackEnable => called for $localAudioTrackName, enable=$localAudioTrackEnable")

        val localAudioTrack = TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localAudioTracks?.firstOrNull { it.trackName == localAudioTrackName }
        if (localAudioTrack != null) {
            localAudioTrack.localAudioTrack.enable(localAudioTrackEnable)
            return result.success(null)
        }
        return result.error("NOT_FOUND", "No LocalAudioTrack found with the name '$localAudioTrackName'", null)
    }

    private fun localDataTrackSendString(call: MethodCall, result: MethodChannel.Result) {
        val localDataTrackName = call.argument<String>("name")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("name"), null)
        val localDataTrackMessage = call.argument<String>("message")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("message"), null)

        debug("localDataTrackSendString => called for $localDataTrackName")

        val localDataTrack = TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localDataTracks?.firstOrNull { it.trackName == localDataTrackName }
            ?: return result.error("NOT_FOUND", "No LocalDataTrack found with the name '$localDataTrackName'", null)

        localDataTrack.localDataTrack.send(localDataTrackMessage)
        return result.success(null)
    }

    private fun localDataTrackSendByteBuffer(call: MethodCall, result: MethodChannel.Result) {
        val localDataTrackName = call.argument<String>("name")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("name"), null)
        val localDataTrackMessage = call.argument<ByteArray>("message")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("message"), null)

        debug("localDataTrackSendByteBuffer => called for $localDataTrackName")

        val localDataTrack = TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localDataTracks?.firstOrNull { it.trackName == localDataTrackName }
            ?: return result.error("NOT_FOUND", "No LocalDataTrack found with the name '$localDataTrackName'", null)

        localDataTrack.localDataTrack.send(ByteBuffer.wrap(localDataTrackMessage))
        return result.success(null)
    }

    private fun remoteAudioTrackEnable(call: MethodCall, result: MethodChannel.Result) {
        val remoteAudioTrackSid = call.argument<String>("sid")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("sid"), null)
        val enable = call.argument<Boolean>("enable")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("enable"), null)
        debug("remoteAudioTrackEnable => sid: $remoteAudioTrackSid enable: $enable")
        val remoteAudioTrack = getRemoteAudioTrack(remoteAudioTrackSid)
            ?: return result.error("NOT_FOUND", "No RemoteAudioTrack found with sid $remoteAudioTrackSid", null)

        remoteAudioTrack.remoteAudioTrack?.enablePlayback(enable)
        return result.success(null)
    }

    private fun isRemoteAudioTrackPlaybackEnabled(call: MethodCall, result: MethodChannel.Result) {
        val remoteAudioTrackSid = call.argument<String>("sid")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("sid"), null)
        debug("isRemoteAudioTrackPlaybackEnabled => sid: $remoteAudioTrackSid")
        val remoteAudioTrack = getRemoteAudioTrack(remoteAudioTrackSid)
            ?: return result.error("NOT_FOUND", "No RemoteAudioTrack found with sid $remoteAudioTrackSid", null)

        return result.success(remoteAudioTrack.remoteAudioTrack?.isPlaybackEnabled)
    }

    private fun getRemoteAudioTrack(sid: String): RemoteAudioTrackPublication? {
        val remoteParticipants = TwilioProgrammableVideoPlugin.roomListener.room?.remoteParticipants
            ?: return null

        var remoteAudioTrack: RemoteAudioTrackPublication?
        for (remoteParticipant in remoteParticipants) {
            remoteAudioTrack = remoteParticipant.remoteAudioTracks.firstOrNull { it.trackSid == sid }
            if (remoteAudioTrack != null) return remoteAudioTrack
        }
        return null
    }

    private fun setAudioSettings(call: MethodCall, result: MethodChannel.Result) {
        val speakerphoneEnabled = call.argument<Boolean>("speakerphoneEnabled")
                ?: return result.error("MISSING_PARAMS", missingParameterMessage("speakerphoneEnabled"), null)
        val bluetoothPreferred = call.argument<Boolean>("bluetoothPreferred")
                ?: return result.error("MISSING_PARAMS", missingParameterMessage("bluetoothPreferred"), null)

        audioSettings.speakerEnabled = speakerphoneEnabled
        audioSettings.bluetoothPreferred = bluetoothPreferred

        TwilioProgrammableVideoPlugin.audioNotificationListener.listenForRouteChanges(applicationContext)

        applyAudioSettings()

        result.success(null)
    }

    private fun getAudioSettings(call: MethodCall, result: MethodChannel.Result) {
        val audioSettingsMap =
            mapOf(
                "speakerphoneEnabled" to audioSettings.speakerEnabled,
                "bluetoothPreferred" to audioSettings.bluetoothPreferred
            )
        result.success(audioSettingsMap)
    }

    private fun disableAudioSettings(call: MethodCall, result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.audioNotificationListener.stopListeningForRouteChanges(applicationContext)
        audioSettings.reset()
        result.success(null)
    }

    internal fun applyAudioSettings() {
        debug("applyAudioSettings")
        setSpeakerPhoneOnInternal()
        applyBluetoothSettings()
    }

    // BluetoothSco being enabled functions similarly to holding Audio Focus when it comes
    // to external apps audio, if that external app would normally be using the connected
    // bluetooth device. That is, it prevents the external app from continuing or resuming playback.
    //
    // Given this, we only want to turn BluetoothSco on when we are actually using the audio system.
    internal fun applyBluetoothSettings() {
        val isConnected = TwilioProgrammableVideoPlugin.isConnected()
        val anyPlaying = TwilioProgrammableVideoPlugin.audioNotificationListener.anyAudioPlayersActive()
        debug("applyBluetoothSettings BEGIN =>\n" +
            "\ton: ${audioSettings.bluetoothPreferred}\n" +
            "\tscoOn: ${audioManager.isBluetoothScoOn}\n" +
            "\tconnected: $isConnected\n" +
            "\tanyPlaying: $anyPlaying")
        if (isConnected || anyPlaying) {
            Handler(Looper.getMainLooper()).postDelayed({
                setBluetoothSco(audioSettings.bluetoothPreferred)
                audioManager.isBluetoothScoOn = audioSettings.bluetoothPreferred
                debug("applyBluetoothSettings END => on: ${audioSettings.bluetoothPreferred} scoOn: ${audioManager.isBluetoothScoOn}")
            }, 1000)
        }
    }

    internal fun setBluetoothSco(on: Boolean) {
        if (on) {
            audioManager.startBluetoothSco()
            debug("startBluetoothSco => on: $on\n" +
                    "\tbluetoothPreferred: ${audioSettings.bluetoothPreferred}\n" +
                    "\tscoOn: ${audioManager.isBluetoothScoOn}")
        } else {
            audioManager.stopBluetoothSco()
            debug("stopBluetoothSco => on: $on\n\tbluetoothPreferred: ${audioSettings.bluetoothPreferred}\n\tscoOn: ${audioManager.isBluetoothScoOn}")
        }
    }

    private fun setSpeakerphoneOn(call: MethodCall, result: MethodChannel.Result) {
        val on = call.argument<Boolean>("on")
            ?: return result.error("MISSING_PARAMS", missingParameterMessage("on"), null)

        audioSettings.speakerEnabled = on
        setSpeakerPhoneOnInternal()

        if (!audioSettings.speakerEnabled && audioSettings.bluetoothPreferred) {
            applyBluetoothSettings()
        }
        return result.success(audioSettings.speakerEnabled)
    }

    private fun setSpeakerPhoneOnInternal() {
        val bluetoothProfileConnectionState = BluetoothAdapter.getDefaultAdapter().getProfileConnectionState(BluetoothProfile.HEADSET)
        debug("setSpeakerPhoneOnInternal => on: ${audioSettings.speakerEnabled}\n bluetoothEnable: ${audioSettings.bluetoothPreferred}\n bluetoothScoOn: ${audioManager.isBluetoothScoOn}\n bluetoothProfileConnectionState: $bluetoothProfileConnectionState")

        // Even if already enabled, setting `audioManager.isSpeakerphoneOn` to true
        // will reroute audio to the speaker. If using a Bluetooth headset, this will cause audio to
        // momentarily be routed to the device bottom speaker.
        //
        // It has been observed when disconnecting a bluetooth headset that sometimes
        // the bluetoothProfileConnectionState will still be BluetoothProfile.STATE_CONNECTED
        // resulting in an edge case where audio will be routed via the receiver rather than the
        // bottom speaker.
        if (!audioSettings.bluetoothPreferred ||
                bluetoothProfileConnectionState != BluetoothProfile.STATE_CONNECTED) {
            applySpeakerPhoneSettings()
        }
    }

    internal fun applySpeakerPhoneSettings() {
        debug("applySpeakerPhoneSettings => enabled: ${audioSettings.speakerEnabled}")
        audioManager.isSpeakerphoneOn = audioSettings.speakerEnabled
    }

    private fun getSpeakerphoneOn(result: MethodChannel.Result) {
        return result.success(audioManager.isSpeakerphoneOn)
    }

    /*
     * Automatically returns true on SDKs lower than 23 as there is officially no method of querying
     * available audio devices on earlier SDKs. See: https://github.com/google/oboe/issues/67
     */
    private fun deviceHasReceiver(result: MethodChannel.Result) {
        val hasReceiver = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            devices.any { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }
        } else {
            true
        }
        debug("deviceHasReceiver => called $hasReceiver")
        return result.success(hasReceiver)
    }

    private fun getStats(result: MethodChannel.Result) {
        TwilioProgrammableVideoPlugin.roomListener.room?.getStats {
            result.success(StatsMapper.statsReportsToMap(it))
        }
    }

    private fun disconnect(call: MethodCall, result: MethodChannel.Result) {
        debug("disconnect => called")
        TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localVideoTracks?.forEach { it.localVideoTrack.release() }
        TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localAudioTracks?.forEach { it.localAudioTrack.release() }
        TwilioProgrammableVideoPlugin.roomListener.room?.localParticipant?.localDataTracks?.forEach { it.localDataTrack.release() }
        TwilioProgrammableVideoPlugin.roomListener.room?.disconnect()
        TwilioProgrammableVideoPlugin.roomListener.room = null
        debug("disconnect => audioPlayers active: ${TwilioProgrammableVideoPlugin.audioNotificationListener.anyAudioPlayersActive()}")
        if (!TwilioProgrammableVideoPlugin.audioNotificationListener.anyAudioPlayersActive()) {
            setBluetoothSco(false)
            setAudioFocus(false)
        }
        result.success(true)
    }

    private fun connect(call: MethodCall, result: MethodChannel.Result) {
        debug("connect => called, Build.MODEL: '${Build.MODEL}'")
        if (TwilioProgrammableVideoPlugin.HARDWARE_AEC_BLACKLIST.contains(Build.MODEL) && !WebRtcAudioUtils.useWebRtcBasedAcousticEchoCanceler()) {
            debug("connect => setWebRtcBasedAcousticEchoCanceler: true")
            WebRtcAudioUtils.setWebRtcBasedAcousticEchoCanceler(true)
        }
        val optionsObj = call.argument<Map<String, Any>>("connectOptions")
            ?: return result.error("MISSING_PARAMS", "Missing 'connectOptions' parameter", null)

        val obtainedFocus = setAudioFocus(true)
        if (!obtainedFocus) {
            debug("connect => Failed to obtain audio focus, aborting connect.")
            return result.error("ACTIVE_CALL", "Detected an active call that is using the audio system.", null)
        }

        try {
            val optionsBuilder = ConnectOptions.Builder(optionsObj["accessToken"] as String)

            // Set the room name if it has been passed.
            if (optionsObj["roomName"] != null) {
                debug("connect => setting roomName to '${optionsObj["roomName"]}'")
                optionsBuilder.roomName(optionsObj["roomName"] as String)
            }

            // Set the region if it has been passed.
            if (optionsObj["region"] != null) {
                debug("connect => setting region to '${optionsObj["region"]}'")
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
                debug("connect => setting audioCodecs to '${audioCodecs.joinToString(", ")}'")
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
                debug("connect => setting videoCodecs to '${videoCodecs.joinToString(", ")}'")
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
                debug("connect => setting audioTracks to '${audioTracks.joinToString(", ")}'")
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
                debug("connect => setting dataTracks to '${dataTracks.joinToString(", ")}'")
                optionsBuilder.dataTracks(dataTracks)
            }

            debug("connect => setting enableNetworkQuality to '${optionsObj["enableNetworkQuality"]}'")
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

                    if ((videoCapturerMap["type"] as String) == "CameraCapturer") {
                        VideoCapturerHandler.initializeCapturer(videoCapturerMap, result)
                    } else {
                        return result.error("INIT_ERROR", "VideoCapturer type ${videoCapturerMap["type"]} not yet supported.", null)
                    }

                    if (TwilioProgrammableVideoPlugin.cameraCapturer != null) {
                        videoTracks.add(LocalVideoTrack.create(this.applicationContext, videoTrack["enable"] as Boolean, TwilioProgrammableVideoPlugin.cameraCapturer!!, videoTrack["name"] as String))
                    }
                }
                debug("connect => setting videoTracks to '${videoTracks.joinToString(", ")}'")
                optionsBuilder.videoTracks(videoTracks)
            }

            optionsBuilder.enableDominantSpeaker(if (optionsObj["enableDominantSpeaker"] != null) optionsObj["enableDominantSpeaker"] as Boolean else false)
            optionsBuilder.enableAutomaticSubscription(if (optionsObj["enableAutomaticSubscription"] != null) optionsObj["enableAutomaticSubscription"] as Boolean else true)

            applyAudioSettings()

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

        val enableAudio = call.argument<Boolean>("audio")
            ?: return result.error("MISSING_PARAMS", "Missing 'audio' parameter", null)

        TwilioProgrammableVideoPlugin.nativeDebug = enableNative
        TwilioProgrammableVideoPlugin.audioDebug = enableAudio
        result.success(enableNative)
    }

    internal fun setAudioFocus(focus: Boolean): Boolean {
        if (focus) {
            if (previousAudioMode == null) {
                previousAudioMode = audioManager.mode
            }
            val volumeControlStream = this.activity?.volumeControlStream
            if (volumeControlStream != null) {
                previousVolumeControlStream = volumeControlStream
            }
            previousMicrophoneMute = audioManager.isMicrophoneMute
            var requestResult: Int

            // Request audio focus
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val playbackAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
                audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                    .setAudioAttributes(playbackAttributes)
                    .setAcceptsDelayedFocusGain(false)
                    .setOnAudioFocusChangeListener {
                        // Occasionally observe during tests that just after requesting AudioFocus we receive a AudioFocus LOSS event
                        // When this occurred during tests, Spotify audio continues rather than pausing while our audio begins.
                        // We could look at introducing retry logic when this occurs, but this can also be solved by the user simply
                        // pausing playback from external apps if they encounter the issue.
                        //
                        // Per https://developer.android.com/guide/topics/media-apps/audio-focus AudioFocus is meant to be cooperative
                        // and is not enforced by the OS.
                        debug("onAudioFocusChange => focusChange: $it")
                    }
                    .build()
                debug("setAudioFocus =>" +
                    "\n\tfocus: $focus," +
                    "\n\taudioFocusRequest: $audioFocusRequest" +
                    "\n\tpreviousAudioMode: $previousAudioMode")
                requestResult = audioManager.requestAudioFocus(audioFocusRequest!!)
            } else {
                requestResult = audioManager.requestAudioFocus(
                    null, AudioManager.STREAM_VOICE_CALL,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                )
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
            val requestGranted = requestResult == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            debug("requestAudioFocus => requestGranted: $requestGranted")
            return requestGranted
        } else {
            debug("setAudioFocus =>" +
                    "\tfocus: $focus," +
                    "\taudioFocusRequest: $audioFocusRequest" +
                    "\tpreviousAudioMode: $previousAudioMode")
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                audioManager.abandonAudioFocus(null)
            } else if (audioFocusRequest != null) {
                audioManager.abandonAudioFocusRequest(audioFocusRequest!!)
            }
            audioManager.isSpeakerphoneOn = false
            if (previousAudioMode != null) {
                audioManager.mode = previousAudioMode!!
                previousAudioMode = null
            }
            audioManager.isMicrophoneMute = previousMicrophoneMute
            this.activity?.volumeControlStream = previousVolumeControlStream
            return true
        }
    }

    fun sendCameraEvent(name: String, data: Any, e: java.lang.Exception? = null) {
        sendEvent(name, data, e)
    }

    fun setPhotographer(photographer: Photographer) {
        this.photographer = photographer
    }

    private fun missingParameterMessage(parameterName: String): String {
        return "The parameter '$parameterName' was not given"
    }

    internal fun debug(msg: String) {
        TwilioProgrammableVideoPlugin.debug("$TAG::$msg")
    }
}
