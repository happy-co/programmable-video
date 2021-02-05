// swiftlint:disable type_body_length
// swiftlint:disable file_length
import Flutter
import Foundation
import TwilioVideo

public class PluginHandler: BaseListener {
    public func getRemoteParticipant(_ sid: String) -> RemoteParticipant? {
        return SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.remoteParticipants.first(where: {$0.sid == sid})
    }

    public func getLocalParticipant() -> LocalParticipant? {
        return SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.localParticipant
    }

    // swiftlint:disable:next cyclomatic_complexity
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.handle => received \(call.method)")
        switch call.method {
        case "debug":
            debug(call, result: result)
        case "connect":
            connect(call, result: result)
        case "disconnect":
            disconnect(call, result: result)
        case "setSpeakerphoneOn":
            setSpeakerphoneOn(call, result: result)
        case "getSpeakerphoneOn":
            getSpeakerphoneOn(result: result)
        case "LocalAudioTrack#enable":
            localAudioTrackEnable(call, result: result)
        case "LocalDataTrack#sendString":
            localDataTrackSendString(call, result: result)
        case "LocalDataTrack#sendByteBuffer":
            localDataTrackSendByteBuffer(call, result: result)
        case "LocalVideoTrack#enable":
            localVideoTrackEnable(call, result: result)
        case "RemoteAudioTrack#enablePlayback":
            remoteAudioTrackEnable(call, result: result)
        case "RemoteAudioTrack#isPlaybackEnabled":
            isRemoteAudioTrackPlaybackEnabled(call, result: result)
        case "CameraCapturer#switchCamera":
            switchCamera(call, result: result)
        case "CameraCapturer#hasTorch":
            hasTorch(result: result)
        case "CameraCapturer#setTorch":
            setTorch(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func switchCamera(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.switchCamera => called")
        if let cameraSource = SwiftTwilioProgrammableVideoPlugin.cameraSource {
            var captureDevice: AVCaptureDevice?
            switch cameraSource.device?.position {
            case .back:
                captureDevice = CameraSource.captureDevice(position: .front)
            default: // or .front
                captureDevice = CameraSource.captureDevice(position: .back)
            }

            if let captureDevice = captureDevice {
                cameraSource.selectCaptureDevice(captureDevice, completion: { (_, _, error) in
                    if let error = error {
                        self.sendEvent("cameraError", data: ["capturer": self.videoSourceToDict(SwiftTwilioProgrammableVideoPlugin.cameraSource, newCameraSource: nil)], error: error)
                    } else {
                        self.sendEvent("cameraSwitched", data: ["capturer": self.videoSourceToDict(SwiftTwilioProgrammableVideoPlugin.cameraSource, newCameraSource: captureDevice.position)], error: nil)
                    }
                })
                return result(videoSourceToDict(cameraSource, newCameraSource: captureDevice.position))
            } else {
                return result(FlutterError(code: "MISSING_CAMERA", message: "Could not find another camera to switch to", details: nil))
            }
        } else {
            return result(FlutterError(code: "NOT_FOUND", message: "No CameraCapturer has been initialized yet, try connecting first.", details: nil))
        }
    }

    private func hasTorch(result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.hasTorch => called")
        guard let captureDevice = SwiftTwilioProgrammableVideoPlugin.cameraSource?.device else {
            return result(false)
        }

        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.hasTorch => device: \(captureDevice.uniqueID) hasTorch: \(captureDevice.hasTorch)")
        return result(captureDevice.hasTorch)
    }

    private func setTorch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.setTorch => called")
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'enable' parameters", details: nil))
        }

        guard let enableTorch = arguments["enable"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'enable' parameter", details: nil))
        }

        do {
            guard let captureDevice = SwiftTwilioProgrammableVideoPlugin.cameraSource?.device else {
                return result(FlutterError(code: "NOT_FOUND", message: "No camera source found", details: nil))
            }

            if !captureDevice.hasTorch {
                return result(FlutterError(code: "NOT_FOUND", message: "Camera source found does not have a torch", details: nil))
            }

            try captureDevice.lockForConfiguration()

            if enableTorch {
                try captureDevice.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            } else {
                captureDevice.torchMode = AVCaptureDevice.TorchMode.off
            }

            captureDevice.unlockForConfiguration()
            return result(nil)
        } catch let error as NSError {
            return result(FlutterError(code: "\(error.code)", message: error.description, details: nil))
        }
    }

    private func localVideoTrackEnable(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' and 'enable' parameters", details: nil))
        }

        guard let localVideoTrackName = arguments["name"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' parameter", details: nil))
        }

        guard let localVideoTrackEnable = arguments["enable"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'enable' parameter", details: nil))
        }

        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.localVideoTrackEnable => called for \(localVideoTrackName), enable=\(localVideoTrackEnable)")

        let localVideoTrack = getLocalParticipant()?.localVideoTracks.first(where: {$0.trackName == localVideoTrackName})
        if let localVideoTrack = localVideoTrack {
            localVideoTrack.localTrack?.isEnabled = localVideoTrackEnable
            return result(nil)
        }
        return result(FlutterError(code: "NOT_FOUND", message: "No LocalVideoTrack found with the name '\(localVideoTrackName)'", details: nil))
    }

    private func localAudioTrackEnable(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' and 'enable' parameters", details: nil))
        }

        guard let localAudioTrackName = arguments["name"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' parameter", details: nil))
        }

        guard let localAudioTrackEnable = arguments["enable"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'enable' parameter", details: nil))
        }

        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.localAudioTrackEnable => called for \(localAudioTrackName), enable=\(localAudioTrackEnable)")

        let localAudioTrack = getLocalParticipant()?.localAudioTracks.first(where: {$0.trackName == localAudioTrackName})
        if let localAudioTrack = localAudioTrack {
            localAudioTrack.localTrack?.isEnabled = localAudioTrackEnable
            return result(nil)
        }
        return result(FlutterError(code: "NOT_FOUND", message: "No LocalAudioTrack found with the name '\(localAudioTrackName)'", details: nil))
    }

    private func remoteAudioTrackEnable(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' and 'enable' parameters", details: nil))
        }

        guard let remoteAudioTrackSid = arguments["sid"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'sid' parameter", details: nil))
        }

        guard let remoteAudioTrackEnable = arguments["enable"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'enable' parameter", details: nil))
        }

        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.remoteAudioTrackEnable => called for \(remoteAudioTrackSid), enable=\(remoteAudioTrackEnable)")

        guard let remoteAudioTrack = getRemoteAudioTrack(remoteAudioTrackSid) else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'enable' parameter", details: nil))
        }

        remoteAudioTrack.remoteTrack?.isPlaybackEnabled = remoteAudioTrackEnable
        return result(nil)
    }

    private func isRemoteAudioTrackPlaybackEnabled(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' and 'enable' parameters", details: nil))
        }

        guard let remoteAudioTrackSid = arguments["sid"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'sid' parameter", details: nil))
        }

        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.isRemoteAudioTrackPlaybackEnabled => called for \(remoteAudioTrackSid)")

        guard let remoteAudioTrack = getRemoteAudioTrack(remoteAudioTrackSid) else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'enable' parameter", details: nil))
        }

        return result(remoteAudioTrack.remoteTrack?.isPlaybackEnabled)
    }

    private func getRemoteAudioTrack(_ sid: String) -> RemoteAudioTrackPublication? {
        guard let remoteParticipants = SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.remoteParticipants else {
            return nil
        }
        var remoteAudioTrack: RemoteAudioTrackPublication?
        for remoteParticipant in remoteParticipants {
            remoteAudioTrack = remoteParticipant.remoteAudioTracks.first(where: { $0.remoteTrack?.sid == sid })
            if remoteAudioTrack != nil {
                return remoteAudioTrack
            }
        }
        return nil
    }

    private func localDataTrackSendString(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' and 'message' parameters", details: nil))
        }

        guard let localDataTrackName = arguments["name"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' parameter", details: nil))
        }

        guard let localDataTrackMessage = arguments["message"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'message' parameter", details: nil))
        }

        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.localDataTrackSendString => called for \(localDataTrackName)")

        let localDataTrack = getLocalParticipant()?.localDataTracks.first(where: {$0.trackName == localDataTrackName})
        if let localDataTrack = localDataTrack {
            localDataTrack.localTrack?.send(localDataTrackMessage)
            return result(true)
        }
        return result(FlutterError(code: "NOT_FOUND", message: "No LocalDataTrack found with the name '\(localDataTrackName)'", details: nil))
    }

    private func localDataTrackSendByteBuffer(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' and 'message' parameters", details: nil))
        }

        guard let localDataTrackName = arguments["name"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' parameter", details: nil))
        }

        guard let localDataTrackMessage = arguments["message"] as? FlutterStandardTypedData else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'message' parameter", details: nil))
        }

        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.localDataTrackSendString => called for \(localDataTrackName)")

        let localDataTrack = getLocalParticipant()?.localDataTracks.first(where: {$0.trackName == localDataTrackName})
        if let localDataTrack = localDataTrack {
            localDataTrack.localTrack?.send(localDataTrackMessage.data)
            return result(true)
        }
        return result(FlutterError(code: "NOT_FOUND", message: "No LocalDataTrack found with the name '\(localDataTrackName)'", details: nil))
    }

    private func setSpeakerphoneOn(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.setSpeakerphoneOn => called")
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'on' parameter", details: nil))
        }

        guard let on = arguments["on"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'on' parameter", details: nil))
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try on ? audioSession.setMode(.videoChat) : audioSession.setMode(.voiceChat)
            return result(on)
        } catch let error as NSError {
            return result(FlutterError(code: "\(error.code)", message: error.description, details: nil))
        }
    }

    private func getSpeakerphoneOn(result: @escaping FlutterResult) {
        let speakerPhoneOn = AVAudioSession.sharedInstance().mode == .videoChat
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.getSpeakerphoneOn => called \(speakerPhoneOn)")
        return result(speakerPhoneOn)
    }

    private func disconnect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.disconnect => called")
        SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.disconnect()

        if let camera = SwiftTwilioProgrammableVideoPlugin.cameraSource {
            camera.stopCapture()
            SwiftTwilioProgrammableVideoPlugin.cameraSource = nil
        }

        result(true)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func connect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => called")
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'connectOpotions' parameter", details: nil))
        }

        guard let optionsObj = arguments["connectOptions"] as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'connectOptions' parameter", details: nil))
        }

        guard let accessToken = optionsObj["accessToken"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'accessToken' parameter", details: nil))
        }

        // Override the device before creating any Rooms or Tracks.
        if SwiftTwilioProgrammableVideoPlugin.audioDevice == nil {
            SwiftTwilioProgrammableVideoPlugin.audioDevice = DefaultAudioDevice()
            DefaultAudioDevice.DefaultAVAudioSessionConfigurationBlock()
        }
        TwilioVideoSDK.audioDevice = SwiftTwilioProgrammableVideoPlugin.audioDevice!

        let connectOptions = ConnectOptions(token: accessToken) { (builder) in
            // Set the room name if it has been passed.
            if let roomName = optionsObj["roomName"] as? String {
                SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting roomName to '\(roomName)'")
                builder.roomName = roomName
            }

            // Set the region if it has been passed.
            if let region = optionsObj["region"] as? String {
                SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting region to '\(region)'")
                builder.region = region
            }

            // Set the preferred audio codecs if it has been passed.
            if let preferredAudioCodecs = optionsObj["preferredAudioCodecs"] as? [String: String] {
                var audioCodecs: [AudioCodec] = []
                for (_, audioCodec) in preferredAudioCodecs {
                    switch audioCodec {
                    case "isac":
                        audioCodecs.append(IsacCodec())
                    case "PCMA":
                        audioCodecs.append(PcmaCodec())
                    case "PCMU":
                        audioCodecs.append(PcmuCodec())
                    case "G722":
                        audioCodecs.append(G722Codec())
                    default: // or opus
                        audioCodecs.append(OpusCodec())
                    }
                }
                SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting preferredAudioCodecs to '\(audioCodecs)'")
                builder.preferredAudioCodecs = audioCodecs
            }

            // Set the preferred video codecs if it has been passed.
            if let preferredVideoCodecs = optionsObj["preferredVideoCodecs"] as? [String: String] {
                var videoCodecs: [VideoCodec] = []
                for (_, videoCodec) in preferredVideoCodecs {
                    switch videoCodec {
                    case "VP9":
                        videoCodecs.append(Vp9Codec())
                    case "H264":
                        videoCodecs.append(H264Codec())
                    default: // or VP8
                        videoCodecs.append(Vp8Codec())
                    }
                }
                SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting preferredVideoCodecs to '\(videoCodecs)'")
                builder.preferredVideoCodecs = videoCodecs
            }

            // Set the local audio tracks if it has been passed.
            if let audioTrackOptions = optionsObj["audioTracks"] as? [AnyHashable: [String: Any]] {
                var audioTracks: [LocalAudioTrack] = []
                for (_, audioTrack) in audioTrackOptions {
                    let enable = audioTrack["enable"] as? Bool
                    let name = audioTrack["name"] as? String
                    audioTracks.append(LocalAudioTrack(options: nil, enabled: enable ?? true, name: name ?? nil)!)
                }
                SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting audioTracks to '\(audioTracks)'")
                builder.audioTracks = audioTracks
            }

            // Set the local data tracks if it has been passed.
            if let dataTracksDict = optionsObj["dataTracks"] as? [AnyHashable: [String: Any]] {
                var dataTracks: [LocalDataTrack] = []
                for (_, dataTrack) in dataTracksDict {
                    if let dataTrackOptionsDict = dataTrack["dataTrackOptions"] as? [AnyHashable: Any] {
                        let dataTrackOptions = DataTrackOptions { (builder) in
                            if let ordered = dataTrackOptionsDict["ordered"] as? Bool {
                                builder.isOrdered = ordered
                            }
                            if let maxPacketLifeTime = dataTrackOptionsDict["maxPacketLifeTime"] as? Int32 {
                                builder.maxPacketLifeTime = maxPacketLifeTime
                            }
                            if let maxRetransmits = dataTrackOptionsDict["maxRetransmits"] as? Int32 {
                                builder.maxRetransmits = maxRetransmits
                            }
                            if let name = dataTrackOptionsDict["name"] as? String {
                                builder.name = name
                            }
                        }
                        dataTracks.append(LocalDataTrack(options: dataTrackOptions)!)
                    } else {
                        dataTracks.append(LocalDataTrack()!)
                    }
                }
                SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting dataTracks to '\(dataTracks)'")
                builder.dataTracks = dataTracks
            }

            // Set the local video tracks if it has been passed.
            if let videoTrackOptions = optionsObj["videoTracks"] as? [AnyHashable: [String: Any]] {
                var videoTracks: [LocalVideoTrack] = []
                for (_, videoTrack) in videoTrackOptions {
                    let enable = videoTrack["enable"] as? Bool
                    let name = videoTrack["name"] as? String

                    let videoCapturer = videoTrack["videoCapturer"] as? [String: Any]
                    let videoSourceType = videoCapturer?["type"] as? String

                    switch videoSourceType {
                    default: // or CameraCapturer
                        let cameraSource = videoCapturer?["cameraSource"] as? String
                        let cameraDeviceRequested: AVCaptureDevice? = cameraSource == "BACK_CAMERA" ?
                            CameraSource.captureDevice(position: .back) :
                            CameraSource.captureDevice(position: .front)

                        guard let cameraDevice = cameraDeviceRequested else {
                            return result(FlutterError(code: "MISSING_CAMERA", message: "No camera found for \(videoCapturer?["cameraSource"] ?? "FRONT_CAMERA")", details: nil))
                        }

                        let videoSource = CameraSource()!
                        let localVideoTrack = LocalVideoTrack(source: videoSource, enabled: enable ?? true, name: name ?? nil)!

                        videoSource.startCapture(device: cameraDevice) { (device: AVCaptureDevice, _: VideoFormat, error: Error?) in
                            if let error = error {
                                self.sendEvent("cameraError", data: ["capturer": self.videoSourceToDict(SwiftTwilioProgrammableVideoPlugin.cameraSource, newCameraSource: nil)], error: error)
                            } else {
                                self.sendEvent("firstFrameAvailable", data: ["capturer": self.videoSourceToDict(SwiftTwilioProgrammableVideoPlugin.cameraSource, newCameraSource: device.position)], error: nil)
                            }
                        }
                        videoTracks.append(localVideoTrack)
                        SwiftTwilioProgrammableVideoPlugin.cameraSource = videoSource
                    }
                }
                SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting videoTracks to '\(videoTracks)'")
                builder.videoTracks = videoTracks
            }

            if let isNetworkQualityEnabled = optionsObj["enableNetworkQuality"] as? Bool {
                SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting enableNetworkQuality to '\(isNetworkQualityEnabled)'")
                builder.isNetworkQualityEnabled = isNetworkQualityEnabled

                if let networkQualityConfigurationMap = optionsObj["networkQualityConfiguration"] as? [AnyHashable: Any],
                   let localConfig = networkQualityConfigurationMap["local"] as? String,
                   let remoteConfig = networkQualityConfigurationMap["remote"] as? String {
                        let local = self.getNetworkQualityVerbosity(verbosity: localConfig)
                        let remote = self.getNetworkQualityVerbosity(verbosity: remoteConfig)
                        builder.networkQualityConfiguration = NetworkQualityConfiguration(localVerbosity: local, remoteVerbosity: remote)
                }
            }

            builder.isDominantSpeakerEnabled = optionsObj["enableDominantSpeaker"] as? Bool ?? false
            builder.isAutomaticSubscriptionEnabled = optionsObj["enableAutomaticSubscription"] as? Bool ?? true
        }

        let roomId = 1
        SwiftTwilioProgrammableVideoPlugin.roomListener = RoomListener(roomId, connectOptions)
        result(roomId)
    }

    private func getNetworkQualityVerbosity(verbosity: String) -> NetworkQualityVerbosity {
        switch verbosity {
            case "NETWORK_QUALITY_VERBOSITY_NONE":
                return NetworkQualityVerbosity.none
            case "NETWORK_QUALITY_VERBOSITY_MINIMAL":
                return NetworkQualityVerbosity.minimal
            default:
                return NetworkQualityVerbosity.none
        }
    }

    func videoSourceToDict(_ videoSource: VideoSource?, newCameraSource: AVCaptureDevice.Position?) -> [String: Any] {
        if let cameraSource = videoSource as? CameraSource {
            let source: AVCaptureDevice.Position? = newCameraSource != nil ? newCameraSource : cameraSource.device?.position
            return [
                "type": "CameraCapturer",
                "cameraSource": cameraPositionToString(source)
            ]
        }
        return [
            "type": "Unknown",
            "isScreenCast": videoSource?.isScreencast ?? false
        ]
    }

    private func cameraPositionToString(_ position: AVCaptureDevice.Position?) -> String {
        switch position {
        case .front:
            return "FRONT_CAMERA"
        case .back:
            return "BACK_CAMERA"
        default:
            return "UNKNOWN"
        }
    }

    private func debug(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'native' parameter", details: nil))
        }

        guard let enableNative = arguments["native"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'native' parameter", details: nil))
        }

        SwiftTwilioProgrammableVideoPlugin.nativeDebug = enableNative
        result(enableNative)
    }
}
