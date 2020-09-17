import Flutter
import UIKit
import TwilioVideo

public class SwiftTwilioProgrammableVideoPlugin: NSObject, FlutterPlugin {
    static var pluginHandler: PluginHandler = PluginHandler()

    internal static var roomListener: RoomListener?

    internal static var remoteParticipantListener = RemoteParticipantListener()

    internal static var localParticipantListener = LocalParticipantListener()

    internal static var remoteDataTrackListener = RemoteDataTrackListener()

    public static var cameraSource: CameraSource?

    public static var loggingSink: FlutterEventSink?

    public static var audioDevice: AudioDevice?

    public static var nativeDebug = false

    public static func debug(_ msg: String) {
        if SwiftTwilioProgrammableVideoPlugin.nativeDebug {
            NSLog(msg)
            guard let loggingSink = loggingSink else {
                return
            }
            loggingSink(msg)
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftTwilioProgrammableVideoPlugin()
        instance.onRegister(registrar)
    }

    private var methodChannel: FlutterMethodChannel?

    private var cameraChannel: FlutterEventChannel?

    private var roomChannel: FlutterEventChannel?

    private var remoteParticipantChannel: FlutterEventChannel?

    private var localParticipantChannel: FlutterEventChannel?

    private var loggingChannel: FlutterEventChannel?

    private var remoteDataTrackChannel: FlutterEventChannel?

    public func onRegister(_ registrar: FlutterPluginRegistrar) {
        methodChannel = FlutterMethodChannel(name: "twilio_programmable_video", binaryMessenger: registrar.messenger())
        methodChannel?.setMethodCallHandler(SwiftTwilioProgrammableVideoPlugin.pluginHandler.handle)

        cameraChannel = FlutterEventChannel(name: "twilio_programmable_video/camera", binaryMessenger: registrar.messenger())
        cameraChannel?.setStreamHandler(CameraStreamHandler())

        roomChannel = FlutterEventChannel(name: "twilio_programmable_video/room", binaryMessenger: registrar.messenger())
        roomChannel?.setStreamHandler(RoomStreamHandler())

        remoteParticipantChannel = FlutterEventChannel(name: "twilio_programmable_video/remote", binaryMessenger: registrar.messenger())
        remoteParticipantChannel?.setStreamHandler(RemoteParticipantStreamHandler())

        localParticipantChannel = FlutterEventChannel(name: "twilio_programmable_video/local", binaryMessenger: registrar.messenger())
        localParticipantChannel?.setStreamHandler(LocalParticipantStreamHandler())

        loggingChannel = FlutterEventChannel(name: "twilio_programmable_video/logging", binaryMessenger: registrar.messenger())
        loggingChannel?.setStreamHandler(LoggingStreamHandler())

        remoteDataTrackChannel = FlutterEventChannel(name: "twilio_programmable_video/remote_data_track", binaryMessenger: registrar.messenger())
        remoteDataTrackChannel?.setStreamHandler(RemoteDataTrackStreamHandler())

        let pvf = ParticipantViewFactory(SwiftTwilioProgrammableVideoPlugin.pluginHandler)
        registrar.register(pvf, withId: "twilio_programmable_video/views")
    }

    class CameraStreamHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("CameraStreamHandler.onListen => Camera eventChannel attached")
            pluginHandler.events = events
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("CameraStreamHandler.onCancel => Camera eventChannel detached")
            pluginHandler.events = nil
            return nil
        }
    }

    class RoomStreamHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            guard let roomListener = SwiftTwilioProgrammableVideoPlugin.roomListener else { return nil }
            SwiftTwilioProgrammableVideoPlugin.debug("RoomStreamHandler.onListen => Room eventChannel attached")
            roomListener.events = events
            roomListener.room = TwilioVideoSDK.connect(options: roomListener.connectOptions, delegate: roomListener)
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("RoomStreamHandler.onCancel => Room eventChannel detached")
            guard let roomListener = SwiftTwilioProgrammableVideoPlugin.roomListener else { return nil }
            roomListener.events = nil
            return nil
        }
    }

    class RemoteParticipantStreamHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("RemoteParticipantStreamHandler.onListen => RemoteParticipant eventChannel attached")
            SwiftTwilioProgrammableVideoPlugin.remoteParticipantListener.events = events
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("RemoteParticipantStreamHandler.onCancel => RemoteParticipant eventChannel detached")
            SwiftTwilioProgrammableVideoPlugin.remoteParticipantListener.events = nil
            return nil
        }
    }

    class LocalParticipantStreamHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("LocalParticipantStreamHandler.onListen => LocalParticipant eventChannel attached")
            SwiftTwilioProgrammableVideoPlugin.localParticipantListener.events = events
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("LocalParticipantStreamHandler.onCancel => LocalParticipant eventChannel detached")
            SwiftTwilioProgrammableVideoPlugin.localParticipantListener.events = nil
            return nil
        }
    }

    class LoggingStreamHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("LoggingStreamHandler.onListen => Logging eventChannel attached")
            SwiftTwilioProgrammableVideoPlugin.loggingSink = events
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("LoggingStreamHandler.onCancel => Logging eventChannel detached")
            SwiftTwilioProgrammableVideoPlugin.loggingSink = nil
            return nil
        }
    }

    class RemoteDataTrackStreamHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("RemoteDataTrackStreamHandler.onListen => RemoteDataTrack eventChannel attached")
            SwiftTwilioProgrammableVideoPlugin.remoteDataTrackListener.events = events
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            SwiftTwilioProgrammableVideoPlugin.debug("RemoteDataTrackStreamHandler.onCancel => RemoteDataTrack eventChannel detached")
            SwiftTwilioProgrammableVideoPlugin.remoteDataTrackListener.events = nil
            return nil
        }
    }
}
