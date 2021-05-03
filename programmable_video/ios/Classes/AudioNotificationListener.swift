import Flutter
import Foundation
import TwilioVideo

internal class AudioNotificationListener: BaseListener {
    internal func listenForRouteChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    internal func stopListeningForRouteChanges() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleRouteChange(notification: NSNotification) {
        SwiftTwilioProgrammableVideoPlugin.debug("AudioNotificationListener::handleRouteChange => notification: \(notification)")
        // Check if the sample rate, or channels changed and trigger a format change if it did.
        guard let userInfo = notification.userInfo,
              let reasonRaw = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw) else {
            SwiftTwilioProgrammableVideoPlugin.debug("AudioNotificationListener::handleRouteChange => parse error")
            return
        }
        
        let bluetoothConnected = bluetoothAudioConnected()
        
        SwiftTwilioProgrammableVideoPlugin.debug("AudioNotificationListener::handleRouteChange => reason: \(reason.rawValue), category: \(AVAudioSession.sharedInstance().category)")

        switch reason {
            case AVAudioSession.RouteChangeReason.unknown,
                 AVAudioSession.RouteChangeReason.override,
                 AVAudioSession.RouteChangeReason.wakeFromSleep,
                 AVAudioSession.RouteChangeReason.noSuitableRouteForCategory,
                 AVAudioSession.RouteChangeReason.categoryChange,
                 // In iOS 9.2+ switching routes from a BT device in control center may cause a category change.
                 AVAudioSession.RouteChangeReason.routeConfigurationChange:
                SwiftTwilioProgrammableVideoPlugin.debug("category: \(AVAudioSession.sharedInstance().category)")
            // Each device change might cause the actual sample rate or channel configuration of the session to change.
            case AVAudioSession.RouteChangeReason.newDeviceAvailable:
                let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
                SwiftTwilioProgrammableVideoPlugin.debug("newDeviceAvailable: \(previousRoute), bluetoothConnected: \(bluetoothConnected)")
                sendEvent("newDeviceAvailable", data: nil, error: nil)
            case AVAudioSession.RouteChangeReason.oldDeviceUnavailable:
                let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
                SwiftTwilioProgrammableVideoPlugin.debug("oldDeviceUnavailable: \(previousRoute), bluetoothConnected: \(bluetoothConnected)")
                sendEvent("oldDeviceUnavailable", data: nil, error: nil)
            default:
                SwiftTwilioProgrammableVideoPlugin.debug("default")
                break
        }

    }
    
    func bluetoothAudioConnected() -> Bool {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        return outputs.filter( {
            $0.portType == .bluetoothA2DP ||
            $0.portType == .bluetoothHFP ||
            $0.portType == .bluetoothLE
        }).isEmpty
    }
}
