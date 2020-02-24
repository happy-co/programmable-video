import Flutter
import UIKit
import TwilioVideo

public class SwiftTwilioProgrammableVideoPlugin: NSObject, FlutterPlugin {
    internal static var roomListener: RoomListener?

    internal static var remoteParticipantListener = RemoteParticipantListener()

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

    private var roomChannel: FlutterEventChannel?

    private var remoteParticipantChannel: FlutterEventChannel?

    private var loggingChannel: FlutterEventChannel?

    public func onRegister(_ registrar: FlutterPluginRegistrar) {
        let pluginHandler = PluginHandler()
        methodChannel = FlutterMethodChannel(name: "twilio_programmable_video", binaryMessenger: registrar.messenger())
        methodChannel?.setMethodCallHandler(pluginHandler.handle)

        roomChannel = FlutterEventChannel(name: "twilio_programmable_video/room", binaryMessenger: registrar.messenger())
        roomChannel?.setStreamHandler(RoomStreamHandler())

        remoteParticipantChannel = FlutterEventChannel(name: "twilio_programmable_video/remote", binaryMessenger: registrar.messenger())
        remoteParticipantChannel?.setStreamHandler(RemoteParticipantStreamHandler())

        loggingChannel = FlutterEventChannel(name: "twilio_programmable_video/logging", binaryMessenger: registrar.messenger())
        loggingChannel?.setStreamHandler(LoggingStreamHandler())

        let pvf = ParticipantViewFactory(pluginHandler)
        registrar.register(pvf, withId: "twilio_programmable_video/views")
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
}
