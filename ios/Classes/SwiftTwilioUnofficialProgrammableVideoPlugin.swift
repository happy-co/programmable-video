import Flutter
import UIKit

public class SwiftTwilioUnofficialProgrammableVideoPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "twilio_unofficial_programmable_video", binaryMessenger: registrar.messenger())
    let instance = SwiftTwilioUnofficialProgrammableVideoPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
