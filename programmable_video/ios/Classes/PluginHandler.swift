// swiftlint:disable type_body_length
// swiftlint:disable file_length
import CallKit
import Flutter
import Foundation
import TwilioVideo

public class PluginHandler: BaseListener {
    let TAG = "PluginHandler"

    let audioSettings = AudioSettings()

    public func getRemoteParticipant(_ sid: String) -> RemoteParticipant? {
        return SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.remoteParticipants.first(where: {$0.sid == sid})
    }

    public func getLocalParticipant() -> LocalParticipant? {
        return SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.localParticipant
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // `getStats`, if called repeatedly to drive an animation, is quite noisy
        if call.method != "getStats" {
            debug("handle => received \(call.method)")
        }
        switch call.method {
        case "debug":
            debug(call, result: result)
        case "connect":
            connect(call, result: result)
        case "disconnect":
            disconnect(call, result: result)
        case "setAudioSettings":
            setAudioSettings(call, result: result)
        case "getAudioSettings":
            getAudioSettings(call, result: result)
        case "disableAudioSettings":
            disableAudioSettings(call, result: result)
        case "setSpeakerphoneOn":
            setSpeakerphoneOn(call, result: result)
        case "getSpeakerphoneOn":
            getSpeakerphoneOn(result: result)
        case "deviceHasReceiver":
            deviceHasReceiver(result: result)
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
        case "CameraCapturer#setTorch":
            setTorch(call, result: result)
        case "CameraSource#getSources":
            getSources(call, result: result)
        case "getStats":
            getStats(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getSources(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        return result([
            cameraPositionToMap(.front),
            cameraPositionToMap(.back)
        ])
    }

    private func switchCamera(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        debug("switchCamera => called")
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("cameraId"), details: nil))
        }

        guard let newCameraId = arguments["cameraId"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("cameraId"), details: nil))
        }

        if let cameraSource = SwiftTwilioProgrammableVideoPlugin.cameraSource {
            var captureDevice: AVCaptureDevice?
            switch newCameraId {
            case "BACK_CAMERA":
                captureDevice = CameraSource.captureDevice(position: .back)
            default:
                captureDevice = CameraSource.captureDevice(position: .front)
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

    private func setTorch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        debug("setTorch => called")
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("enable"), details: nil))
        }

        guard let enableTorch = arguments["enable"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("enable"), details: nil))
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
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("name"), details: nil))
        }

        guard let localVideoTrackEnable = arguments["enable"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("enable"), details: nil))
        }

        debug("localVideoTrackEnable => called for \(localVideoTrackName), enable=\(localVideoTrackEnable)")

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
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("name"), details: nil))
        }

        guard let localAudioTrackEnable = arguments["enable"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("enable"), details: nil))
        }

        debug("localAudioTrackEnable => called for \(localAudioTrackName), enable=\(localAudioTrackEnable)")

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
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("sid"), details: nil))
        }

        guard let remoteAudioTrackEnable = arguments["enable"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("enable"), details: nil))
        }

        debug("remoteAudioTrackEnable => called for \(remoteAudioTrackSid), enable=\(remoteAudioTrackEnable)")

        guard let remoteAudioTrack = getRemoteAudioTrack(remoteAudioTrackSid) else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("enable"), details: nil))
        }

        remoteAudioTrack.remoteTrack?.isPlaybackEnabled = remoteAudioTrackEnable
        return result(nil)
    }

    private func isRemoteAudioTrackPlaybackEnabled(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'name' and 'enable' parameters", details: nil))
        }

        guard let remoteAudioTrackSid = arguments["sid"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("sid"), details: nil))
        }

        debug("isRemoteAudioTrackPlaybackEnabled => called for \(remoteAudioTrackSid)")

        guard let remoteAudioTrack = getRemoteAudioTrack(remoteAudioTrackSid) else {
            return result(FlutterError(code: "NOT_FOUND", message: "No remote audio track found: \(remoteAudioTrackSid)", details: nil))
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
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("name"), details: nil))
        }

        guard let localDataTrackMessage = arguments["message"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("message"), details: nil))
        }

        debug("localDataTrackSendString => called for \(localDataTrackName)")

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
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("name"), details: nil))
        }

        guard let localDataTrackMessage = arguments["message"] as? FlutterStandardTypedData else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("message"), details: nil))
        }

        debug("localDataTrackSendString => called for \(localDataTrackName)")

        let localDataTrack = getLocalParticipant()?.localDataTracks.first(where: {$0.trackName == localDataTrackName})
        if let localDataTrack = localDataTrack {
            localDataTrack.localTrack?.send(localDataTrackMessage.data)
            return result(true)
        }
        return result(FlutterError(code: "NOT_FOUND", message: "No LocalDataTrack found with the name '\(localDataTrackName)'", details: nil))
    }

    private func getAudioMode() -> AVAudioSession.Mode {
        let mode: AVAudioSession.Mode = audioSettings.speakerEnabled ? .videoChat : .voiceChat
        return mode
    }

    private func getAudioOptions() -> AVAudioSession.CategoryOptions {
        debug("getAudioOptions =>\n\tbluetoothPreferred: \(audioSettings.bluetoothPreferred)\n\taudioSettings.speakerEnabled: \(audioSettings.speakerEnabled)")
        let options: AVAudioSession.CategoryOptions = audioSettings.bluetoothPreferred && audioSettings.speakerEnabled
            ? [.defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            : audioSettings.bluetoothPreferred ?
        [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP] : []
        return options
    }

    private func setAudioSettings(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        debug("setAudioSettings => called")
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: "Missing 'speakerphoneEnabled' and 'bluetoothPreferred' parameters", details: nil))
        }

        guard let speakerphoneEnabled = arguments["speakerphoneEnabled"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("speakerphoneEnabled"), details: nil))
        }

        guard let bluetoothPreferred = arguments["bluetoothPreferred"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("bluetoothPreferred"), details: nil))
        }

        initializeAudioDevice()
        SwiftTwilioProgrammableVideoPlugin.audioNotificationListener.listenForRouteChanges()

        do {
            audioSettings.speakerEnabled = speakerphoneEnabled
            audioSettings.bluetoothPreferred = bluetoothPreferred

            try applyAudioSettings()

            return result(nil)
        } catch let error as NSError {
            return result(FlutterError(code: "\(error.code)", message: error.description, details: nil))
        }
    }

    private func getAudioSettings(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let audioSettingsDict = [
            "speakerphoneEnabled": audioSettings.speakerEnabled,
            "bluetoothPreferred": audioSettings.bluetoothPreferred
        ]
        result(audioSettingsDict)
    }

    private func disableAudioSettings(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.audioNotificationListener.stopListeningForRouteChanges()
        audioSettings.reset()

        if SwiftTwilioProgrammableVideoPlugin.audioDevice == nil || !(SwiftTwilioProgrammableVideoPlugin.audioDevice! is AVAudioEngineDevice) {
            do {
                let session: AVAudioSession = AVAudioSession.sharedInstance()
                try session.setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
            } catch let error {
                debug("disableAudioSettings => Exception when deactivating AVAudioSession: \(error)")
            }
        }
        result(nil)
    }

    func applyAudioSettings() throws {
        let audioSession = AVAudioSession.sharedInstance()
        let mode: AVAudioSession.Mode = getAudioMode()
        let options: AVAudioSession.CategoryOptions = getAudioOptions()
        debug("applyAudioSettings =>\n\tmode: \(mode)\n\toptions: \(options)\n\tcurrentMode: \(audioSession.mode)\n\tcurrentOptions: \(audioSession.categoryOptions)")
        try audioSession.setCategory(.playAndRecord, mode: mode, options: options)

        if SwiftTwilioProgrammableVideoPlugin.audioDevice == nil || !(SwiftTwilioProgrammableVideoPlugin.audioDevice! is AVAudioEngineDevice) {
                debug("applyAudioSettings => setActive")
            let session: AVAudioSession = AVAudioSession.sharedInstance()
            try session.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        }
    }

    private func setSpeakerphoneOn(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        debug("setSpeakerphoneOn => called")
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("on"), details: nil))
        }

        guard let on = arguments["on"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("on"), details: nil))
        }

        initializeAudioDevice()

        do {
            audioSettings.speakerEnabled = on

            let audioSession = AVAudioSession.sharedInstance()
            let mode: AVAudioSession.Mode = getAudioMode()
            let options: AVAudioSession.CategoryOptions = getAudioOptions()
            try audioSession.setCategory(.playAndRecord, mode: mode, options: options)

            return result(on)
        } catch let error as NSError {
            return result(FlutterError(code: "\(error.code)", message: error.description, details: nil))
        }
    }

    private func getSpeakerphoneOn(result: @escaping FlutterResult) {
        let speakerphoneOn = AVAudioSession.sharedInstance().mode == .videoChat
        debug("getSpeakerphoneOn => called \(speakerphoneOn)")
        return result(speakerphoneOn)
    }

    private func deviceHasReceiver(result: @escaping FlutterResult) {
        // Per https://stackoverflow.com/a/41374958 and https://developer.apple.com/documentation/avfaudio/avaudiosessionportbuiltinreceiver
        // of all iOS devices, typically only iPhones have a build in receiver.
        // Therefore, we check device type rather than checking for outputs
        // since iOS will only show active outputs, and therefore requires manipulation of
        // the AVAudioSession configuration to otherwise determine if the device ∂handlehas a receiver.
        let hasReceiver = UIDevice.current.userInterfaceIdiom == .phone

        debug("deviceHasReceiver => hasReceiver: \(hasReceiver)")
        return result(hasReceiver)
    }

    private func disconnect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        debug("disconnect => called")
        SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.disconnect()

        if let camera = SwiftTwilioProgrammableVideoPlugin.cameraSource {
            camera.stopCapture()
            SwiftTwilioProgrammableVideoPlugin.cameraSource = nil
        }

        result(true)
    }

    private func getStats(result:@escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.getStats {
            result(StatsMapper.statsReportsToDict($0))
        }
    }

    private func initializeAudioDevice() {
        if SwiftTwilioProgrammableVideoPlugin.audioDevice == nil {
            SwiftTwilioProgrammableVideoPlugin.audioDevice = DefaultAudioDevice()
            DefaultAudioDevice.DefaultAVAudioSessionConfigurationBlock()
        }
        TwilioVideoSDK.audioDevice = SwiftTwilioProgrammableVideoPlugin.audioDevice!
    }

    private func checkForActiveCalls() throws {
        let observer = CXCallObserver()
        let calls = observer.calls
        var hasActiveCalls = false
        for call in calls where !call.hasEnded {
            hasActiveCalls = true
            break
        }

        if hasActiveCalls && AVAudioSession.sharedInstance().isOtherAudioPlaying {
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
            } catch let error {
                throw error
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func connect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        debug("connect => called")
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("connectOptions"), details: nil))
        }

        guard let optionsObj = arguments["connectOptions"] as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("connectOptions"), details: nil))
        }

        guard let accessToken = optionsObj["accessToken"] as? String else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("accessToken"), details: nil))
        }

        do {
            try checkForActiveCalls()
        } catch {
            debug("connect => detected an active call that is preventing activation of the AVAudioSession")
            return result(FlutterError(code: "ACTIVE_CALL", message: "Detected an active call that is using the audio system.", details: nil))
        }

        // Override the device before creating any Rooms or Tracks.
        initializeAudioDevice()

        let connectOptions = ConnectOptions(token: accessToken) { (builder) in
            // Set the room name if it has been passed.
            if let roomName = optionsObj["roomName"] as? String {
                self.debug("connect => setting roomName to '\(roomName)'")
                builder.roomName = roomName
            }

            // Set the region if it has been passed.
            if let region = optionsObj["region"] as? String {
                self.debug("connect => setting region to '\(region)'")
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
                self.debug("connect => setting preferredAudioCodecs to '\(audioCodecs)'")
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
                self.debug("connect => setting preferredVideoCodecs to '\(videoCodecs)'")
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
                self.debug("connect => setting audioTracks to '\(audioTracks)'")
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
                self.debug("connect => setting dataTracks to '\(dataTracks)'")
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
                        let cameraSource = videoCapturer?["source"] as? [String: Any]
                        let cameraId = cameraSource?["cameraId"] as? String
                        let cameraDeviceRequested: AVCaptureDevice? = cameraId == "BACK_CAMERA" ?
                            CameraSource.captureDevice(position: .back) :
                            CameraSource.captureDevice(position: .front)

                        guard let cameraDevice = cameraDeviceRequested else {
                            return result(FlutterError(code: "MISSING_CAMERA", message: "No camera found for \(cameraId ?? "FRONT_CAMERA")", details: nil))
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
                self.debug("connect => setting videoTracks to '\(videoTracks)'")
                builder.videoTracks = videoTracks
            }

            if let isNetworkQualityEnabled = optionsObj["enableNetworkQuality"] as? Bool {
                self.debug("connect => setting enableNetworkQuality to '\(isNetworkQualityEnabled)'")
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

        do {
            try applyAudioSettings()
        } catch let error as NSError {
            debug("connect => Error applying audio settings.\n\tCode: \(error.code)\n\tMessage: \(error.description)")
        }

        if let onConnected = SwiftTwilioProgrammableVideoPlugin.audioDeviceOnConnected {
            onConnected()
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
                "source": cameraPositionToMap(source)
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

    private func cameraPositionToMap(_ position: AVCaptureDevice.Position?) -> [String: Any] {
        var hasTorch = false
        if let position = position {
            hasTorch = CameraSource.captureDevice(position: position)?.hasTorch ?? false
        }
        return [
            "isFrontFacing": position == .front,
            "isBackFacing": position == .back,
            "hasTorch": hasTorch,
            "cameraId": cameraPositionToString(position)
        ]
    }

    private func debug(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("native"), details: nil))
        }

        guard let enableNative = arguments["native"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("native"), details: nil))
        }

        guard let enableAudio = arguments["audio"] as? Bool else {
            return result(FlutterError(code: "MISSING_PARAMS", message: missingParameterMessage("audio"), details: nil))
        }

        SwiftTwilioProgrammableVideoPlugin.nativeDebug = enableNative
        SwiftTwilioProgrammableVideoPlugin.audioDebug = enableAudio
        result(enableNative)
    }

    private func missingParameterMessage(_ parameterName: String) -> String {
        return "The parameter '\(parameterName)' was not given"
    }

    func debug(_ msg: String) {
        SwiftTwilioProgrammableVideoPlugin.debug("\(TAG)::\(msg)")
    }
}
