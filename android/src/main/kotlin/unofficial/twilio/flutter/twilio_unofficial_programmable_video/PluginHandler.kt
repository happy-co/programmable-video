package unofficial.twilio.flutter.twilio_unofficial_programmable_video

import android.content.Context
import androidx.annotation.NonNull
import com.twilio.video.*
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class PluginHandler(private val applicationContext: Context) : MethodCallHandler {
    private val remoteParticipants: List<RemoteParticipant>?
        get() {
            return TwilioUnofficialProgrammableVideoPlugin.roomListener.room?.remoteParticipants?.toList()
        }

    fun getRemoteParticipant(sid: String?): RemoteParticipant? {
        return remoteParticipants?.first { it.sid == sid }
    }

    fun getLocalParticipant(): LocalParticipant? {
        return TwilioUnofficialProgrammableVideoPlugin.roomListener.room?.localParticipant
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        TwilioUnofficialProgrammableVideoPlugin.debug("TwilioUnofficialProgrammableVideoPlugin.onMethodCall => received ${call.method}")
        when (call.method) {
            "connect" -> connect(call, result)
            else -> result.notImplemented()
        }
    }

    private fun connect(call: MethodCall, result: MethodChannel.Result) {
        TwilioUnofficialProgrammableVideoPlugin.debug("TwilioUnofficialProgrammableVideoPlugin.connect => called")
        val optionsObj = call.argument<Map<String, Any>>("connectOptions")
        if (optionsObj != null) {
            try {
                val optionsBuilder = ConnectOptions.Builder(optionsObj["accessToken"] as String)

                // Set the room name if it has been passed.
                if (optionsObj["roomName"] != null) {
                    TwilioUnofficialProgrammableVideoPlugin.debug("TwilioUnofficialProgrammableVideoPlugin.connect => setting roomName to '${optionsObj["roomName"]}'")
                    optionsBuilder.roomName(optionsObj["roomName"] as String)
                }

                // Set the region if it has been passed.
                if (optionsObj["region"] != null) {
                    TwilioUnofficialProgrammableVideoPlugin.debug("TwilioUnofficialProgrammableVideoPlugin.connect => setting region to '${optionsObj["region"]}'")
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
                    TwilioUnofficialProgrammableVideoPlugin.debug("TwilioUnofficialProgrammableVideoPlugin.connect => setting audioCodecs to '${audioCodecs.joinToString(", ")}'")
                    optionsBuilder.preferAudioCodecs(audioCodecs)
                }

                // Set the preferred video codecs if it has been passed.
                if (optionsObj["preferredVideoCodecs"] != null) {
                    val preferredVideoCodecs = optionsObj["preferredVideoCodecs"] as Map<*, *>

                    val videoCodecs = ArrayList<VideoCodec>()
                    for ((videoCodec) in preferredVideoCodecs) {
                        when (videoCodec) {
                            Vp8Codec.NAME -> videoCodecs.add(Vp8Codec()) // TODO: It has an optional parameter, need to figure out for what: https://github.com/twilio/video-quickstart-android/blob/master/quickstartKotlin/src/main/java/com/twilio/video/quickstart/kotlin/VideoActivity.kt#L106
                            Vp9Codec.NAME -> videoCodecs.add(Vp9Codec())
                            H264Codec.NAME -> videoCodecs.add(H264Codec())
                            else -> videoCodecs.add(Vp8Codec())
                        }
                    }
                    TwilioUnofficialProgrammableVideoPlugin.debug("TwilioUnofficialProgrammableVideoPlugin.connect => setting videoCodecs to '${videoCodecs.joinToString(", ")}'")
                    optionsBuilder.preferVideoCodecs(videoCodecs)
                }

                // Set the local audio tracks if it has been passed.
                if (optionsObj["audioTracks"] != null) {
                    val audioTrackOptions = optionsObj["audioTracks"] as Map<*, *>

                    val audioTracks = ArrayList<LocalAudioTrack?>()
                    for ((audioTrack) in audioTrackOptions) {
                        audioTrack as Map<*, *> // Ensure right type.
                        audioTracks.add(LocalAudioTrack.create(this.applicationContext, audioTrack["enable"] as Boolean))
                    }
                    TwilioUnofficialProgrammableVideoPlugin.debug("TwilioUnofficialProgrammableVideoPlugin.connect => setting audioTracks to '${audioTracks.joinToString(", ")}'")
                    optionsBuilder.audioTracks(audioTracks)
                }

                // Set the local video tracks if it has been passed.
                if (optionsObj["videoTracks"] != null) {
                    val videoTrackOptions = optionsObj["videoTracks"] as Map<*, *>

                    val videoTracks = ArrayList<LocalVideoTrack?>()
                    for ((videoTrack) in videoTrackOptions) {
                        videoTrack as Map<*, *> // Ensure right type.

                        val videoCapturer: VideoCapturer = when (videoTrack["videoCapturer"] as String) {
                            "FRONT_CAMERA" -> CameraCapturer(this.applicationContext, CameraCapturer.CameraSource.FRONT_CAMERA)
                            "BACK_CAMERA" -> CameraCapturer(this.applicationContext, CameraCapturer.CameraSource.BACK_CAMERA)
                            else -> CameraCapturer(this.applicationContext, CameraCapturer.CameraSource.FRONT_CAMERA)
                        }
                        videoTracks.add(LocalVideoTrack.create(this.applicationContext, videoTrack["enable"] as Boolean, videoCapturer))
                    }
                    TwilioUnofficialProgrammableVideoPlugin.debug("TwilioUnofficialProgrammableVideoPlugin.connect => setting videoTracks to '${videoTracks.joinToString(", ")}'")
                    optionsBuilder.videoTracks(videoTracks)
                }

                val roomId = 1 // Future preparation, for when we might want to support multiple rooms.
                TwilioUnofficialProgrammableVideoPlugin.roomListener = RoomListener(roomId, optionsBuilder.build())
                result.success(roomId)
            } catch (e: Exception) {
                result.error("INIT_ERROR", e.toString(), e)
            }
        } else {
            result.error("INIT_ERROR", "Missing ConnectOptions", null)
        }
    }
}