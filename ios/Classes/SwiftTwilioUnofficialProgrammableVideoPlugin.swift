import Flutter
import UIKit
import TwilioVideo

public class SwiftTwilioUnofficialProgrammableVideoPlugin: NSObject, FlutterPlugin {
    internal static var roomListener: RoomListener?

    internal static var remoteParticipantListener = RemoteParticipantListener()

    public static var cameraSource: CameraSource?

    public static var loggingSink: FlutterEventSink?

    public static var audioDevice: AudioDevice?

    public static var nativeDebug = false

    public static func debug(_ msg: String) {
        if SwiftTwilioUnofficialProgrammableVideoPlugin.nativeDebug {
            NSLog(msg)
            guard let loggingSink = loggingSink else {
                return
            }
            loggingSink(msg)
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftTwilioUnofficialProgrammableVideoPlugin()
        instance.onRegister(registrar)
    }

    private var methodChannel: FlutterMethodChannel?

    private var roomChannel: FlutterEventChannel?

    private var remoteParticipantChannel: FlutterEventChannel?

    private var loggingChannel: FlutterEventChannel?

    public func onRegister(_ registrar: FlutterPluginRegistrar) {
        let pluginHandler = PluginHandler()
        methodChannel = FlutterMethodChannel(name: "twilio_unofficial_programmable_video", binaryMessenger: registrar.messenger())
        methodChannel?.setMethodCallHandler(pluginHandler.handle)

        roomChannel = FlutterEventChannel(name: "twilio_unofficial_programmable_video/room", binaryMessenger: registrar.messenger())
        roomChannel?.setStreamHandler(RoomStreamHandler())

        remoteParticipantChannel = FlutterEventChannel(name: "twilio_unofficial_programmable_video/remote", binaryMessenger: registrar.messenger())
        remoteParticipantChannel?.setStreamHandler(RemoteParticipantStreamHandler())

        loggingChannel = FlutterEventChannel(name: "twilio_unofficial_programmable_video/logging", binaryMessenger: registrar.messenger())
        loggingChannel?.setStreamHandler(LoggingStreamHandler())

        let pvf = ParticipantViewFactory(pluginHandler)
        registrar.register(pvf, withId: "twilio_unofficial_programmable_video/views")
    }

    class RoomStreamHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            guard let roomListener = SwiftTwilioUnofficialProgrammableVideoPlugin.roomListener else { return nil }
            SwiftTwilioUnofficialProgrammableVideoPlugin.debug("RoomStreamHandler.onListen => Room eventChannel attached")
            roomListener.events = events
            roomListener.room = TwilioVideoSDK.connect(options: roomListener.connectOptions, delegate: roomListener)
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            SwiftTwilioUnofficialProgrammableVideoPlugin.debug("RoomStreamHandler.onCancel => Room eventChannel detached")
            guard let roomListener = SwiftTwilioUnofficialProgrammableVideoPlugin.roomListener else { return nil }
            roomListener.events = nil
            return nil
        }
    }

    class RemoteParticipantStreamHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            SwiftTwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantStreamHandler.onListen => RemoteParticipant eventChannel attached")
            SwiftTwilioUnofficialProgrammableVideoPlugin.remoteParticipantListener.events = events
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            SwiftTwilioUnofficialProgrammableVideoPlugin.debug("RemoteParticipantStreamHandler.onCancel => RemoteParticipant eventChannel detached")
            SwiftTwilioUnofficialProgrammableVideoPlugin.remoteParticipantListener.events = nil
            return nil
        }
    }

    class LoggingStreamHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            SwiftTwilioUnofficialProgrammableVideoPlugin.debug("LoggingStreamHandler.onListen => Logging eventChannel attached")
            SwiftTwilioUnofficialProgrammableVideoPlugin.loggingSink = events
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            SwiftTwilioUnofficialProgrammableVideoPlugin.debug("LoggingStreamHandler.onCancel => Logging eventChannel detached")
            SwiftTwilioUnofficialProgrammableVideoPlugin.loggingSink = nil
            return nil
        }
    }
}
