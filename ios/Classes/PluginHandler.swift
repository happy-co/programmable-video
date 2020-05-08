import Flutter
import Foundation
import TwilioVideo

public class PluginHandler {
    let stillFrameRenderer: StillFrameRenderer = StillFrameRenderer()

    public func getRemoteParticipant(_ sid: String) -> RemoteParticipant? {
        return SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.remoteParticipants.first(where: {$0.sid == sid})
    }

    public func getLocalParticipant() -> LocalParticipant? {
        return SwiftTwilioProgrammableVideoPlugin.roomListener?.room?.localParticipant
    }

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
            case "takePhoto":
                takePhoto(result: result)
            case "LocalAudioTrack#enable":
                localAudioTrackEnable(call, result: result)
            case "LocalDataTrack#sendString":
                localDataTrackSendString(call, result: result)
            case "LocalDataTrack#sendByteBuffer":
                localDataTrackSendByteBuffer(call, result: result)
            case "LocalVideoTrack#enable":
                localVideoTrackEnable(call, result: result)
            case "CameraCapturer#switchCamera":
                switchCamera(call, result: result)
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    func screenshotOfVideoStream(_ imageBuffer: CVImageBuffer?) -> Data {
        var ciImage: CIImage? = nil
        if let imageBuffer = imageBuffer {
            ciImage = CIImage(cvPixelBuffer: imageBuffer)
        }
        let temporaryContext = CIContext(options: nil)

        var videoImage: CGImage? = nil
        if let imageBuffer = imageBuffer, let ciImage = ciImage {
            videoImage = temporaryContext.createCGImage(
                ciImage,
                from: CGRect(x: 0, y: 0, width: CGFloat(CVPixelBufferGetWidth(imageBuffer)), height: CGFloat(CVPixelBufferGetHeight(imageBuffer))))
        }

        var image: UIImage? = nil
        if let videoImage = videoImage {
            image = UIImage(cgImage: videoImage)
        }
        if let imageData = image?.jpegData(compressionQuality: 1.0) {
            return imageData
        }

        return Data()
    }

    private func takePhoto(result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.takePhoto => called")
        if let frameToKeep = stillFrameRenderer.frameToKeep {
            return result(screenshotOfVideoStream(frameToKeep.imageBuffer))
        }
         return result(FlutterError(code: "NOT FOUND", message: "No frame data has been captured", details: nil))
    }

    private func switchCamera(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.switchCamera => called")
        if let cameraSource = SwiftTwilioProgrammableVideoPlugin.cameraSource {
            var captureDevice: AVCaptureDevice
            switch cameraSource.device?.position {
                case .back:
                    guard let realCaptureDevice = CameraSource.captureDevice(position: .front) else {
                        return result(RoomListener.videoSourceToDict(cameraSource))
                    }
                    captureDevice = realCaptureDevice
                default: // or .front
                    guard let realCaptureDevice = CameraSource.captureDevice(position: .back) else {
                        return result(RoomListener.videoSourceToDict(cameraSource))
                    }
                    captureDevice = realCaptureDevice
            }
            cameraSource.selectCaptureDevice(captureDevice, completion: { (_, _, error) in
                if let error = error {
                    return result(FlutterError(code: "\((error as NSError).code)", message: (error as NSError).description, details: nil))
                }
                return result(RoomListener.videoSourceToDict(cameraSource))
            })
        } else {
            return result(FlutterError(code: "NOT FOUND", message: "No CameraCapturer has been initialized yet natively", details: nil))
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
            return result(true)
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
            return result(true)
        }
        return result(FlutterError(code: "NOT_FOUND", message: "No LocalAudioTrack found with the name '\(localAudioTrackName)'", details: nil))
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

        // If it is nil then this method is called before the connect method, so we can just set it here as well.
        if SwiftTwilioProgrammableVideoPlugin.audioDevice == nil {
            SwiftTwilioProgrammableVideoPlugin.audioDevice = DefaultAudioDevice()
            TwilioVideoSDK.audioDevice = SwiftTwilioProgrammableVideoPlugin.audioDevice!
        }

        do {
            DefaultAudioDevice.DefaultAVAudioSessionConfigurationBlock()

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
            TwilioVideoSDK.audioDevice = SwiftTwilioProgrammableVideoPlugin.audioDevice!
        }

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
                            let cameraDevice: AVCaptureDevice
                            switch cameraSource {
                                case "BACK_CAMERA":
                                    cameraDevice = CameraSource.captureDevice(position: .back)!
                                default: // or FRONT_CAMERA
                                    cameraDevice = CameraSource.captureDevice(position: .front)!
                            }
                            let videoSource = CameraSource()!
                            let localVideoTrack = LocalVideoTrack(source: videoSource, enabled: enable ?? true, name: name ?? nil)!

                            let videoFormat: VideoFormat = VideoFormat()
                            videoFormat.dimensions  = CMVideoDimensions(width:1920, height: 1080)
                            videoFormat.frameRate = 15

                            videoSource.startCapture(device: cameraDevice, format: videoFormat, completion: nil)
                            videoTracks.append(localVideoTrack)
                            SwiftTwilioProgrammableVideoPlugin.cameraSource = videoSource
                    }
                }
                SwiftTwilioProgrammableVideoPlugin.debug("PluginHandler.connect => setting videoTracks to '\(videoTracks)'")
                builder.videoTracks = videoTracks
            }
        }

        let roomId = 1
        SwiftTwilioProgrammableVideoPlugin.roomListener = RoomListener(roomId, connectOptions)
        result(roomId)
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

class StillFrameRenderer: NSObject, VideoRenderer {
    var frameToKeep: VideoFrame?

    func renderFrame(_ frame: VideoFrame) {
        frameToKeep = frame
    }

    func updateVideoSize(_ videoSize: CMVideoDimensions, orientation: VideoOrientation) {
        //Do nothing
    }
}
