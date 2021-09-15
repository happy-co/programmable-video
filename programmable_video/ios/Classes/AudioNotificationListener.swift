// swiftlint:disable notification_center_detachment
import Flutter
import Foundation
import TwilioVideo

internal class AudioNotificationListener: BaseListener {
    internal func listenForRouteChanges() {
        stopListeningForRouteChanges()
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }

    internal func stopListeningForRouteChanges() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleRouteChange(notification: NSNotification) {
        debug("AudioNotificationListener::handleRouteChange => notification: \(notification)")
        // Check if the sample rate, or channels changed and trigger a format change if it did.
        guard let userInfo = notification.userInfo,
              let reasonRaw = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw) else {
            debug("AudioNotificationListener::handleRouteChange => parse error")
            return
        }

        let bluetoothConnected = bluetoothAudioConnected()

        debug("AudioNotificationListener::handleRouteChange => reason: \(reason.rawValue), category: \(AVAudioSession.sharedInstance().category)")

        switch reason {
            case AVAudioSession.RouteChangeReason.unknown,
                 AVAudioSession.RouteChangeReason.override,
                 AVAudioSession.RouteChangeReason.wakeFromSleep,
                 AVAudioSession.RouteChangeReason.noSuitableRouteForCategory,
                 AVAudioSession.RouteChangeReason.categoryChange,
                 // In iOS 9.2+ switching routes from a BT device in control center may cause a category change.
                 AVAudioSession.RouteChangeReason.routeConfigurationChange:
                debug("category: \(AVAudioSession.sharedInstance().category)")
            // Each device change might cause the actual sample rate or channel configuration of the session to change.
            case AVAudioSession.RouteChangeReason.newDeviceAvailable:
                let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
                let newRouteName = AVAudioSession.sharedInstance().currentRoute.outputs.first?.portName as? String

                // iOS Devices don't typically have ports to support wired headsets
                // but, for the sake of consistency across platforms we will include both keys
                let eventData = ["connected": bluetoothConnected, "bluetooth": true, "wired": false, "deviceName": newRouteName] as [String: Any]
                debug("newDeviceAvailable => \n\tcurrentRoute: \(AVAudioSession.sharedInstance().currentRoute)\n\tpreviousRoute: \(previousRoute),\n\tbluetoothConnected: \(bluetoothConnected)")
                debug("\tavailableInputs: \(AVAudioSession.sharedInstance().availableInputs)")
                sendEvent("newDeviceAvailable", data: eventData, error: nil)
            case AVAudioSession.RouteChangeReason.oldDeviceUnavailable:
                let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
                let previousRouteName = (previousRoute as? AVAudioSessionRouteDescription)?.outputs.first?.portName as? String
                let eventData = ["connected": bluetoothConnected, "bluetooth": true, "wired": false, "deviceName": previousRouteName] as [String: Any]
                debug("oldDeviceUnavailable => \n\tcurrentRoute: \(AVAudioSession.sharedInstance().currentRoute)\n\tpreviousRoute: \(previousRoute),\n\tbluetoothConnected: \(bluetoothConnected)")
                sendEvent("oldDeviceUnavailable", data: eventData, error: nil)
            default:
                debug("default")
        }
    }

    func bluetoothAudioConnected() -> Bool {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        return !outputs.filter({
            $0.portType == .bluetoothA2DP ||
            $0.portType == .bluetoothHFP ||
            $0.portType == .bluetoothLE
        }).isEmpty
    }

    func debug(_ msg: String) {
        SwiftTwilioProgrammableVideoPlugin.debugAudio(msg)
    }
}
