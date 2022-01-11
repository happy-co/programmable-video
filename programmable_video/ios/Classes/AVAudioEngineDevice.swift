// swiftlint:disable file_length
// swiftlint:disable notification_center_detachment

import Foundation
import TwilioVideo

// swiftlint:disable type_body_length
public class AVAudioEngineDevice: NSObject, AudioDevice {
    private let myPropertyQueue: DispatchQueue = DispatchQueue(
        label: "AVAudioEngineDevice_Queue",
        qos: DispatchQoS.utility,
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem,
        target: nil)

    public static let kPreferredIOBufferDuration: Double = 0.01

    // We will use mono playback and recording where available.
    public static let kPreferredNumberOfChannels: UInt32 = 1

    // An audio sample is a signed 16-bit integer.
    public static let kAudioSampleSize: UInt32 = 2
    public static let kPreferredSampleRate: UInt32 = 48000

    /*
     * Calls to AudioUnitInitialize() can fail if called back-to-back after a format change or adding and removing tracks.
     * A fall-back solution is to allow multiple sequential calls with a small delay between each. This factor sets the max
     * number of allowed initialization attempts.
     */
    public static let kMaxNumberOfAudioUnitInitializeAttempts: Int = 5

    // The VoiceProcessingIO audio unit uses bus 0 for ouptut, and bus 1 for input.
    public static let kOutputBus: UInt32 = 0
    public static let kInputBus: UInt32 = 1

    // This is the maximum slice size for VoiceProcessingIO (as observed in the field). We will double check at initialization time.
    public static var kMaximumFramesPerBuffer: UInt32 = 3072

    /// Properties
    var isConnected: Bool = false
    var interrupted: Bool = false
    var isStartingRenderer: Bool = false
    var isStoppingRenderer: Bool = false
    var isRendering: Bool = false
    var didFormatChangeWhileDisconnected = false

    internal var audioUnit: AudioUnit?

    var renderingFormat: AudioFormat?
    var capturingFormat: AudioFormat?

    var renderingContext: AudioRendererContext = AudioRendererContext()
    var capturingContext: AudioCapturerContext = AudioCapturerContext()

    // AudioEngine properties
    var playoutEngine: AVAudioEngine?
    var recordEngine: AVAudioEngine?

    let audioPlayerNodeManager: AVAudioPlayerNodeManager = AVAudioPlayerNodeManager()

    // Reference to PluginHandler's applyAudioSettings
    var applyAudioSettings: (() throws -> Void)?

    public func setApplyAudioSettings(_ applyAudioSettings: @escaping () throws -> Void) {
        self.applyAudioSettings = applyAudioSettings
    }

    static var instance: AVAudioEngineDevice = AVAudioEngineDevice()
    static let audioDebug = false

    public static func getInstance() -> AVAudioEngineDevice {
        return instance
    }

    // MARK: Init & Dealloc
    override private init() {
        debug("init => START")
        super.init()

        /*
         * Initialize rendering and capturing context. The deviceContext will be be filled in when startRendering or
         * startCapturing gets called.
         */
        self.setupAudioUnit()
        self.getMaximumSliceSize()
        self.allocateMemoryForAudioBuffers()

        // Setup the AVAudioEngine along with the rendering context
        if !self.setupAudioEngine() {
            debug("init => Failed to setup AVAudioEngine")
        }

        debug("init => END")
    }

    deinit {
        debug("deinit")
        self.disposeAllNodes()
        self.stopRendering()
        self.stopCapturing()
        NotificationCenter.default.removeObserver(self)
        self.teardownAudioEngine()
        deallocateMemoryForAudioBuffers()
    }

    // Allocating pointers explicitly exempts them from Automatic Reference Counting
    func allocateMemoryForAudioBuffers() {
        let audioBufferListSize = MemoryLayout<AudioBufferList>.size
        let renderingCapacity = Int(AVAudioEngineDevice.kMaximumFramesPerBuffer * AVAudioEngineDevice.kPreferredNumberOfChannels * AVAudioEngineDevice.kAudioSampleSize)

        debug("allocateMemoryForAudioBuffers => renderCapacity: \(renderingCapacity)")
        var pRenderBufferList = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer<AudioBufferList>.allocate(capacity: renderingCapacity))
        var renderBufferListData = UnsafeMutablePointer<Int8>.allocate(capacity: renderingCapacity)
        var renderBufferList = AudioBufferList(mNumberBuffers: 1,
                                             mBuffers: AudioBuffer(
                                                mNumberChannels: AVAudioEngineDevice.kPreferredNumberOfChannels,
                                                mDataByteSize: UInt32(0),
                                                mData: renderBufferListData))
        pRenderBufferList.unsafeMutablePointer.initialize(to: renderBufferList)

        self.renderingContext.bufferList = pRenderBufferList
        // Ensure getMaximumSliceSize has run before this
        self.renderingContext.maxFramesPerBuffer = Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)

        var pCaptureBufferList = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer<AudioBufferList>.allocate(capacity: renderingCapacity))
        var captureBufferListData = UnsafeMutablePointer<Int8>.allocate(capacity: renderingCapacity)
        var captureBufferList = AudioBufferList(mNumberBuffers: 1,
                                             mBuffers: AudioBuffer(
                                                mNumberChannels: AVAudioEngineDevice.kPreferredNumberOfChannels,
                                                mDataByteSize: UInt32(0),
                                                mData: renderBufferListData))
        pCaptureBufferList.unsafeMutablePointer.initialize(to: captureBufferList)

        var pMixedAudioBufferList = UnsafeMutablePointer<AudioBufferList?>.allocate(capacity: audioBufferListSize)
        var pMixedAudioBufferListData = UnsafeMutablePointer<Int8>.allocate(capacity: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer * AVAudioEngineDevice.kPreferredNumberOfChannels * AVAudioEngineDevice.kAudioSampleSize))
        pMixedAudioBufferList.initialize(to: AudioBufferList(
                                            mNumberBuffers: 1,
                                            mBuffers: AudioBuffer(
                                             mNumberChannels: AVAudioEngineDevice.kPreferredNumberOfChannels,
                                             mDataByteSize: UInt32(0),
                                             mData: pMixedAudioBufferListData
                                            )))

        self.capturingContext.bufferList = pCaptureBufferList
        self.capturingContext.mixedAudioBufferList = pMixedAudioBufferList
    }

    func deallocateMemoryForAudioBuffers() {
        debug("deallocateMemoryForAudioBuffers")
        self.renderingContext.bufferList?.unsafePointer.deallocate()
        self.renderingContext.bufferList = nil
        self.renderingContext.maxFramesPerBuffer = nil

        self.capturingContext.bufferList?.unsafePointer.deallocate()
        self.capturingContext.mixedAudioBufferList?.deallocate()
        self.capturingContext.bufferList = nil
        self.capturingContext.mixedAudioBufferList = nil
    }

    func description() -> NSString {
        return "AVAudioEngine Audio Mixing"
    }

    /*
     * Determine at runtime the maximum slice size used by VoiceProcessingIO. While I/O Audio Units
     * Ostensibly can handle any format, the AVAudioEngine's need to have the format provided at configuration
     * time. As a result, when format is determined to have changed, or has potentially changed, we reinitialize
     * AudioUnit, ensure that we have its maximum slice size, and then reinitialize the AVAudioEngines.
     */
    func getMaximumSliceSize() {
        guard let audioUnit = self.audioUnit else {
            debug("Could not getMaximumSliceSize! Audio Unit not initialized!")
            return
        }

        var framesPerSlice: UInt32 = 0
        var propertySize: UInt32 = UInt32(MemoryLayout<UInt32>.size)
        var status = AudioUnitGetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global, AVAudioEngineDevice.kOutputBus,
                                      &framesPerSlice, &propertySize)
        debug("getMaximumSliceSize =>\n\tmaximum slice size: \(framesPerSlice) frames.\n\taudioUnit: \(audioUnit)")
        AVAudioEngineDevice.kMaximumFramesPerBuffer = framesPerSlice
    }

    // MARK: Private (AVAudioEngine)
    func setupAudioEngine() -> Bool {
        debug("setupAudioEngine")
        return self.setupPlayoutAudioEngine() && self.setupRecordAudioEngine()
    }

    func setupRecordAudioEngine() -> Bool {
        debug("setupRecordAudioEngine")
        assert(self.recordEngine == nil, "AVAudioEngine is already configured")

        /*
         * By default AVAudioEngine will render to/from the audio device, and automatically establish connections between
         * nodes, e.g. inputNode -> effectNode -> outputNode.
         */
        self.recordEngine = AVAudioEngine()
        guard let engine = self.recordEngine else {
            return false
        }

        // AVAudioEngine operates on the same format as the Core Audio output bus.
        guard let activeFormat = activeFormat() else {
            return false
        }
        self.capturingFormat = activeFormat

        var asbd: AudioStreamBasicDescription = activeFormat.streamDescription()

        guard let format = AVAudioFormat(streamDescription: &asbd) else {
            return false
        }

        // Switch to manual rendering mode
        engine.stop()
        do {
            debug("setupRecordAudioEngine => enableManualRenderingMode:\n\tformat: \(format)")
            try engine.enableManualRenderingMode(AVAudioEngineManualRenderingMode.realtime, format: format, maximumFrameCount: UInt32(activeFormat.framesPerBuffer))
        } catch let error {
            debug("Failed to setup manual rendering mode, error = \(error)")
            return false
        }

        /*
         * In manual rendering mode, AVAudioEngine won't receive audio from the microphone. Instead, it will receive the
         * audio data from the Video SDK and mix it in MainMixerNode. Here we connect the input node to the main mixer node.
         * InputNode -> MainMixer -> OutputNode
         */
        engine.connect(engine.inputNode, to: engine.mainMixerNode, format: format)

        // Set the block to provide input data to engine
        let inputNode: AVAudioInputNode = engine.inputNode
        var success: Bool = inputNode.setManualRenderingInputPCMFormat(format) { (inNumberOfFrames: AVAudioFrameCount) -> UnsafePointer<AudioBufferList>? in
            assert(inNumberOfFrames <= activeFormat.framesPerBuffer)
            return self.capturingContext.bufferList?.unsafePointer
        }

        if !success {
            debug("Failed to set the manual rendering block")
            return false
        }

        // The manual rendering block (called in Core Audio's VoiceProcessingIO's playout callback at real time)
        self.capturingContext.renderBlock = engine.manualRenderingBlock

        do {
            debug("AVAudioEngine::setupRecordAudioEngine => start engine")
            try engine.start()
        } catch let error {
            debug("Failed to start AVAudioEngine, error = \(error)")
            return false
        }

        debug("AVAudioEngine::setupRecordAudioEngine => END")
        return true
    }

    // swiftlint:disable:next function_body_length
    func setupPlayoutAudioEngine() -> Bool {
        debug("setupPlayoutAudioEngine")
        assert(self.playoutEngine == nil, "AVAudioEngine is already configured")

        /*
         * By default AVAudioEngine will render to/from the audio device, and automatically establish connections between
         * nodes, e.g. inputNode -> effectNode -> outputNode.
         */
        self.playoutEngine = AVAudioEngine()
        guard let engine = self.playoutEngine else {
            return false
        }

        // AVAudioEngine operates on the same format as the Core Audio output bus.
        guard let activeFormat = activeFormat() else {
            return false
        }
        self.renderingFormat = activeFormat

        var asbd: AudioStreamBasicDescription = activeFormat.streamDescription()
        guard let format = AVAudioFormat(streamDescription: &asbd) else {
            return false
        }

        // Switch to manual rendering mode
        engine.stop()
        do {
            debug("setupPlayoutAudioEngine =>\n\tformat: \(format)\n\tmaxFrameCount: \(UInt32(activeFormat.framesPerBuffer))\n\tsampleRate: \(format.sampleRate)")
            try engine.enableManualRenderingMode(AVAudioEngineManualRenderingMode.realtime, format: format, maximumFrameCount: UInt32(activeFormat.framesPerBuffer))
        } catch let error {
            debug("Failed to setup manual rendering mode, error = \(error)")
            return false
        }

        /*
         * In manual rendering mode, AVAudioEngine won't receive audio from the microhpone. Instead, it will receive the
         * audio data from the Video SDK and mix it in MainMixerNode. Here we connect the input node to the main mixer node.
         * InputNode -> MainMixer -> OutputNode
         */
        engine.connect(engine.inputNode, to: engine.mainMixerNode, format: format)

        /*
         * Attach AVAudioPlayerNode node to play music from a file.
         * AVAudioPlayerNode -> ReverbNode -> AVAudioUnitEQ -> MainMixer -> OutputNode (note: ReverbNode is optional)
         */
        if self.audioPlayerNodeManager.shouldReattachNodes() {
            self.reattachMusicNodes()
        }

        // Set the block to provide input data to engine
        let inputNode: AVAudioInputNode = engine.inputNode
        let success: Bool = inputNode.setManualRenderingInputPCMFormat(format) { [unowned self] (inNumberOfFrames: AVAudioFrameCount) -> UnsafePointer<AudioBufferList>? in
            assert(inNumberOfFrames <= activeFormat.framesPerBuffer)

            debugAudio("playoutEngine renderBlock")
            guard let audioBuffer = self.renderingContext.bufferList?.first?.mData?.assumingMemoryBound(to: Int8.self),
                  let dataByteSize = self.renderingContext.bufferList?.first?.mDataByteSize else {
                return nil
            }

            let audioBufferSizeInBytes: Int = Int(dataByteSize)

            if let deviceContext = self.renderingContext.deviceContext {
                /*
                 * Pull decoded, mixed audio data from the media engine into the
                 * AudioUnit's AudioBufferList.
                 */
                debugAudio("playoutEngine renderBlock => readRenderData")
                AudioDeviceReadRenderData(context: deviceContext, data: audioBuffer, sizeInBytes: audioBufferSizeInBytes)
            } else {
                /*
                 * Return silence when we do not have the playout device context. This is the
                 * case when the remote participant has not published an audio track yet.
                 * Since the audio graph and audio engine has been setup, we can still play
                 * the music file using AVAudioEngine.
                 */
                debugAudio("playoutEngine renderBlock => memset silence")
                memset(audioBuffer, 0, audioBufferSizeInBytes)
            }

            return self.renderingContext.bufferList?.unsafePointer
        }

        if !success {
            debug("Failed to set the manual rendering block")
            return false
        }

        // The manual rendering block (called in Core Audio's VoiceProcessingIO's playout callback at real time)
        self.renderingContext.renderBlock = engine.manualRenderingBlock

        do {
            debug("AVAudioEngine::setupPlayoutAudioEngine => start engine")
            try engine.start()
        } catch let error {
            debug("Failed to start AVAudioEngine, error = \(error)")
            return false
        }

        debug("setupPlayoutAudioEngine => end")
        return true
    }

    func teardownRecordAudioEngine() {
        debug("teardownRecordAudioEngine")
        if let engine = self.recordEngine {
            engine.stop()
            self.recordEngine = nil
            self.capturingFormat = nil
        }
    }

    func teardownPlayoutAudioEngine() {
        debug("teardownPlayoutAudioEngine")
        if let engine = self.playoutEngine, engine.isRunning {
            engine.stop()
        }
        self.playoutEngine = nil
        self.renderingFormat = nil
    }

    func teardownAudioEngine() {
        debug("teardownAudioEngine")
        self.teardownPlayoutAudioEngine()
        self.teardownRecordAudioEngine()
    }

    public func onConnected() {
        debug("onConnected => START")
        self.setupAVAudioSession()
        self.isConnected = true
        debug("onConnected => END")
    }

    public func onDisconnected() {
        debug("onDisconnected => START")
        self.isConnected = false
        self.safelyTeardownAVAudioSession()
        debug("onDisconnected => END")
    }

    // MARK: Audio File Playback API
    public func playMusic(_ id: Int) {
        self.audioPlayerNodeManager.queueNode(id)
        safelyPlayMusic {
            debug("playMusic => START")
            self.audioPlayerNodeManager.playNode(id)
            debug("playMusic => END")
        }
    }

    func safelyPlayMusic(_ playCallback: @escaping () -> Void) {
        debug("safelyPlayMusic => START")
        self.setupAVAudioSession()

        self.myPropertyQueue.async {
            debug("safelyPlayMusic => START - myPropertyQueue.async" +
                "\n\tstartingRenderer: \(self.isStartingRenderer)" +
                "\n\tisRendering: \(self.isRendering)" +
                "\n\tstoppingRenderer: \(self.isStoppingRenderer)")

            // Could collapse isRendering/isStartingRenderer/isStoppingRenderer into a single state enum
            if self.isRendering {
                    debug("safelyPlayMusic => scheduleMusicOnPlayoutEngine => dispatch")
                // Since the engine is already rendering, no need to queue playCallback on myPropertyQueue to ensure that it occurs after rendering is started
                playCallback()
            } else if self.isStartingRenderer {
                debug("safelyPlayMusic => playCallback: QUEUE - self.myPropertyQueue.async")
                self.myPropertyQueue.async {
                    playCallback()
                }
            } else {
                debug("safelyPlayMusic => startRendering")
                if self.startRenderingInternal(context: nil) {
                    debug("safelyPlayMusic => startRendering => scheduleMusicOnPlayoutEngine")
                    playCallback()
                } else {
                    debug("safelyPlayMusic => startRendering failed")
                }
            }
            debug("safelyPlayMusic => END - myPropertyQueue.async")
        }
    }

    public func stopMusic(_ id: Int) {
        debug("stopMusic => node: \(id)")
        self.audioPlayerNodeManager.stopNode(id)

        if !self.audioPlayerNodeManager.isActive(),
           !self.isConnected,
            !self.isStartingRenderer,
            !self.isStoppingRenderer {
            self.stopRendering()
        }
        self.safelyTeardownAVAudioSession()
        debug("stopMusic => END node: \(id)")
    }

    func safelyTeardownAVAudioSession() {
        self.myPropertyQueue.async {
            debug("safelyTeardownAVAudioSession => START")
            if !self.audioPlayerNodeManager.isActive(),
               !self.isConnected,
                !self.isStartingRenderer,
                !self.isStoppingRenderer {
                self.teardownAVAudioSession()
            }
            debug("safelyTeardownAVAudioSession => END")
        }
    }

    public func pauseMusic(_ id: Int) {
        debug("pauseNode => \(id)")
        self.audioPlayerNodeManager.pauseNode(id)
    }

    public func resumeMusic(_ id: Int) {
        debug("resumeMusic => \(id)")
        self.audioPlayerNodeManager.resumeNode(id)
    }

    public func setMusicVolume(_ id: Int, _ volume: Double) {
        self.audioPlayerNodeManager.setMusicVolume(id, volume)
    }

    public func seekPosition(_ id: Int, _ positionInMillis: Int) {
        safelyPlayMusic {
            debug("seekPosition => START\n\tid: \(id), positionInMillis: \(positionInMillis)")
            self.audioPlayerNodeManager.seekPosition(id, Int64(positionInMillis))
            debug("seekPosition => END")
        }
    }

    public func getPosition(_ id: Int) -> Int64 {
        debug("getPosition => id: \(id)")
        return self.audioPlayerNodeManager.getPosition(id)
    }

    func disposeAllNodes() {
        self.audioPlayerNodeManager.nodes.keys.forEach { (id) in
            disposeMusicNode(id)
        }
    }

    public func disposeMusicNode(_ id: Int) {
        debug("disposeMusicNode => id: \(id)")
        stopMusic(id)
        detachMusicNode(id)

        self.audioPlayerNodeManager.disposeNode(id)
    }

    public func addMusicNode(_ id: Int, _ file: AVAudioFile, _ loop: Bool, _ volume: Double) {
        if self.playoutEngine == nil {
            self.setupPlayoutAudioEngine()
        }

        let nodeBundle = self.audioPlayerNodeManager.addNode(id, file, loop, volume)
        self.attachMusicNode(nodeBundle)
    }

    func reattachMusicNodes() {
        debug("reattachMusicNodes")
        self.audioPlayerNodeManager.nodes.values.forEach { (_ node: AVAudioPlayerNodeBundle) in
            attachMusicNode(node)
        }
    }

    func attachMusicNode(_ nodeBundle: AVAudioPlayerNodeBundle) {
        debug("attachMusicNode => node: \(nodeBundle.id)")
        guard let playoutEngine = self.playoutEngine else {
            return
        }

        playoutEngine.attach(nodeBundle.player)
        playoutEngine.attach(nodeBundle.reverb)
        playoutEngine.attach(nodeBundle.eq)
        playoutEngine.connect(nodeBundle.player, to: nodeBundle.reverb, format: nodeBundle.file.processingFormat)
        playoutEngine.connect(nodeBundle.reverb, to: nodeBundle.eq, format: nodeBundle.file.processingFormat)
        playoutEngine.connect(nodeBundle.eq, to: playoutEngine.mainMixerNode, format: nodeBundle.file.processingFormat)
    }

    func detachMusicNode(_ id: Int) {
        guard let playoutEngine = self.playoutEngine,
              let node = self.audioPlayerNodeManager.getNode(id) else {
            return
        }

        playoutEngine.disconnectNodeOutput(node.eq)
        playoutEngine.disconnectNodeOutput(node.reverb)
        playoutEngine.disconnectNodeOutput(node.player)

        playoutEngine.detach(node.eq)
        playoutEngine.detach(node.reverb)
        playoutEngine.detach(node.player)
    }

    func detachMusicNodes() {
        self.audioPlayerNodeManager.nodes.forEach { (arg0) in
            let (key, _) = arg0
            self.detachMusicNode(key)
        }
    }

    // MARK: TVIAudioDeviceRenderer
    public func renderFormat() -> AudioFormat? {
        debug("renderFormat => format: \(self.renderingFormat)")
        return renderingFormat
    }

    public func initializeRenderer() -> Bool {
        debug("initializeRenderer")
        /*
         * In this example we don't need any fixed size buffers or other pre-allocated resources. We will simply write
         * directly to the AudioBufferList provided in the AudioUnit's rendering callback.
         */
        return true
    }

    public func startRendering(context: AudioDeviceContext?) -> Bool {
        self.isStartingRenderer = true
        self.isRendering = false

        debug("startRendering => START context: \(context)")
        self.myPropertyQueue.async {
            var result: Bool = false
            var attempts = 0
            let maxAttempts = 10
            while !result && attempts < maxAttempts {
                attempts += 1
                debug("startRendering => attempt \(attempts)")
                if AVAudioSession.sharedInstance().isOtherAudioPlaying {
                    debug("startRendering => Other audio is playing. Retrying in 100ms")
                    let timeSecs = 0.1 /// 100ms
                    Thread.sleep(forTimeInterval: timeSecs)
                    continue
                }

                result = self.startRenderingInternal(context: context)

                if result {
                    debug("startRendering => SUCCESS")
                    break
                }

                if attempts < maxAttempts {
                    debug("startRendering => FAIL attempt \(attempts). Retrying in 100ms")
                    let timeSecs = 0.1 /// 100ms
                    Thread.sleep(forTimeInterval: timeSecs)
                } else {
                    debug("startRendering => ERROR could not start rendering.")
                }
            }
        }

        debug("startRendering => END")
        return true
    }

    // swiftlint:disable:next function_body_length
    internal func startRenderingInternal(context: AudioDeviceContext?) -> Bool {
        debug("startRenderingInternal => START\n\tcontext: \(context)\n\totherAudioPlaying: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")

        if self.didFormatChangeWhileDisconnected {
            debug("startRenderingInternal => notifyVideoSdkOfFormatChange")
            self.handleFormatChange("startRenderingInternal")
            self.notifyVideoSdkOfFormatChange(context: context)
        }

        var result = false

        self.isStartingRenderer = true
        self.isRendering = false
        // Do not overwrite valid deviceContext with null
        if let context = context {
            self.renderingContext.deviceContext = context
        }

        // Pause active audio player nodes while engine is restarted
        if self.audioPlayerNodeManager.anyPlaying() || self.audioPlayerNodeManager.anyQueued() {
            debug("startRenderingInternal => pause active audio nodes")
            /*
            * Since startRenderingInternal should always be run on the local DispatchQueue
            * we do not need to dispatch this call here. Further, we want to ensure this
            * completes execution prior to stopping the audio unit.
            */
            self.audioPlayerNodeManager.pauseAll(true)
            debug("startRenderingInternal => nodes paused")
        }

        /*
         * We will restart the audio unit if a remote participant adds an audio track after the audio graph is
         * established. Also we will re-establish the audio graph in case the format changes.
         *
         * We will start the audioGraph if playback of an attached audio node is requested while
         * rendering is not already underway.
         */
        if self.audioUnit != nil {
            debug("startRenderingInternal => reset audioUnit")
            self.stopAudioUnit()
            self.teardownAudioUnit()
        }

        self.setupAudioUnit()

        if let engine = self.playoutEngine,
           let engineFormat = AudioFormat(
            channels: Int(engine.manualRenderingFormat.channelCount),
            sampleRate: UInt32(engine.manualRenderingFormat.sampleRate),
            framesPerBuffer: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)),
           let activeFormat = self.activeFormat(),
           engineFormat.isEqual(activeFormat) {
            if engine.isRunning {
                debug("startRenderingInternal => stopping engine.\n\tengineFormat: \(engineFormat)\n\tactiveFormat: \(activeFormat)")
                engine.stop()
            }

            do {
                debug("startRenderingInternal => starting engine")
                try engine.start()
            } catch let error {
                debug("Failed to start AVAudioEngine, error = \(error)")
            }
        } else {
        /*
         * If the engine is not configured properly we will tear it down,
         * restart it, reattach audio nodes as needed.
         */
            debug("startRenderingInternal => teardown and setup audio engine\n\tengineFormat: \(self.renderingFormat)\n\tactiveFormat: \(self.activeFormat)")
            self.teardownPlayoutAudioEngine()
            self.setupPlayoutAudioEngine()
        }

        result = self.startAudioUnit()

        // Resume playback on audio player nodes that were active prior to engine restart
        if self.audioPlayerNodeManager.anyPaused() {
            /*
             * ensure fadeIn/resume is happening on the same queue as other
             * requests to change player state
             */
            debug("startRenderingInternal => resumeAll")
            self.audioPlayerNodeManager.resumeAll()
        }

        self.isStartingRenderer = false
        self.isRendering = true

        debug("startRenderingInternal => END - result: \(result)")

        return result
    }

    public func stopRendering() -> Bool {
        debug("stopRendering => nodes playing: \(self.audioPlayerNodeManager.anyPlaying()), nodes paused: \(self.audioPlayerNodeManager.anyPaused())")
        self.isStoppingRenderer = true
        self.isRendering = false
        self.myPropertyQueue.async {
            debug("stopRendering => START - myPropertyQueue.async")
            let isActive = self.audioPlayerNodeManager.isActive()
            // If the capturer is running, we will not stop the audio unit.
            if self.capturingContext.deviceContext == nil,
               !isActive {
                debug("stopRendering => stopAudioUnit")
                self.stopAudioUnit()
                self.teardownAudioUnit()
            }

            self.renderingContext.deviceContext = nil
            if let engine = self.playoutEngine,
               engine.isRunning,
               !isActive {
                // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.

                // If audio player nodes are in use, we will not stop the engine
                if let engine = self.playoutEngine {
                    debug("stopRendering => stop playoutEngine")
                    engine.stop()
                }
                debug("stopRendering => END - DispatchQueue.main.async")
                self.isStoppingRenderer = false
            } else {
                self.isStoppingRenderer = false
            }
            debug("stopRendering => END - myPropertyQueue.async")
        }

        return true
    }

    // MARK: AudioDeviceCapturer
    public func captureFormat() -> AudioFormat? {
        debug("captureFormat => format: \(self.capturingFormat)")
        return capturingFormat
    }

    public func initializeCapturer() -> Bool {
        debug("initializeCapturer")
        return true
    }

    public func startCapturing(context: AudioDeviceContext) -> Bool {
        debug("startCapturing => START context: \(context)")
        self.myPropertyQueue.async {
            var result: Bool = false
            var attempts = 0
            let maxAttempts = 10

            while !result && attempts < maxAttempts {
                attempts += 1
                debug("startCapturing => attempt \(attempts)")
                if AVAudioSession.sharedInstance().isOtherAudioPlaying {
                    debug("startCapturing => Other audio is playing. Retrying in 100ms")
                    let timeSecs = 0.1 /// 100ms
                    Thread.sleep(forTimeInterval: timeSecs)
                    continue
                }

                result = self.startCapturingInternal(context: context)

                if result {
                    debug("startCapturing => SUCCESS")
                    break
                }

                if attempts < maxAttempts {
                    debug("startCapturing => FAIL attempt \(attempts). Retrying in 100ms")
                    let timeSecs = 0.1 /// 100ms
                    Thread.sleep(forTimeInterval: timeSecs)
                } else {
                    debug("startCapturing => ERROR could not start capturing.")
                }
            }
        }

        return true
    }

    internal func startCapturingInternal(context: AudioDeviceContext) -> Bool {
        var result: Bool = true
        debug("startCapturingInternal - START\n\tcontext: \(context)\n\totherAudioPlaying: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
        if self.didFormatChangeWhileDisconnected {
            debug("startCapturingInternal => notifyVideoSdkOfFormatChange")
            self.handleFormatChange("startCapturingInternal")
            self.notifyVideoSdkOfFormatChange(context: context)
        }

        if self.audioPlayerNodeManager.anyPlaying() {
            debug("startCapturingInternal => pause active audio nodes")
            /*
            * Since startRenderingInternal should always be run on the local DispatchQueue
            * we do not need to dispatch this call here. Further, we want to ensure this
            * completes execution prior to stopping the audio unit.
            */
            self.audioPlayerNodeManager.pauseAll(true)
            debug("startCapturingInternal => nodes paused")
        }

        // Restart the audio unit if the audio graph is alreay setup and if we publish an audio track.
        if self.audioUnit != nil {
            debug("startCapturingInternal => reset audioUnit")
            self.stopAudioUnit()
            self.teardownAudioUnit()
        }

        self.setupAudioUnit()

        if let engine = self.recordEngine,
           let engineFormat = AudioFormat(
            channels: Int(engine.manualRenderingFormat.channelCount),
            sampleRate: UInt32(engine.manualRenderingFormat.sampleRate),
            framesPerBuffer: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)),
           let activeFormat = self.activeFormat(),
           engineFormat.isEqual(activeFormat) {
            if engine.isRunning {
                debug("startCapturingInternal => stopping engine")
                engine.stop()
            }

            do {
                debug("startCapturingInternal => starting engine")
                try engine.start()
            } catch let error {
                debug("startCapturingInternal => Failed to start AVAudioEngine, error = \(error)")
            }
        } else {
            self.teardownRecordAudioEngine()
            self.setupRecordAudioEngine()
        }

        self.capturingContext.deviceContext = context

        result = self.startAudioUnit()

        if self.isRendering && self.audioPlayerNodeManager.anyPaused() {
            /*
             * ensure fadeIn/resume is happening on the same queue as other
             * requests to change player state
             */
            debug("startCapturingInternal => resumeAll")
            self.audioPlayerNodeManager.resumeAll()
        }

        debug("startCapturingInternal - END - result: \(result)")
        return result
    }

    public func stopCapturing() -> Bool {
        debug("stopCapturing => nodes playing: \(self.audioPlayerNodeManager.anyPlaying()), nodes paused: \(self.audioPlayerNodeManager.anyPaused())")
        self.myPropertyQueue.async {
            debug("stopCapturing => START - myPropertyQueue.async")
            // If the renderer is in use by a remote participants audio track, or audio player nodes, we will not stop the audio unit.
            if self.renderingContext.deviceContext == nil,
               !self.audioPlayerNodeManager.isActive() {
                self.stopAudioUnit()
                self.teardownAudioUnit()
            }
            self.capturingContext.deviceContext = nil

            // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.
            if let engine = self.recordEngine, engine.isRunning {
                debug("stopCapturing => stop recordEngine")
                engine.stop()
            }
            debug("stopCapturing => END - myPropertyQueue.async")
        }

        return true
    }

    // MARK: Private (AVAudioSession and CoreAudio)
    func activeFormat() -> AudioFormat? {
        debug("activeFormat =>\n\tmaxFramesPerBuffer: \(AVAudioEngineDevice.kMaximumFramesPerBuffer)\n\tsampleRate: \(AVAudioSession.sharedInstance().sampleRate)")
        /*
         * Use the pre-determined maximum frame size. AudioUnit callbacks are variable, and in most sitations will be close
         * to the `AVAudioSession.preferredIOBufferDuration` that we've requested.
         */
        let sessionFramesPerBuffer: Int = Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)
        let sessionSampleRate: UInt32 = UInt32(AVAudioSession.sharedInstance().sampleRate)

        return AudioFormat(channels: AudioFormat.ChannelsMono, sampleRate: sessionSampleRate, framesPerBuffer: sessionFramesPerBuffer)
    }

    static func audioUnitDescription() -> AudioComponentDescription {
        debug("audioUnitDescription")
        var audioUnitDescription: AudioComponentDescription = AudioComponentDescription()
        audioUnitDescription.componentType = kAudioUnitType_Output
        audioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO
        audioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple
        audioUnitDescription.componentFlags = 0
        audioUnitDescription.componentFlagsMask = 0
        return audioUnitDescription
    }

    func setupAVAudioSession() {
        let session: AVAudioSession = AVAudioSession.sharedInstance()
        debug("setupAVAudioSession => START AVAudioSession:" +
            "\n\tpreferredSampleRate: \(session.preferredSampleRate)" +
            "\n\tpreferredOutputNumberOfChannels: \(session.preferredOutputNumberOfChannels)" +
            "\n\tpreferredIOBufferDuration: \(session.preferredIOBufferDuration)" +
            "\n\totherAudioPlaying: \(session.isOtherAudioPlaying)")

        do {
            try session.setPreferredSampleRate(Double(AVAudioEngineDevice.kPreferredSampleRate))
            try session.setPreferredOutputNumberOfChannels(Int(AVAudioEngineDevice.kPreferredNumberOfChannels))
            /*
             * We want to be as close as possible to the 10 millisecond buffer size that the media engine needs. If there is
             * a mismatch then TwilioVideo will ensure that appropriately sized audio buffers are delivered.
             */
            try session.setPreferredIOBufferDuration(AVAudioEngineDevice.kPreferredIOBufferDuration)

            // Callout to PluginHandler to applyAudioSettings to ensure that those applied are those set by user
            if let applyAudioSettings = applyAudioSettings {
                try applyAudioSettings()
            }
        } catch let error {
            debug("setupAVAudioSession => Error setting up AudioSession: \(error)")
            self.didFormatChangeWhileDisconnected = true
            return
        }

        self.registerAVAudioSessionObservers()

        do {
            debug("setupAVAudioSession => setupAVAudioSession => setActive")
            try session.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch let error {
            debug("setupAVAudioSession => Error activating AVAudioSession: \(error)")
            self.didFormatChangeWhileDisconnected = true
            return
        }

        if session.maximumInputNumberOfChannels > 0 {
            do {
                try session.setPreferredInputNumberOfChannels(AudioFormat.ChannelsMono)
            } catch let error {
                debug("setupAVAudioSession => Error setting number of input channels: \(error)")
                self.didFormatChangeWhileDisconnected = true
                return
            }
        }
        debug("setupAVAudioSession => END")
    }

    func teardownAVAudioSession() {
        let anyActive = self.audioPlayerNodeManager.isActive()
        debug("teardownAVAudioSession =>\n\tanyActive: \(anyActive)" +
        "\n\tisConnected: \(self.isConnected)\n\tisRendering: \(self.isRendering)" +
        "\n\tisStartingRenderer: \(self.isStartingRenderer)\n\tisStoppingRenderer: \(self.isStoppingRenderer)")
        if !anyActive && !self.isConnected {
            do {
                NotificationCenter.default.removeObserver(self)
                let session = AVAudioSession.sharedInstance()
                try session.setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
            } catch let error {
                debug("Error deactivating AVAudioSession: \(error)")
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func setupAudioUnit() {
        debug("setupAudioUnit")
        // Find and instantiate the VoiceProcessingIO audio unit.
        var audioUnitDescription: AudioComponentDescription = AVAudioEngineDevice.audioUnitDescription()
        guard let audioComponent: AudioComponent = AudioComponentFindNext(nil, &audioUnitDescription) else {
            debug("Could not find VoiceProcessingIO AudioComponent!")
            return
        }

        var status: OSStatus = AudioComponentInstanceNew(audioComponent, &self.audioUnit)
        if status != 0 {
            debug("Could not find VoiceProcessingIO AudioComponent instance!")
            return
        }

        /*
         * Configure the VoiceProcessingIO audio unit. Our rendering format attempts to match what AVAudioSession requires
         * to prevent any additional format conversions after the media engine has mixed our playout audio.
         */
        guard var streamDescription: AudioStreamBasicDescription = self.activeFormat()?.streamDescription() else {
            debug("Could not find AudioStreamBasicDescription!")
            return
        }

        guard let audioUnit = self.audioUnit else {
            debug("Could not find AudioUnit.")
            return
        }

        var enableOutput: UInt32 = 1
        var enableInput: UInt32 = 1
        let uint32Size = UInt32(MemoryLayout<UInt32>.size)
        let streamDescriptionSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        let auRenderCallbackStructSize = UInt32(MemoryLayout<AURenderCallbackStruct>.size)

        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Output, AVAudioEngineDevice.kOutputBus,
                                      &enableOutput, uint32Size)
        if status != 0 {
            debug("Could not enable out bus!")
            if let audioUnit = self.audioUnit {
                AudioComponentInstanceDispose(audioUnit)
                self.audioUnit = nil
            }
            return
        }

        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Output, AVAudioEngineDevice.kInputBus,
                                      &streamDescription, streamDescriptionSize)
        if status != 0 {
            debug("Could not set stream format on input bus!")
            return
        }

        debug("setupAudioUnit => setStreamDescription \n\tsize: \(streamDescriptionSize)\n\tstreamDescription: \(streamDescription)")
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Input, AVAudioEngineDevice.kOutputBus,
                                      &streamDescription, streamDescriptionSize)
        if status != 0 {
            debug("Could not set stream format on output bus!")
            return
        }

        // Enable the microphone input
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Input, AVAudioEngineDevice.kInputBus, &enableInput,
                                      uint32Size)

        if status != 0 {
            debug("Could not enable input bus!")
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
            return
        }

        // Setup the rendering callback.
        var renderCallback: AURenderCallbackStruct = AURenderCallbackStruct()
        renderCallback.inputProc = AVAudioEngineDevicePlayoutCallback
        renderCallback.inputProcRefCon = UnsafeMutableRawPointer(&self.renderingContext)
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback,
                                      kAudioUnitScope_Output, AVAudioEngineDevice.kOutputBus, &renderCallback,
                                      auRenderCallbackStructSize)
        if status != 0 {
            debug("Could not set rendering callback!")
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
            return
        }

        // Setup the capturing callback.
        var captureCallback: AURenderCallbackStruct = AURenderCallbackStruct()
        captureCallback.inputProc = AVAudioEngineDeviceRecordCallback
        captureCallback.inputProcRefCon = UnsafeMutableRawPointer(&self.capturingContext)
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback,
                                      kAudioUnitScope_Input, AVAudioEngineDevice.kInputBus, &captureCallback,
                                      auRenderCallbackStructSize)
        if status != 0 {
            debug("Could not set capturing callback!")
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
            return
        }

        var failedInitializeAttempts: NSInteger = 0
        while status != noErr {
            debug("Failed to initialize the Voice Processing I/O unit. Error= \(status).")
            failedInitializeAttempts += 1
            if failedInitializeAttempts == AVAudioEngineDevice.kMaxNumberOfAudioUnitInitializeAttempts {
                break
            }
            debug("Pause 100ms and try audio unit initialization again.")
            Thread.sleep(forTimeInterval: 0.1)
            status = AudioUnitInitialize(audioUnit)
        }

        // Finally, initialize and start the VoiceProcessingIO audio unit.
        if status != 0 {
            debug("Could not initialize the audio unit! => OSStatus: \(status)")
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
            return
        }

        self.capturingContext.audioUnit = audioUnit

        return
    }

    func startAudioUnit() -> Bool {
        debug("startAudioUnit => START\n\totherAudioPlaying: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
        guard let audioUnitUnwrapped = self.audioUnit else {
            return false
        }

        var result = false
        var failedInitializeAttempts: NSInteger = 0
        while failedInitializeAttempts < AVAudioEngineDevice.kMaxNumberOfAudioUnitInitializeAttempts {
            debug("startAudioUnit => failed attempts: \(failedInitializeAttempts)")
            let status: OSStatus = AudioOutputUnitStart(audioUnitUnwrapped)
            if status == noErr {
                result = true
                break
            }
            debug("Failed to start output on the Voice Processing I/O unit. Error= \(status).")
            failedInitializeAttempts += 1

            debug("Pause 100ms and try audio unit initialization again.")
            Thread.sleep(forTimeInterval: 0.1)
        }

        debug("startAudioUnit => END => started: \(result)\n\totherAudioPlaying: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
        return result
    }

    func stopAudioUnit() -> Bool {
        debug("stopAudioUnit => START")
        guard let audioUnitUnwrapped = self.audioUnit else {
            return false
        }

        let status: OSStatus = AudioOutputUnitStop(audioUnitUnwrapped)
        if status != 0 {
            debug("stopAudioUnit => END - Could not stop the audio unit!")
            return false
        }
        debug("stopAudioUnit => END")
        return true
    }

    func teardownAudioUnit() {
        debug("teardownAudioUnit => audioUnit: \(self.audioUnit)")
        if let audioUnitUnwrapped = self.audioUnit {
            AudioUnitUninitialize(audioUnitUnwrapped)
            AudioComponentInstanceDispose(audioUnitUnwrapped)
            self.audioUnit = nil
        }
    }

    // MARK: NSNotification Observers
    func deviceContext() -> AudioDeviceContext? {
        debug("deviceContext => rendering: \(self.renderingContext.deviceContext) capturing: \(self.capturingContext.deviceContext)")
        if self.renderingContext.deviceContext != nil {
            return self.renderingContext.deviceContext
        } else if self.capturingContext.deviceContext != nil {
            return self.capturingContext.deviceContext
        }
        return nil
    }

    func registerAVAudioSessionObservers() {
        debug("registerAVAudioSessionObservers")
        // An audio device that interacts with AVAudioSession should handle events like interruptions and route changes.
        var center: NotificationCenter = NotificationCenter.default

        center.removeObserver(self)

        center.addObserver(self, selector: #selector(handleAudioInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        /*
         * Interruption handling is different on iOS 9.x. If your application becomes interrupted while it is in the
         * background then you will not get a corresponding notification when the interruption ends. We workaround this
         * by handling UIApplicationDidBecomeActiveNotification and treating it as an interruption end.
         */
        center.addObserver(self, selector: #selector(handleApplicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        center.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)

        center.addObserver(self, selector: #selector(handleMediaServiceLost), name: AVAudioSession.mediaServicesWereLostNotification, object: nil)

        center.addObserver(self, selector: #selector(handleMediaServiceRestored), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }

    @objc private func handleAudioInterruption(notification: Notification) {
        debug("handleAudioInterruption => type: \(notification)")
        guard let userInfo = notification.userInfo,
              let reasonRaw = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type: AVAudioSession.InterruptionType = AVAudioSession.InterruptionType(rawValue: reasonRaw) else {
            debug("handleAudioInterruption => parse error")
            return
        }

        self.myPropertyQueue.async {
            // If the worker block is executed, then context is guaranteed to be valid.
            if let context = self.deviceContext() {
                AudioDeviceExecuteWorkerBlock(context: context) {
                    if type == AVAudioSession.InterruptionType.began {
                        debug("handleAudioInterruption => Interruption began.")
                        self.interrupted = true
                        self.stopAudioUnit()
                    } else {
                        debug("handleAudioInterruption => Interruption ended.")
                        self.interrupted = false
                        self.startAudioUnit()
                    }
                }
            } else {
                debug("handleAudioInterruption => Ignoring.")
            }
        }
    }

    @objc private func handleApplicationDidBecomeActive(notification: Notification) {
        debug("handleApplicationDidBecomeActive")
        self.myPropertyQueue.async {
            // If the worker block is executed, then context is guaranteed to be valid.
            if self.interrupted {
                debug("Synthesizing an interruption ended event for iOS 9.x devices.")
                self.interrupted = false

                if self.formatChanged() {
                    self.handleFormatChange("handleApplicationDidBecomeActive")
                }

                self.setupAVAudioSession()
                self.startAudioUnit()
                if self.audioPlayerNodeManager.anyPaused() {
                    self.audioPlayerNodeManager.resumeAll()
                }
            }
        }
    }

    @objc private func handleRouteChange(notification: NSNotification) {
        debug("handleRouteChange => notification: \(notification), sampleRate: \(AVAudioSession.sharedInstance().sampleRate)\n\totherAudioPlaying: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
        // Check if the sample rate, or channels changed and trigger a format change if it did.
        guard let userInfo = notification.userInfo,
              let reasonRaw = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw) else {
            debug("handleRouteChange => parse error")
            return
        }
        let session = AVAudioSession.sharedInstance()
        debug("handleRouteChange =>\n\treason: \(reason.rawValue)\n\tcategory: \(session.category)\n\tmode: \(session.mode)\n\tsampleRate: \(session.sampleRate)")

        switch reason {
            case AVAudioSession.RouteChangeReason.unknown:
                    debug("category: \(AVAudioSession.sharedInstance().category)")
            case AVAudioSession.RouteChangeReason.newDeviceAvailable,
                 AVAudioSession.RouteChangeReason.oldDeviceUnavailable,
                    // Each device change might cause the actual sample rate or channel configuration of the session to change.
                    // In iOS 9.2+ switching routes from a BT device in control center may cause a category change.
                 AVAudioSession.RouteChangeReason.categoryChange,
                 AVAudioSession.RouteChangeReason.override,
                 AVAudioSession.RouteChangeReason.wakeFromSleep,
                 AVAudioSession.RouteChangeReason.noSuitableRouteForCategory,
                 AVAudioSession.RouteChangeReason.routeConfigurationChange:
                    // With CallKit, AVAudioSession may change the sample rate during a configuration change.
                    // If a valid route change occurs we may want to update our audio graph to reflect the new output device.
                    debug("handleRouteChange => QUEUE - myPropertyQueue.async")
                    self.myPropertyQueue.async {
                        debug("handleRouteChange => START - myPropertyQueue.async")
                        self.handleValidRouteChange()
                        debug("handleRouteChange => END - myPropertyQueue.async")
                    }
            default:
                break
        }
    }

    func handleValidRouteChange() {
        debug("handleValidRouteChange")
        // Nothing to process while we are interrupted. We will interrogate the AVAudioSession once the interruption ends.
        if self.interrupted || self.audioUnit == nil {
            debug("handleValidRouteChange => do nothing\n\tinterrupted: \(self.interrupted)\n\taudioUnit: \(self.audioUnit)\n\totherAudioPlaying: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
            self.callAudioDeviceFormatChangedOnStart()
            return
        }

        debug("handleValidRouteChange => A route change ocurred while the AudioUnit was started. Checking the active audio format.")

        // Determine if the format actually changed. We only care about sample rate and number of channels.
        if self.formatChanged() {
            self.handleFormatChange("handleValidRouteChange")
            if let context = self.deviceContext() {
                // Video SDK is connected
                debug("handleValidRouteChange => BEGIN AudioDeviceFormatChanged")
                // Notify Video SDK about the format change
                self.notifyVideoSdkOfFormatChange(context: context)
                debug("handleValidRouteChange => END AudioDeviceFormatChanged")
            } else {
                // Video SDK is disconnected or connecting
                debug("handleValidRouteChange => BEGIN handleFormatChange")
                self.callAudioDeviceFormatChangedOnStart()
                debug("handleValidRouteChange => END handleFormatChange")
                if self.audioPlayerNodeManager.anyPaused() {
                    debug("handleValidRouteChange => BEGIN startRenderingInternal to resume audio nodes")
                    self.startRenderingInternal(context: self.deviceContext())
                    debug("handleValidRouteChange => END startRenderingInternal")
                }
            }
        } else {
            debug("handleValidRouteChange => Format unchanged, ignoring")
        }
    }

    func formatChanged() -> Bool {
        var result: Bool = false
        if let activeFormat: AudioFormat = activeFormat() {
            result = !activeFormat.isEqual(renderingFormat) || !activeFormat.isEqual(capturingFormat)
        } else {
            result = false
        }

        debug("formatChanged => \(result)")
        return result
    }

    func callAudioDeviceFormatChangedOnStart() {
        self.didFormatChangeWhileDisconnected = true
    }

    func notifyVideoSdkOfFormatChange(context: AudioDeviceContext?) {
        if let context = context {
            debug("notifyVideoSdkOfFormatChange")
            self.didFormatChangeWhileDisconnected = false
            // Notify Video SDK about the format change
            // `AudioDeviceFormatChanged` will cause the Video SDK to
            // read the new rendering/capturing formats from the AVAudioEngineDevice
            // using `renderFormat()` and `captureFormat()`, and subsequently
            // instruct the AVAudioEngineDevice to stop/start capturing and rendering.
            AudioDeviceFormatChanged(context: context)
        }
    }

    func handleFormatChange(_ caller: String) {
        debug("handleFormatChange => START - caller: \(caller)")
        self.stopAudioUnit()
        self.audioPlayerNodeManager.pauseAll(true)
        self.teardownAudioUnit()
        self.setupAudioUnit()
        self.detachMusicNodes()
        self.teardownAudioEngine()
        do {
            let result = try AVAudioSession.sharedInstance().setPreferredSampleRate(Double(AVAudioEngineDevice.kPreferredSampleRate))
            debug("handleFormatChange => setPreferredSampleRate result: \(result) sampleRate: \(AVAudioEngineDevice.kPreferredSampleRate)")
        } catch let error {
            debug("handleFormatChange => setPreferredSampleRate error: \(error)")
        }
        self.getMaximumSliceSize()
        self.deallocateMemoryForAudioBuffers()
        self.allocateMemoryForAudioBuffers()

        // Nodes will be reattached as part of setupPlayoutAudioEngine
        self.setupAudioEngine()
        // When to resume paused nodes left to calling functions
        debug("handleFormatChange => END")
    }

    @objc private func handleMediaServiceLost(notification: Notification) {
        debug("handleMediaServiceLost")

        self.myPropertyQueue.async {
            self.interrupted = true
            self.stopAudioUnit()
            self.audioPlayerNodeManager.pauseAll(true)
            self.teardownAudioUnit()
            self.detachMusicNodes()
            self.teardownAudioEngine()
            self.deallocateMemoryForAudioBuffers()
        }
    }

    // Reference: https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/HandlingAudioInterruptions/HandlingAudioInterruptions.html#//apple_ref/doc/uid/TP40007875-CH4-SW8
    @objc private func handleMediaServiceRestored(notification: Notification) {
        debug("handleMediaServiceRestored")

        self.myPropertyQueue.async {
            self.interrupted = false
            self.setupAudioUnit()
            self.getMaximumSliceSize()
            do {
                let result = try AVAudioSession.sharedInstance().setPreferredSampleRate(Double(AVAudioEngineDevice.kPreferredSampleRate))
                debug("handleFormatChange => setPreferredSampleRate result: \(result) sampleRate: \(AVAudioEngineDevice.kPreferredSampleRate)")
            } catch let error {
                debug("handleFormatChange => setPreferredSampleRate error: \(error)")
            }
            self.allocateMemoryForAudioBuffers()
            self.setupAudioEngine()
            // If the worker block is executed, then context is guaranteed to be valid.
            self.setupAVAudioSession()
            if !self.startAudioUnit() {
                self.interrupted = true
                return
            }

            if self.audioPlayerNodeManager.anyPaused() {
                self.startRenderingInternal(context: self.deviceContext())
                self.audioPlayerNodeManager.resumeAll()
            }

            if let deviceContext = self.deviceContext() {
                self.notifyVideoSdkOfFormatChange(context: deviceContext)
            }
        }
    }
}

// MARK: Private (AudioUnit callbacks)
// swiftlint:disable:next function_parameter_count
func AVAudioEngineDevicePlayoutCallback(inRefCon: UnsafeMutableRawPointer,
                                        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                                        inTimestamp: UnsafePointer<AudioTimeStamp>,
                                        inBusNumber: UInt32,
                                        inNumberFrames: UInt32,
                                        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    let abl = UnsafeMutableAudioBufferListPointer(ioData)

    guard let ioData = ioData else {
        return noErr
    }
    assert(ioData.pointee.mNumberBuffers == 1)
    assert(ioData.pointee.mBuffers.mNumberChannels <= 2)
    assert(ioData.pointee.mBuffers.mNumberChannels > 0)

    var context = inRefCon.assumingMemoryBound(to: AudioRendererContext.self)
    context.pointee.bufferList?.unsafeMutablePointer.initialize(to: ioData.pointee)

    var audioBufferSizeInBytes: UInt32 = ioData.pointee.mBuffers.mDataByteSize

    // Pull decoded, mixed audio data from the media engine into the AudioUnit's AudioBufferList.
    assert(audioBufferSizeInBytes == (ioData.pointee.mBuffers.mNumberChannels * AVAudioEngineDevice.kAudioSampleSize * inNumberFrames))
    var outputStatus: OSStatus = noErr

    // Get the mixed audio data from AVAudioEngine's output node by calling the `renderBlock`
    guard let renderBlock: AVAudioEngineManualRenderingBlock = context.pointee.renderBlock,
        let maxFramesPerBuffer = context.pointee.maxFramesPerBuffer else {
        return outputStatus
    }

    // Next log statement left in for debugging purposes. Commented out to minimize operations on the real time audio thread, and noise in the console.
    debugAudio("PlayoutCallback =>\n\tinNumberOfFrames: \(inNumberFrames)\n\taudioBufferSizeInBytes: \(audioBufferSizeInBytes)" +
    "\n\tabl buffer: \(abl?.first?.mData?.assumingMemoryBound(to: Int8.self).pointee)\n\tinput buffer: \(ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: Int8.self).pointee)")
    let status: AVAudioEngineManualRenderingStatus = renderBlock(inNumberFrames, ioData, &outputStatus)

    /*
     * Render silence if there are temporary mismatches between CoreAudio and our rendering format or AVAudioEngine
     * could not render the audio samples.
     */
    if inNumberFrames > maxFramesPerBuffer || status != AVAudioEngineManualRenderingStatus.success {
        if inNumberFrames > maxFramesPerBuffer {
            debug("PlayoutCallback => Can handle a max of \(maxFramesPerBuffer) frames but got \(inNumberFrames). Status: \(status.rawValue) OutputStatus: \(outputStatus)")
        }
        // Next line left in for debugging purposes. Commented out to minimize operations on the real time audio thread
        debugAudio("PlayoutCallback => render silence - outputStatus: \(outputStatus) status: \(status.rawValue)")
        ioActionFlags.pointee = AudioUnitRenderActionFlags(rawValue: ioActionFlags.pointee.rawValue | AudioUnitRenderActionFlags.unitRenderAction_OutputIsSilence.rawValue)
        memset(ioData.pointee.mBuffers.mData, 0, Int(audioBufferSizeInBytes))
    }

    // Next line left in for debugging purposes. Commented out to minimize operations on the real time audio thread
    debugAudio("PlayoutCallback => END inputData: \(ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: Int8.self).pointee) outputStatus: \(outputStatus) status: \(status.rawValue)")
    return noErr
}

// swiftlint:disable:next function_parameter_count function_body_length
func AVAudioEngineDeviceRecordCallback(inRefCon: UnsafeMutableRawPointer,
                                       ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                                       inTimestamp: UnsafePointer<AudioTimeStamp>,
                                       inBusNumber: UInt32,
                                       inNumberFrames: UInt32,
                                       ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    if inNumberFrames > AVAudioEngineDevice.kMaximumFramesPerBuffer {
        debug("RecordCallback => Expected no more than \(AVAudioEngineDevice.kMaximumFramesPerBuffer) frames but got \(inNumberFrames).")
        return noErr
    }

    var context = inRefCon.assumingMemoryBound(to: AudioCapturerContext.self)

    if context.pointee.deviceContext == nil {
        return noErr
    }

    guard let abl = context.pointee.bufferList else {
        return noErr
    }

    abl.unsafeMutablePointer.pointee.mBuffers.mDataByteSize = inNumberFrames * UInt32(MemoryLayout<UInt16>.size) * AVAudioEngineDevice.kPreferredNumberOfChannels
    // The buffer will be filled by VoiceProcessingIO AudioUnit
    abl.unsafeMutablePointer.pointee.mBuffers.mData = nil

    guard let audioUnit = context.pointee.audioUnit else {
        debug("RecordCallback => Expected AudioCapturerContext to have AudioUnit.")
        return noErr
    }
    // Next log statement left in for debugging purposes. Commented out to minimize operations on the real time audio thread, and noise in the console.
     debugAudio("RecordCallback => BEGIN AudioUnitRender:\n\tcontext bufferList: \(context.pointee.bufferList?.first?.mData?.assumingMemoryBound(to: Int8.self).pointee)" +
     "\n\ttabl bufferList: \(abl.first?.mData?.assumingMemoryBound(to: Int8.self).pointee)")
    var status: OSStatus = noErr
    status = AudioUnitRender(audioUnit,
                             ioActionFlags,
                             inTimestamp,
                             1,
                             inNumberFrames,
                             abl.unsafeMutablePointer)

    if context.pointee.mixedAudioBufferList?.pointee == nil {
        debug("RecordCallback => mixedAudioBufferList points to nil")
        return noErr
    }

    var mixedAudioBufferList: UnsafeMutablePointer<AudioBufferList> = UnsafeMutablePointer<AudioBufferList>( &context.pointee.mixedAudioBufferList!.pointee!)

    if let numberChannels = abl.first?.mNumberChannels {
        mixedAudioBufferList.pointee.mBuffers.mNumberChannels = numberChannels
    }

    if let dataByteSize = abl.first?.mDataByteSize {
        mixedAudioBufferList.pointee.mBuffers.mDataByteSize = dataByteSize
    }

    guard let renderBlock: AVAudioEngineManualRenderingBlock = context.pointee.renderBlock else {
        return noErr
    }

    var outputStatus: OSStatus = noErr

    // Next line left in for debugging purposes. Commented out to minimize operations on the real time audio thread
    debugAudio("RecordCallback => BEGIN renderBlock:\n\tmixedAudioBufferList: \(mixedAudioBufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Int8.self).pointee)\n\tinNumberFrames: \(inNumberFrames)")
    let ret: AVAudioEngineManualRenderingStatus = renderBlock(inNumberFrames, mixedAudioBufferList, &outputStatus)
    debugAudio("RecordCallback => END renderBlock:\n\tmixedAudioBufferList: \(mixedAudioBufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Int8.self).pointee)")

    if ret != AVAudioEngineManualRenderingStatus.success {
        debug("RecordCallback => AVAudioEngine failed mix audio => \(String(describing: ret.rawValue)), outputStatus: \(outputStatus)")
    }

    if let audioBuffer = mixedAudioBufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Int8.self),
       let deviceContext = context.pointee.deviceContext {
        AudioDeviceWriteCaptureData(context: deviceContext, data: audioBuffer, sizeInBytes: Int(mixedAudioBufferList.pointee.mBuffers.mDataByteSize))
    }

    return noErr
}

class AudioRendererContext {
    // Audio device context received in AudioDevice's `startRendering:context` callback.
    var deviceContext: AudioDeviceContext?

    // Maximum frames per buffer.
    var maxFramesPerBuffer: Int?

    // Buffer passed to AVAudioEngine's manualRenderingBlock to receive the mixed audio data.
    var bufferList: UnsafeMutableAudioBufferListPointer?

    /*
     * Points to AVAudioEngine's manualRenderingBlock. This block is called from within the VoiceProcessingIO playout
     * callback in order to receive mixed audio data from AVAudioEngine in real time.
     */
    var renderBlock: AVAudioEngineManualRenderingBlock?
}

class AudioCapturerContext {
    // Audio device context received in AudioDevice's `startCapturing:context` callback.
    var deviceContext: AudioDeviceContext?

    // Preallocated buffer list. Please note the buffer itself will be provided by Core Audio's VoiceProcessingIO audio unit.
    var bufferList: UnsafeMutableAudioBufferListPointer?

    // Preallocated mixed (AudioUnit mic + AVAudioPlayerNode file) audio buffer list.
    var mixedAudioBufferList: UnsafeMutablePointer<AudioBufferList?>?

    // Core Audio's VoiceProcessingIO audio unit.
    var audioUnit: AudioUnit?

    /*
     * Points to AVAudioEngine's manualRenderingBlock. This block is called from within the VoiceProcessingIO playout
     * callback in order to receive mixed audio data from AVAudioEngine in real time.
     */
    var renderBlock: AVAudioEngineManualRenderingBlock?
}

// Can swap internal usage to NSLog if you need to guarantee logging at app startup
internal func debug(_ msg: String) {
    SwiftTwilioProgrammableVideoPlugin.debugAudio("AVAudioEngineDevice::\(msg)")
}

internal func debugAudio(_ msg: String) {
    if AVAudioEngineDevice.audioDebug {
        NSLog("AVAudioEngineDevice::\(msg)")
    }
}
