package twilio.flutter.twilio_programmable_video

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.twilio.video.Video
import com.twilio.video.VideoCapturer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformViewRegistry

/** TwilioProgrammableVideoPlugin */
class TwilioProgrammableVideoPlugin : FlutterPlugin {
    private lateinit var methodChannel: MethodChannel

    private lateinit var cameraChannel: EventChannel

    private lateinit var roomChannel: EventChannel

    private lateinit var remoteParticipantChannel: EventChannel

    private lateinit var localParticipantChannel: EventChannel

    private lateinit var loggingChannel: EventChannel

    private lateinit var remoteDataTrackChannel: EventChannel

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        @Suppress("unused")
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val instance = TwilioProgrammableVideoPlugin()
            instance.onAttachedToEngine(registrar.context(), registrar.messenger(), registrar.platformViewRegistry())
        }

        @JvmStatic
        val LOG_TAG = "Twilio_PVideo"

        @JvmStatic
        val HARDWARE_AEC_BLACKLIST = hashSetOf(
                "Pixel",
                "Pixel 2",
                "Pixel XL",
                "Moto G5",
                "Moto G (5S) Plus",
                "Moto G4",
                "TA-1053",
                "Mi A1",
                "Mi A2",
                "E5823", // Sony z5 compact
                "Redmi Note 5",
                "FP2", // Fairphone FP2
                "MI 5"
        )

        lateinit var pluginHandler: PluginHandler

        lateinit var roomListener: RoomListener

        lateinit var cameraCapturer: VideoCapturer

        var loggingSink: EventChannel.EventSink? = null

        var remoteParticipantListener = RemoteParticipantListener()

        var localParticipantListener = LocalParticipantListener()

        var handler = Handler(Looper.getMainLooper())

        var nativeDebug: Boolean = false

        var remoteDataTrackListener = RemoteDataTrackListener()

        @JvmStatic
        fun debug(msg: String) {
            if (nativeDebug) {
                Log.d(LOG_TAG, msg)
                handler.post {
                    loggingSink?.success(msg)
                }
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(binding.applicationContext, binding.binaryMessenger, binding.platformViewRegistry)
    }

    private fun onAttachedToEngine(applicationContext: Context, messenger: BinaryMessenger, platformViewRegistry: PlatformViewRegistry) {
        pluginHandler = PluginHandler(applicationContext)
        methodChannel = MethodChannel(messenger, "twilio_programmable_video")
        methodChannel.setMethodCallHandler(pluginHandler)

        cameraChannel = EventChannel(messenger, "twilio_programmable_video/camera")
        cameraChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => Camera eventChannel attached")
                pluginHandler.events = events
            }

            override fun onCancel(arguments: Any?) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => Camera eventChannel detached")
                pluginHandler.events = null
            }
        })

        roomChannel = EventChannel(messenger, "twilio_programmable_video/room")
        roomChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => Room eventChannel attached")
                roomListener.events = events
                roomListener.room = Video.connect(applicationContext, roomListener.connectOptions, roomListener)
            }

            override fun onCancel(arguments: Any) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => Room eventChannel detached")
                roomListener.events = null
            }
        })

        remoteParticipantChannel = EventChannel(messenger, "twilio_programmable_video/remote")
        remoteParticipantChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => RemoteParticipant eventChannel attached")
                remoteParticipantListener.events = events
            }

            override fun onCancel(arguments: Any) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => RemoteParticipant eventChannel detached")
                remoteParticipantListener.events = null
            }
        })

        localParticipantChannel = EventChannel(messenger, "twilio_programmable_video/local")
        localParticipantChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => LocalParticipant eventChannel attached")
                localParticipantListener.events = events
            }

            override fun onCancel(arguments: Any) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => LocalParticipant eventChannel detached")
                localParticipantListener.events = null
            }
        })

        loggingChannel = EventChannel(messenger, "twilio_programmable_video/logging")
        loggingChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => Logging eventChannel attached")
                loggingSink = events
            }

            override fun onCancel(arguments: Any) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => Logging eventChannel detached")
                loggingSink = null
            }
        })

        remoteDataTrackChannel = EventChannel(messenger, "twilio_programmable_video/remote_data_track")
        remoteDataTrackChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => RemoteDataTrack eventChannel attached")
                remoteDataTrackListener.events = events
            }

            override fun onCancel(arguments: Any) {
                debug("TwilioProgrammableVideoPlugin.onAttachedToEngine => RemoteDataTrack eventChannel detached")
                remoteDataTrackListener.events = null
            }
        })

        val pvf = ParticipantViewFactory(StandardMessageCodec.INSTANCE, pluginHandler)
        platformViewRegistry.registerViewFactory("twilio_programmable_video/views", pvf)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        roomChannel.setStreamHandler(null)
        remoteParticipantChannel.setStreamHandler(null)
        loggingChannel.setStreamHandler(null)
        remoteDataTrackChannel.setStreamHandler(null)
        localParticipantChannel.setStreamHandler(null)
    }
}
