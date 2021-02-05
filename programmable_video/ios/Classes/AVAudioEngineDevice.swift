// swiftlint:disable file_length

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
    var interrupted: Bool = false
    var isStartingRenderer: Bool = false
    var isStoppingRenderer: Bool = false
    var isRendering: Bool = false
    var audioUnit: AudioUnit?
    var captureBufferList: AudioBufferList = AudioBufferList()

    var renderingFormat: AudioFormat?
    var capturingFormat: AudioFormat?
    var renderingContext: AudioRendererContext
    var capturingContext: AudioCapturerContext

    // AudioEngine properties
    var playoutEngine: AVAudioEngine?
    var recordEngine: AVAudioEngine?

    let audioPlayerNodeManager: AVAudioPlayerNodeManager = AVAudioPlayerNodeManager()

    // MARK: Init & Dealloc

    override public init() {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::init => START")
        /*
         * Initialize rendering and capturing context. The deviceContext will be be filled in when startRendering or
         * startCapturing gets called.
         */
        self.renderingContext = AudioRendererContext()
        self.capturingContext = AudioCapturerContext(
            bufferList: UnsafeMutablePointer<AudioBufferList>(&self.captureBufferList),
            mixedAudioBufferList: UnsafeMutablePointer<AudioBufferList?>.allocate(
                capacity: MemoryLayout<AudioBufferList>.size))
        self.capturingContext.mixedAudioBufferList.initialize(to: nil)
        super.init()

        // Setup the AVAudioEngine along with the rendering context
        if !self.setupPlayoutAudioEngine() {
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to setup AVAudioEngine")
        }

        // Setup the AVAudioEngine along with the rendering context
        if !self.setupRecordAudioEngine() {
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to setup AVAudioEngine")
        }

        self.setupAVAudioSession()
        self.renderFormat()
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::init => END")
    }

    deinit {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::deinit")
        self.disposeAllNodes()
        self.stopRendering()
        self.stopCapturing()
        NotificationCenter.default.removeObserver(self)
        self.teardownAudioEngine()

        self.capturingContext.bufferList.deallocate()
        self.capturingContext.mixedAudioBufferList.deallocate()
    }

    func description() -> NSString {
        return "AVAudioEngine Audio Mixing"
    }

    /*
     * Determine at runtime the maximum slice size used by VoiceProcessingIO. Setting the stream format and sample rate
     * doesn't appear to impact the maximum size so we prefer to read this value once at initialization time.
     */
    func initialize() {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::initialize")
        var audioUnitDescription: AudioComponentDescription = AVAudioEngineDevice.audioUnitDescription()
        guard let audioComponent: AudioComponent = AudioComponentFindNext(nil, &audioUnitDescription) else {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not retrieve AudioComponents!")
            return
        }
        var audioUnitRaw: AudioUnit?
        var status: OSStatus = AudioComponentInstanceNew(audioComponent, &audioUnitRaw)
        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not find VoiceProcessingIO AudioComponent instance!")
            return
        }

        guard let audioUnit = audioUnitRaw else {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not find VoiceProcessingIO AudioComponent instance!")
            return
        }

        var framesPerSlice: UInt32 = 0
        var propertySize: UInt32 = UInt32(MemoryLayout<UInt32>.size)
        status = AudioUnitGetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global, AVAudioEngineDevice.kOutputBus,
                                      &framesPerSlice, &propertySize)
        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not read VoiceProcessingIO AudioComponent instance!")
            AudioComponentInstanceDispose(audioUnit)
            return
        }

        SwiftTwilioProgrammableVideoPlugin.debug("This device uses a maximum slice size of \(framesPerSlice) frames.")
        AVAudioEngineDevice.kMaximumFramesPerBuffer = framesPerSlice
        AudioComponentInstanceDispose(audioUnit)

        var bufferListData = UnsafeMutablePointer<Int8>.allocate(capacity: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer * AVAudioEngineDevice.kPreferredNumberOfChannels * AVAudioEngineDevice.kAudioSampleSize))

        renderingContext.bufferList = AudioBufferList(mNumberBuffers: 1,
                                                      mBuffers: AudioBuffer(
                                                       mNumberChannels: AVAudioEngineDevice.kPreferredNumberOfChannels,
                                                       mDataByteSize: UInt32(0),
                                                       mData: bufferListData))
    }

    // MARK: Private (AVAudioEngine)

    func setupAudioEngine() -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::setupAudioEngine")
        return self.setupPlayoutAudioEngine() && self.setupRecordAudioEngine()
    }

    func setupRecordAudioEngine() -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::setupRecordAudioEngine")
        assert(recordEngine == nil, "AVAudioEngine is already configured")

        /*
         * By default AVAudioEngine will render to/from the audio device, and automatically establish connections between
         * nodes, e.g. inputNode -> effectNode -> outputNode.
         */
        recordEngine = AVAudioEngine()
        guard let engine = recordEngine else {
            return false
        }

        // AVAudioEngine operates on the same format as the Core Audio output bus.
        guard let activeFormat = AVAudioEngineDevice.activeFormat() else {
            return false
        }

        var asbd: AudioStreamBasicDescription = activeFormat.streamDescription()

        guard let format = AVAudioFormat(streamDescription: &asbd) else {
            return false
        }

        // Switch to manual rendering mode
        engine.stop()
        do {
            try engine.enableManualRenderingMode(AVAudioEngineManualRenderingMode.realtime, format: format, maximumFrameCount: AVAudioEngineDevice.kMaximumFramesPerBuffer)
        } catch let error {
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to setup manual rendering mode, error = \(error)")
            return false
        }

        /*
         * In manual rendering mode, AVAudioEngine won't receive audio from the microphone. Instead, it will receive the
         * audio data from the Video SDK and mix it in MainMixerNode. Here we connect the input node to the main mixer node.
         * InputNode -> MainMixer -> OutputNode
         */
        engine.connect(engine.inputNode, to: engine.mainMixerNode, format: format)

        /*
         * Attach AVAudioPlayerNode node to play music from a file.
         * AVAudioPlayerNode -> ReverbNode -> MainMixer -> OutputNode (note: ReverbNode is optional)
         */

        // Set the block to provide input data to engine
        let inputNode: AVAudioInputNode = engine.inputNode
        var success: Bool = inputNode.setManualRenderingInputPCMFormat(format) { (inNumberOfFrames: AVAudioFrameCount) -> UnsafePointer<AudioBufferList>? in
            assert(inNumberOfFrames <= AVAudioEngineDevice.kMaximumFramesPerBuffer)
            return UnsafePointer<AudioBufferList>(self.capturingContext.bufferList)
        }

        if !success {
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to set the manual rendering block")
            return false
        }

        // The manual rendering block (called in Core Audio's VoiceProcessingIO's playout callback at real time)
        self.capturingContext.renderBlock = engine.manualRenderingBlock

        do {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngine::setupRecordAudioEngine => start engine")
            try engine.start()
        } catch let error {
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to start AVAudioEngine, error = \(error)")
            return false
        }

        return true
    }

    // swiftlint:disable:next function_body_length
    func setupPlayoutAudioEngine() -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::setupPlayoutAudioEngine")
        assert(self.playoutEngine == nil, "AVAudioEngine is already configured")

        /*
         * By default AVAudioEngine will render to/from the audio device, and automatically establish connections between
         * nodes, e.g. inputNode -> effectNode -> outputNode.
         */
        self.playoutEngine = AVAudioEngine()

        // AVAudioEngine operates on the same format as the Core Audio output bus.
        guard let activeFormat = AVAudioEngineDevice.activeFormat() else {
            return false
        }

        guard let engine = self.playoutEngine else {
            return false
        }

        var asbd: AudioStreamBasicDescription = activeFormat.streamDescription()
        guard let format = AVAudioFormat(streamDescription: &asbd) else {
            return false
        }

        // Switch to manual rendering mode
        engine.stop()
        do {
            try engine.enableManualRenderingMode(AVAudioEngineManualRenderingMode.realtime, format: format, maximumFrameCount: AVAudioEngineDevice.kMaximumFramesPerBuffer)
        } catch let error {
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to setup manual rendering mode, error = \(error)")
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
            assert(inNumberOfFrames <= AVAudioEngineDevice.kMaximumFramesPerBuffer)

            let context: AudioRendererContext = self.renderingContext
            let bufferList = context.bufferList

            guard let audioBuffer = self.renderingContext.bufferList.mBuffers.mData?.assumingMemoryBound(to: Int8.self) else {
                return nil
            }

            var audioBufferSizeInBytes: Int = Int(self.renderingContext.bufferList.mBuffers.mDataByteSize)

            if var deviceContext = context.deviceContext {
                /*
                 * Pull decoded, mixed audio data from the media engine into the
                 * AudioUnit's AudioBufferList.
                 */
                AudioDeviceReadRenderData(context: deviceContext, data: audioBuffer, sizeInBytes: audioBufferSizeInBytes)
            } else {
                /*
                 * Return silence when we do not have the playout device context. This is the
                 * case when the remote participant has not published an audio track yet.
                 * Since the audio graph and audio engine has been setup, we can still play
                 * the music file using AVAudioEngine.
                 */
                memset(audioBuffer, 0, audioBufferSizeInBytes)
            }

            var result = bufferList
            return UnsafePointer<AudioBufferList>(&result)
        }

        if !success {
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to set the manual rendering block")
            return false
        }

        // The manual rendering block (called in Core Audio's VoiceProcessingIO's playout callback at real time)
        self.renderingContext.renderBlock = engine.manualRenderingBlock

        do {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngine::setupPlayoutAudioEngine => start engine")
            try engine.start()
        } catch let error {
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to start AVAudioEngine, error = \(error)")
            return false
        }

        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::setupPlayoutAudioEngine => end")
        return true
    }

    func teardownRecordAudioEngine() {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::teardownRecordAudioEngine")
        if let engine = self.recordEngine {
            engine.stop()
            self.recordEngine = nil
        }
    }

    func teardownPlayoutAudioEngine() {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::teardownPlayoutAudioEngine")
        if let engine = self.playoutEngine, engine.isRunning {
            engine.stop()
        }
        self.playoutEngine = nil
    }

    func teardownAudioEngine() {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::teardownAudioEngine")
        self.teardownPlayoutAudioEngine()
        self.teardownRecordAudioEngine()
    }

    // MARK: Audio File Playback API

    public func playMusic(_ id: Int) {
        safelyPlayMusic {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::playMusic => QUEUE - DispatchQueue.main.async")
            DispatchQueue.main.async {
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::playMusic => START - DispatchQueue.main.async id: \(id)")
                self.audioPlayerNodeManager.playNode(id)
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::playMusic => END - DispatchQueue.main.async: \(id)")
            }
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::playMusic => END")
        }
    }

    func safelyPlayMusic(_ playCallback: @escaping () -> Void) {
        myPropertyQueue.async {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::safelyPlayMusic => START - myPropertyQueue.async")
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::playMusic => startingRenderer: \(self.isStartingRenderer), isRendering: \(self.isRendering), stoppingRenderer: \(self.isStoppingRenderer)")

            // Could collapse isRendering/isStartingRenderer/isStoppingRenderer into a single state enum
            if self.isRendering {
                    SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::playMusic => scheduleMusicOnPlayoutEngine => dispatch")
                // Since the engine is already rendering, no need to queue playCallback on myPropertyQueue to ensure that it occurs after rendering is started
                playCallback()
            } else if self.isStartingRenderer {
                self.myPropertyQueue.async {
                    playCallback()
                }
            } else {
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::playMusic => startRendering")

                if self.startRenderingInternal(context: nil) {
                    SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::playMusic => startRendering => scheduleMusicOnPlayoutEngine")
                    self.myPropertyQueue.async {
                        playCallback()
                    }
                } else {
                    SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::playMusic => startRendering failed")
                }
            }
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::safelyPlayMusic => END - myPropertyQueue.async")
        }
    }

    public func stopMusic(_ id: Int) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopMusic => \(id)")
        self.audioPlayerNodeManager.stopNode(id)

        if !self.audioPlayerNodeManager.anyPlaying(),
           !self.audioPlayerNodeManager.anyPaused(),
           self.renderingContext.deviceContext == nil,
            !self.isStartingRenderer,
            !self.isStoppingRenderer {
            self.stopRendering()
        }
    }

    public func pauseMusic(_ id: Int) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::pauseNode => \(id)")
        self.audioPlayerNodeManager.pauseNode(id)
    }

    public func resumeMusic(_ id: Int) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::resumeMusic => \(id)")
        self.audioPlayerNodeManager.resumeNode(id)
    }

    public func setMusicVolume(_ id: Int, _ volume: Double) {
        self.audioPlayerNodeManager.setMusicVolume(id, volume)
    }

    public func seekPosition(_ id: Int, _ positionInMillis: Int) {
        safelyPlayMusic {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::seekPosition => QUEUE - DispatchQueue.main.async")
            DispatchQueue.main.async {
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::seekPosition => START - DispatchQueue.main.async")
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::seekPosition => id: \(id), positionInMillis: \(positionInMillis)")
                self.audioPlayerNodeManager.seekPosition(id, Int64(positionInMillis))
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::seekPosition => END - DispatchQueue.main.async")
            }
        }
    }

    public func getPosition(_ id: Int) -> Int64 {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::getPosition => id: \(id)")
        return self.audioPlayerNodeManager.getPosition(id)
    }

    func disposeAllNodes() {
        self.audioPlayerNodeManager.nodes.keys.forEach { (id) in
            disposeMusicNode(id)
        }
    }

    public func disposeMusicNode(_ id: Int) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::disposeMusicNode => id: \(id)")
        guard let playoutEngine = self.playoutEngine,
              let node = self.audioPlayerNodeManager.getNode(id) else {
            return
        }

        stopMusic(id)

        playoutEngine.disconnectNodeOutput(node.eq)
        playoutEngine.disconnectNodeOutput(node.reverb)
        playoutEngine.disconnectNodeOutput(node.player)

        playoutEngine.detach(node.eq)
        playoutEngine.detach(node.reverb)
        playoutEngine.detach(node.player)

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
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::reattachMusicNodes")
        self.audioPlayerNodeManager.nodes.values.forEach { (_ node: AVAudioPlayerNodeBundle) in
            attachMusicNode(node)
        }
    }

    func attachMusicNode(_ nodeBundle: AVAudioPlayerNodeBundle) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::attachMusicNode => node: \(nodeBundle.id)")
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

    // MARK: TVIAudioDeviceRenderer

    public func renderFormat() -> AudioFormat? {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::renderFormat")
        if renderingFormat == nil, let activeFormat = AVAudioEngineDevice.activeFormat() {
            /*
             * Assume that the AVAudioSession has already been configured and started and that the values
             * for sampleRate and IOBufferDuration are final.
             */
            renderingFormat = activeFormat
            self.renderingContext.maxFramesPerBuffer = activeFormat.framesPerBuffer
        }

        return renderingFormat
    }

    public func initializeRenderer() -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::initializeRenderer")
        /*
         * In this example we don't need any fixed size buffers or other pre-allocated resources. We will simply write
         * directly to the AudioBufferList provided in the AudioUnit's rendering callback.
         */
        return true
    }

    public func startRendering(context: AudioDeviceContext?) -> Bool {
        var result: Bool = false

        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRendering => START - deviceContext: \(context), onMain: \(Thread.current.isMainThread), isRendering: \(self.isRendering)")
        myPropertyQueue.sync {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRendering => START - myPropertyQueue.sync")
            result = self.startRenderingInternal(context: context)
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRendering => END - myPropertyQueue.sync")
        }

        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRendering => END")
        return result
    }

    // swiftlint:disable:next function_body_length
    func startRenderingInternal(context: AudioDeviceContext?) -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRenderingInternal => START - current thread main: \(Thread.current.isMainThread)")

        var result = false

        self.isStartingRenderer = true
        self.isRendering = false
        self.renderingContext.deviceContext = context

        // Pause active audio player nodes while engine is restarted
        if self.audioPlayerNodeManager.anyPlaying() {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRenderingInternal => pause active audio nodes")
            /*
            * Since startRenderingInternal should always be run on the local DispatchQueue
            * we do not need to dispatch this call here. Further, we want to ensure this
            * completes execution prior to stopping the audio unit.
            */
            self.audioPlayerNodeManager.pauseAll(true)
        }

        /*
         * We will restart the audio unit if a remote participant adds an audio track after the audio graph is
         * established. Also we will re-establish the audio graph in case the format changes.
         *
         * We will start the audioGraph if playback of an attached audio node is requested while
         * rendering is not already underway.
         */
        if self.audioUnit != nil {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRenderingInternal => stop audioUnit")
            self.stopAudioUnit()
            self.teardownAudioUnit()
        }

        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRenderingInternal => QUEUE - DispatchQueue.main.async")
        // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.
        DispatchQueue.main.async {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRenderingInternal => START - DispatchQueue.main.async")

            if let engine = self.playoutEngine,
               let engineFormat = AudioFormat(
                channels: Int(engine.manualRenderingFormat.channelCount),
                sampleRate: UInt32(engine.manualRenderingFormat.sampleRate),
                framesPerBuffer: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)),
               let activeFormat = AVAudioEngineDevice.activeFormat(),
               engineFormat.isEqual(activeFormat) {
                if engine.isRunning {
                    SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRenderingInternal => stopping engine")
                    engine.stop()
                }

                do {
                    SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRenderingInternal => starting engine")
                    try engine.start()
                } catch let error {
                    SwiftTwilioProgrammableVideoPlugin.debug("Failed to start AVAudioEngine, error = \(error)")
                }
            } else {
            /*
             * If the engine is not configured properly we will tear it down,
             * restart it, reattach audio nodes as needed.
             */
                self.teardownPlayoutAudioEngine()
                self.setupPlayoutAudioEngine()
            }

            // Resume playback on audio player nodes that were active prior to engine restart
            if self.audioPlayerNodeManager.anyPaused() {
                /*
                 * ensure fadeIn/resume is happening on the same queue as other
                 * requests to change player state
                 */
                self.myPropertyQueue.async {
                    self.audioPlayerNodeManager.resumeAll()
                }
            }
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRenderingInternal => END - DispatchQueue.main.async")
        }

        if !self.setupAudioUnitWithRenderContext(renderContext: &self.renderingContext, captureContext: &self.capturingContext) {
            result = false
            self.isStartingRenderer = false
            self.isRendering = false
            return false
        }

        result = self.startAudioUnit()

        self.isStartingRenderer = false
        self.isRendering = true

        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startRenderingInternal => END")

        return result
    }

    public func stopRendering() -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopRendering => nodes playing: \(self.audioPlayerNodeManager.anyPlaying()), nodes paused: \(self.audioPlayerNodeManager.anyPaused())")
        self.isStoppingRenderer = true
        self.isRendering = false
        myPropertyQueue.async {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopRendering => START - myPropertyQueue.async")
            // If the capturer is running, we will not stop the audio unit.
            if self.capturingContext.deviceContext == nil,
               !self.audioPlayerNodeManager.anyPlaying(),
               !self.audioPlayerNodeManager.anyPaused() {
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopRendering => stopAudioUnit")
                self.stopAudioUnit()
                self.teardownAudioUnit()
            }

            self.renderingContext.deviceContext = nil
            if let engine = self.playoutEngine,
               engine.isRunning,
               !self.audioPlayerNodeManager.anyPlaying(),
               !self.audioPlayerNodeManager.anyPaused() {
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopRendering => QUEUE - DispatchQueue.main.async")
                // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.
                DispatchQueue.main.async {
                    SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopRendering => START - DispatchQueue.main.async")

                    // If audio player nodes are in use, we will not stop the engine
                    if let engine = self.playoutEngine {
                        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopRendering => stop playoutEngine")
                        engine.stop()
                    }
                    SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopRendering => END - DispatchQueue.main.async")
                    self.isStoppingRenderer = false
                }
            } else {
                self.isStoppingRenderer = false
            }
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopRendering => END - myPropertyQueue.async")
        }

        return true
    }

    // MARK: AudioDeviceCapturer
    public func captureFormat() -> AudioFormat? {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::captureFormat")
        if capturingFormat == nil {
            /*
             * Assume that the AVAudioSession has already been configured and started and that the values
             * for sampleRate and IOBufferDuration are final.
             */
            capturingFormat = AVAudioEngineDevice.activeFormat()
        }

        return capturingFormat
    }

    public func initializeCapturer() -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::initializeCapturer")
        captureBufferList.mNumberBuffers = 1
        captureBufferList.mBuffers.mNumberChannels = AVAudioEngineDevice.kPreferredNumberOfChannels

        if self.capturingContext.mixedAudioBufferList.pointee == nil {
            var pMixedAudioBufferListData = UnsafeMutablePointer<Int8>.allocate(capacity: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer * AVAudioEngineDevice.kPreferredNumberOfChannels * AVAudioEngineDevice.kAudioSampleSize))
            self.capturingContext.mixedAudioBufferList.pointee = AudioBufferList(
                                                   mNumberBuffers: 1,
                                                   mBuffers: AudioBuffer(
                                                    mNumberChannels: AVAudioEngineDevice.kPreferredNumberOfChannels,
                                                    mDataByteSize: UInt32(0),
                                                    mData: pMixedAudioBufferListData
                                                   ))
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::initializeCapturer => initialized mixAudioBufferList")
        }

        return true
    }

    public func startCapturing(context: AudioDeviceContext) -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing")
        var result: Bool = true
        myPropertyQueue.sync {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing - START - myPropertyQueue.async")
            // Restart the audio unit if the audio graph is alreay setup and if we publish an audio track.
            if self.audioUnit != nil {
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing => stop audioUnit")
                self.stopAudioUnit()
                self.teardownAudioUnit()
            }

            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing => QUEUE - DispatchQueue.main.async")
            // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.
            DispatchQueue.main.async {
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing => START - DispatchQueue.main.async")
                if let engine = self.recordEngine,
                   let engineFormat = AudioFormat(
                    channels: Int(engine.manualRenderingFormat.channelCount),
                    sampleRate: UInt32(engine.manualRenderingFormat.sampleRate),
                    framesPerBuffer: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)),
                   let activeFormat = AVAudioEngineDevice.activeFormat(),
                   engineFormat.isEqual(activeFormat) {
                    if engine.isRunning {
                        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing => stopping engine")
                        engine.stop()
                    }

                    do {
                        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing => starting engine")
                        try engine.start()
                    } catch let error {
                        SwiftTwilioProgrammableVideoPlugin.debug("Failed to start AVAudioEngine, error = \(error)")
                    }
                } else {
                    self.teardownRecordAudioEngine()
                    self.setupRecordAudioEngine()
                }
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing => END - DispatchQueue.main.async")
            }

            self.capturingContext.deviceContext = context

            if !self.setupAudioUnitWithRenderContext(renderContext: &self.renderingContext, captureContext: &self.capturingContext) {
                result = false
                return
            }

            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing => startAudioUnit")
            result = self.startAudioUnit()
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startCapturing - END - myPropertyQueue.async")
            return
        }

        return result
    }

    public func stopCapturing() -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopCapturing => nodes playing: \(self.audioPlayerNodeManager.anyPlaying()), nodes paused: \(self.audioPlayerNodeManager.anyPaused())")
        myPropertyQueue.async {
            // If the renderer is in use by a remote participants audio track, or audio player nodes, we will not stop the audio unit.
            if self.renderingContext.deviceContext == nil,
               !self.audioPlayerNodeManager.anyPlaying(),
               !self.audioPlayerNodeManager.anyPaused() {
                self.stopAudioUnit()
                self.teardownAudioUnit()
            }
            self.capturingContext.deviceContext = nil
            self.capturingContext.audioUnit = nil

            // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopCapturing => QUEUE - DispatchQueue.main.async")
            DispatchQueue.main.async {
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopCapturing => START - DispatchQueue.main.async")
                if let engine = self.recordEngine, engine.isRunning {
                    SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopCapturing => stop recordEngine")
                    engine.stop()
                }
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopCapturing => END - DispatchQueue.main.async")
            }
        }

        return true
    }

    // MARK: Private (AVAudioSession and CoreAudio)

    static func activeFormat() -> AudioFormat? {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::activeFormat")
        /*
         * Use the pre-determined maximum frame size. AudioUnit callbacks are variable, and in most sitations will be close
         * to the `AVAudioSession.preferredIOBufferDuration` that we've requested.
         */
        let sessionFramesPerBuffer: Int = Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)
        let sessionSampleRate: UInt32 = UInt32(AVAudioSession.sharedInstance().sampleRate)

        return AudioFormat(channels: AudioFormat.ChannelsMono, sampleRate: sessionSampleRate, framesPerBuffer: sessionFramesPerBuffer)
    }

    static func audioUnitDescription() -> AudioComponentDescription {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::audioUnitDescription")
        var audioUnitDescription: AudioComponentDescription = AudioComponentDescription()
        audioUnitDescription.componentType = kAudioUnitType_Output
        audioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO
        audioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple
        audioUnitDescription.componentFlags = 0
        audioUnitDescription.componentFlagsMask = 0
        return audioUnitDescription
    }

    func setupAVAudioSession() {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::setupAVAudioSession")
        let session: AVAudioSession = AVAudioSession.sharedInstance()

        do {
            try session.setPreferredSampleRate(Double(AVAudioEngineDevice.kPreferredSampleRate))
            try session.setPreferredOutputNumberOfChannels(Int(AVAudioEngineDevice.kPreferredNumberOfChannels))
            /*
             * We want to be as close as possible to the 10 millisecond buffer size that the media engine needs. If there is
             * a mismatch then TwilioVideo will ensure that appropriately sized audio buffers are delivered.
             */
            try session.setPreferredIOBufferDuration(AVAudioEngineDevice.kPreferredIOBufferDuration)
            try session.setCategory(AVAudioSession.Category.playAndRecord)
            try session.setMode(AVAudioSession.Mode.videoChat)
        } catch let error {
            SwiftTwilioProgrammableVideoPlugin.debug("Error setting up AudioSession: \(error)")
        }

        self.registerAVAudioSessionObservers()

        do {
            try session.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch let error {
            SwiftTwilioProgrammableVideoPlugin.debug("Error activating AVAudioSession: \(error)")
        }

        if session.maximumInputNumberOfChannels > 0 {
            do {
                try session.setPreferredInputNumberOfChannels(AudioFormat.ChannelsMono)
            } catch let error {
                SwiftTwilioProgrammableVideoPlugin.debug("Error setting number of input channels: \(error)")
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func setupAudioUnitWithRenderContext(renderContext: inout AudioRendererContext,
                                         captureContext: inout AudioCapturerContext) -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::setupAudioUnitWithRenderContext")
        // Find and instantiate the VoiceProcessingIO audio unit.
        var audioUnitDescription: AudioComponentDescription = AVAudioEngineDevice.audioUnitDescription()
        guard let audioComponent: AudioComponent = AudioComponentFindNext(nil, &audioUnitDescription) else {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not find VoiceProcessingIO AudioComponent!")
            return false
        }

        var status: OSStatus = AudioComponentInstanceNew(audioComponent, &self.audioUnit)
        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not find VoiceProcessingIO AudioComponent instance!")
            return false
        }

        /*
         * Configure the VoiceProcessingIO audio unit. Our rendering format attempts to match what AVAudioSession requires
         * to prevent any additional format conversions after the media engine has mixed our playout audio.
         */
        guard var streamDescription: AudioStreamBasicDescription = self.renderingFormat?.streamDescription() else {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not find AudioStreamBasicDescription!")
            return false
        }

        guard let audioUnit = self.audioUnit else {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not find AudioUnit.")
            return false
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
            SwiftTwilioProgrammableVideoPlugin.debug("Could not enable out bus!")
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
            return false
        }

        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Output, AVAudioEngineDevice.kInputBus,
                                      &streamDescription, streamDescriptionSize)
        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not set stream format on input bus!")
            return false
        }

        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Input, AVAudioEngineDevice.kOutputBus,
                                      &streamDescription, streamDescriptionSize)
        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not set stream format on output bus!")
            return false
        }

        // Enable the microphone input
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Input, AVAudioEngineDevice.kInputBus, &enableInput,
                                      uint32Size)

        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not enable input bus!")
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
            return false
        }

        // Setup the rendering callback.
        var renderCallback: AURenderCallbackStruct = AURenderCallbackStruct()
        renderCallback.inputProc = AVAudioEngineDevicePlayoutCallback
        renderCallback.inputProcRefCon = UnsafeMutableRawPointer(&renderContext)
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback,
                                      kAudioUnitScope_Output, AVAudioEngineDevice.kOutputBus, &renderCallback,
                                      auRenderCallbackStructSize)
        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not set rendering callback!")
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
            return false
        }

        // Setup the capturing callback.
        var captureCallback: AURenderCallbackStruct = AURenderCallbackStruct()
        captureCallback.inputProc = AVAudioEngineDeviceRecordCallback
        captureCallback.inputProcRefCon = UnsafeMutableRawPointer(&captureContext)
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback,
                                      kAudioUnitScope_Input, AVAudioEngineDevice.kInputBus, &captureCallback,
                                      auRenderCallbackStructSize)
        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not set capturing callback!")
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
            return false
        }

        var failedInitializeAttempts: NSInteger = 0
        while status != noErr {
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to initialize the Voice Processing I/O unit. Error= \(status).")
            failedInitializeAttempts += 1
            if failedInitializeAttempts == AVAudioEngineDevice.kMaxNumberOfAudioUnitInitializeAttempts {
                break
            }
            SwiftTwilioProgrammableVideoPlugin.debug("Pause 100ms and try audio unit initialization again.")
            Thread.sleep(forTimeInterval: 0.1)
            status = AudioUnitInitialize(audioUnit)
        }

        // Finally, initialize and start the VoiceProcessingIO audio unit.
        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not initialize the audio unit! => OSStatus: \(status)")
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
            return false
        }

        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::setupAudioUnitWithRenderContext => setting captureContext audioUnit")
        captureContext.audioUnit = audioUnit

        return true
    }

    func startAudioUnit() -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startAudioUnit => START")
        guard let audioUnitUnwrapped = self.audioUnit else {
            return false
        }

        var result = false
        var failedInitializeAttempts: NSInteger = 0
        while failedInitializeAttempts < AVAudioEngineDevice.kMaxNumberOfAudioUnitInitializeAttempts {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startAudioUnit => failed attempts: \(failedInitializeAttempts)")
            let status: OSStatus = AudioOutputUnitStart(audioUnitUnwrapped)
            if status == noErr {
                result = true
                break
            }
            SwiftTwilioProgrammableVideoPlugin.debug("Failed to start output on the Voice Processing I/O unit. Error= \(status).")
            failedInitializeAttempts += 1

            SwiftTwilioProgrammableVideoPlugin.debug("Pause 100ms and try audio unit initialization again.")
            Thread.sleep(forTimeInterval: 0.1)
        }

        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::startAudioUnit => END => started: \(result)")
        return result
    }

    func stopAudioUnit() -> Bool {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::stopAudioUnit")
        guard let audioUnitUnwrapped = self.audioUnit else {
            return false
        }

        let status: OSStatus = AudioOutputUnitStop(audioUnitUnwrapped)
        if status != 0 {
            SwiftTwilioProgrammableVideoPlugin.debug("Could not stop the audio unit!")
            return false
        }
        return true
    }

    func teardownAudioUnit() {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::teardownAudioUnit")
        if let audioUnitUnwrapped = self.audioUnit {
            AudioUnitUninitialize(audioUnitUnwrapped)
            AudioComponentInstanceDispose(audioUnitUnwrapped)
            self.audioUnit = nil
        }
    }

    // MARK: NSNotification Observers
    func deviceContext() -> AudioDeviceContext? {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::deviceContext")
        if self.renderingContext.deviceContext != nil {
            return self.renderingContext.deviceContext
        } else if self.capturingContext.deviceContext != nil {
            return self.capturingContext.deviceContext
        }
        return nil
    }

    func registerAVAudioSessionObservers() {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::registerAVAudioSessionObservers")
        // An audio device that interacts with AVAudioSession should handle events like interruptions and route changes.
        var center: NotificationCenter = NotificationCenter.default

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
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::handleAudioInterruption")
        guard let userInfo = notification.userInfo,
              let type: AVAudioSession.InterruptionType = userInfo[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType else {
            return
        }

        myPropertyQueue.async {
            // If the worker block is executed, then context is guaranteed to be valid.
            if let context = self.deviceContext() {
                AudioDeviceExecuteWorkerBlock(context: context) {
                    if type == AVAudioSession.InterruptionType.began {
                        SwiftTwilioProgrammableVideoPlugin.debug("Interruption began.")
                        self.interrupted = true
                        self.stopAudioUnit()
                    } else {
                        SwiftTwilioProgrammableVideoPlugin.debug("Interruption ended.")
                        self.interrupted = false
                        self.startAudioUnit()
                    }
                }
            }
        }
    }

    @objc private func handleApplicationDidBecomeActive(notification: Notification) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::handleApplicationDidBecomeActive")
        myPropertyQueue.async {
            // If the worker block is executed, then context is guaranteed to be valid.
            if let context = self.deviceContext() {
                AudioDeviceExecuteWorkerBlock(context: context) {
                    if self.interrupted {
                        SwiftTwilioProgrammableVideoPlugin.debug("Synthesizing an interruption ended event for iOS 9.x devices.")
                        self.interrupted = false
                        self.startAudioUnit()
                    }
                }
            }
        }
    }

    @objc private func handleRouteChange(notification: NSNotification) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::handleRouteChange")
        // Check if the sample rate, or channels changed and trigger a format change if it did.
        guard let userInfo = notification.userInfo,
              let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSession.RouteChangeReason else {
            return
        }

        switch reason {
            case AVAudioSession.RouteChangeReason.unknown,
                 AVAudioSession.RouteChangeReason.newDeviceAvailable,
                 AVAudioSession.RouteChangeReason.oldDeviceUnavailable,
                    // Each device change might cause the actual sample rate or channel configuration of the session to change.
                 AVAudioSession.RouteChangeReason.categoryChange,
                    // In iOS 9.2+ switching routes from a BT device in control center may cause a category change.
                 AVAudioSession.RouteChangeReason.override,
                 AVAudioSession.RouteChangeReason.wakeFromSleep,
                 AVAudioSession.RouteChangeReason.noSuitableRouteForCategory,
                 AVAudioSession.RouteChangeReason.routeConfigurationChange:
                    // With CallKit, AVAudioSession may change the sample rate during a configuration change.
                    // If a valid route change occurs we may want to update our audio graph to reflect the new output device.
                    myPropertyQueue.async {
                        // If the worker block is executed, then context is guaranteed to be valid.
                        if let context = self.deviceContext() {
                            AudioDeviceExecuteWorkerBlock(context: context) {
                                self.handleValidRouteChange()
                            }
                        }
                    }
            default:
                break
        }
    }

    func handleValidRouteChange() {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::handleValidRouteChange")
        // Nothing to process while we are interrupted. We will interrogate the AVAudioSession once the interruption ends.
        if self.interrupted || self.audioUnit == nil {
            return
        }

        SwiftTwilioProgrammableVideoPlugin.debug("A route change ocurred while the AudioUnit was started. Checking the active audio format.")

        // Determine if the format actually changed. We only care about sample rate and number of channels.
        guard let activeFormat: AudioFormat = AVAudioEngineDevice.activeFormat() else {
            return
        }
        // Notify Video SDK about the format change
        if !activeFormat.isEqual(renderingFormat) || !activeFormat.isEqual(capturingFormat) {
            SwiftTwilioProgrammableVideoPlugin.debug("Format changed, restarting with \(activeFormat)")

            // Signal a change by clearing our cached format, and allowing TVIAudioDevice to drive the process.
            renderingFormat = nil
            capturingFormat = nil

            myPropertyQueue.async {
                if let context = self.deviceContext() {
                    AudioDeviceFormatChanged(context: context)
                }
            }
        }
    }

    @objc private func handleMediaServiceLost(notification: Notification) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::handleMediaServiceLost")
        self.teardownAudioEngine()

        myPropertyQueue.async {
            // If the worker block is executed, then context is guaranteed to be valid.
            if let context = self.deviceContext() {
                AudioDeviceExecuteWorkerBlock(context: context) {
                    self.teardownAudioUnit()
                }
            }
        }
    }

    @objc private func handleMediaServiceRestored(notification: Notification) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngineDevice::handleMediaServiceRestored")
        self.setupAudioEngine()

        myPropertyQueue.async {
            // If the worker block is executed, then context is guaranteed to be valid.
            if let context = self.deviceContext() {
                AudioDeviceExecuteWorkerBlock(context: context) {
                    self.startAudioUnit()
                }
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
    guard let ioData = ioData else {
        return noErr
    }
    assert(ioData.pointee.mNumberBuffers == 1)
    assert(ioData.pointee.mBuffers.mNumberChannels <= 2)
    assert(ioData.pointee.mBuffers.mNumberChannels > 0)

    var context = inRefCon.assumingMemoryBound(to: AudioRendererContext.self)
    context.pointee.bufferList = ioData.pointee

    var audioBufferSizeInBytes: UInt32 = ioData.pointee.mBuffers.mDataByteSize

    // Pull decoded, mixed audio data from the media engine into the AudioUnit's AudioBufferList.
    assert(audioBufferSizeInBytes == (ioData.pointee.mBuffers.mNumberChannels * AVAudioEngineDevice.kAudioSampleSize * inNumberFrames))
    var outputStatus: OSStatus = noErr

    // Get the mixed audio data from AVAudioEngine's output node by calling the `renderBlock`
    guard let renderBlock: AVAudioEngineManualRenderingBlock = context.pointee.renderBlock,
        let maxFramesPerBuffer = context.pointee.maxFramesPerBuffer else {
        return outputStatus
    }

    let status: AVAudioEngineManualRenderingStatus = renderBlock(inNumberFrames, ioData, &outputStatus)

    /*
     * Render silence if there are temporary mismatches between CoreAudio and our rendering format or AVAudioEngine
     * could not render the audio samples.
     */
    if inNumberFrames > maxFramesPerBuffer || status != AVAudioEngineManualRenderingStatus.success {
        if inNumberFrames > maxFramesPerBuffer {
            SwiftTwilioProgrammableVideoPlugin.debug("Can handle a max of \(maxFramesPerBuffer) frames but got \(inNumberFrames).")
        }
        ioActionFlags.pointee = AudioUnitRenderActionFlags(rawValue: ioActionFlags.pointee.rawValue | AudioUnitRenderActionFlags.unitRenderAction_OutputIsSilence.rawValue)
        memset(ioData.pointee.mBuffers.mData, 0, Int(audioBufferSizeInBytes))
    }

    return noErr
}

// swiftlint:disable:next function_parameter_count
func AVAudioEngineDeviceRecordCallback(inRefCon: UnsafeMutableRawPointer,
                                       ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                                       inTimestamp: UnsafePointer<AudioTimeStamp>,
                                       inBusNumber: UInt32,
                                       inNumberFrames: UInt32,
                                       ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    if inNumberFrames > AVAudioEngineDevice.kMaximumFramesPerBuffer {
        SwiftTwilioProgrammableVideoPlugin.debug("Expected \(AVAudioEngineDevice.kMaximumFramesPerBuffer) frames but got \(inNumberFrames).")
        return noErr
    }

    var context = inRefCon.assumingMemoryBound(to: AudioCapturerContext.self)

    if context.pointee.deviceContext == nil {
        return noErr
    }

    context.pointee.bufferList.pointee.mBuffers.mDataByteSize = inNumberFrames * UInt32(MemoryLayout<UInt16>.size) * AVAudioEngineDevice.kPreferredNumberOfChannels
    // The buffer will be filled by VoiceProcessingIO AudioUnit
    context.pointee.bufferList.pointee.mBuffers.mData = nil

    guard let audioUnit = context.pointee.audioUnit else {
        SwiftTwilioProgrammableVideoPlugin.debug("Expected AudioCapturerContext to have AudioUnit.")
        return noErr
    }

    var status: OSStatus = noErr
    status = AudioUnitRender(audioUnit,
                             ioActionFlags,
                             inTimestamp,
                             1,
                             inNumberFrames,
                             context.pointee.bufferList)

    if context.pointee.mixedAudioBufferList.pointee == nil {
        return noErr
    }

    var mixedAudioBufferList: UnsafeMutablePointer<AudioBufferList> = UnsafeMutablePointer<AudioBufferList>( &context.pointee.mixedAudioBufferList.pointee!)

    mixedAudioBufferList.pointee.mBuffers.mNumberChannels =
        context.pointee.bufferList.pointee.mBuffers.mNumberChannels
    mixedAudioBufferList.pointee.mBuffers.mDataByteSize =
        context.pointee.bufferList.pointee.mBuffers.mDataByteSize

    guard let renderBlock: AVAudioEngineManualRenderingBlock = context.pointee.renderBlock else {
        return noErr
    }

    var outputStatus: OSStatus = noErr
    let ret: AVAudioEngineManualRenderingStatus = renderBlock(inNumberFrames, mixedAudioBufferList, &outputStatus)

    if ret != AVAudioEngineManualRenderingStatus.success {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioEngine failed mix audio => \(String(describing: ret.rawValue))")
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
    var bufferList: AudioBufferList = AudioBufferList()

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
    var bufferList: UnsafeMutablePointer<AudioBufferList>

    // Preallocated mixed (AudioUnit mic + AVAudioPlayerNode file) audio buffer list.
    var mixedAudioBufferList: UnsafeMutablePointer<AudioBufferList?>

    // Core Audio's VoiceProcessingIO audio unit.
    var audioUnit: AudioUnit?

    /*
     * Points to AVAudioEngine's manualRenderingBlock. This block is called from within the VoiceProcessingIO playout
     * callback in order to receive mixed audio data from AVAudioEngine in real time.
     */
    var renderBlock: AVAudioEngineManualRenderingBlock?

    init(bufferList: UnsafeMutablePointer<AudioBufferList>, mixedAudioBufferList: UnsafeMutablePointer<AudioBufferList?>) {
        self.bufferList = bufferList
        self.mixedAudioBufferList = mixedAudioBufferList
    }
}

public class AVAudioPlayerNodeManager {
    var nodes: [Int: AVAudioPlayerNodeBundle] = [:]
    var pausedNodes: [Int: AVAudioPlayerNodeBundle] = [:]

    func addNode(_ id: Int, _ file: AVAudioFile, _ loop: Bool, _ volume: Double) -> AVAudioPlayerNodeBundle {
        let player: AVAudioPlayerNode = AVAudioPlayerNode()
        let eq = AVAudioUnitEQ()
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(AVAudioUnitReverbPreset.mediumHall)
        reverb.wetDryMix = 50

        let nodeBundle = AVAudioPlayerNodeBundle(id, player, reverb, file, loop, eq)
        nodes[id] = nodeBundle
        setMusicVolume(id, volume)

        return nodeBundle
    }

    func disposeNode(_ id: Int) {
        guard let node = getNode(id) else {
            return
        }

        nodes.removeValue(forKey: id)
    }

    func shouldReattachNodes() -> Bool {
        return !nodes.values.isEmpty
    }

    func getNode(_ id: Int) -> AVAudioPlayerNodeBundle? {
        guard let node = nodes[id] else {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::getNode => node not found for id: \(id)")
            return nil
        }

        return node
    }

    public func playNode(_ id: Int) {
        play(id)
    }

    func play(_ id: Int, position: AVAudioFramePosition = 0) {
        guard let node = nodes[id] else {
            return
        }

        if !node.playing {
            let frameCount: AVAudioFrameCount = AVAudioFrameCount(node.file.length - position)

            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::play => file: \(fileName(node.file)), from: \(position), for: \(frameCount), loop: \(node.loop)")

            node.player.scheduleSegment(node.file, startingFrame: position, frameCount: frameCount, at: nil) {
                SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::segmentComplete => file: \(self.fileName(node.file)). playing: \(node.playing), startedAt: \(position), loop: \(node.loop)")
                if node.loop && node.playing && !self.isPaused(node.id) {
                    node.playing = false
                    self.play(node.id)
                } else {
                    node.playing = false
                }
            }
            node.playing = true
            node.startFrame = position
            node.pauseTime = nil
            node.player.play()
            if gainToVolume(node.eq.globalGain) < node.volume {
                fadeInNode(node)
            }
        }
    }

    func fileName(_ file: AVAudioFile) -> String {
        return String(describing: file.url.absoluteString.split(separator: "/").last)
    }

    public func stopNode(_ id: Int) {
        guard let node = nodes[id] else {
            return
        }
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::stopNode => file: \(fileName(node.file))")

        if isPaused(id) {
            node.pauseTime = nil
            pausedNodes.removeValue(forKey: node.id)
        }
        node.playing = false

        fadeOutNode(node)
        node.player.stop()
    }

    public func pauseNode(_ id: Int, _ resumeAfterRendererStarted: Bool = false) {
        guard let node = nodes[id] else {
            return
        }

        node.pauseTime = getPosition(id)
        node.playing = false
        node.resumeAfterRendererStarted = resumeAfterRendererStarted

        fadeOutNode(node)
        node.player.stop()
        pausedNodes[node.id] = node
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::pauseNode => paused node \(node.id) pauseTime: \(node.pauseTime)")
    }

    public func resumeNode(_ id: Int) {
        guard let node = nodes[id],
              let pausePosition = node.pauseTime else {
            return
        }

        if node.player.isPlaying {
            return
        }

        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::resumeNode => node \(node.id), frame: \(pausePosition), volume: \(node.volume)")

        node.resumeAfterRendererStarted = false
        seekPosition(id, pausePosition)
        fadeInNode(node)
        pausedNodes.removeValue(forKey: node.id)
    }

    public func setMusicVolume(_ id: Int, _ volume: Double) {
        guard let node = nodes[id] else {
            return
        }

        node.volume = volume
        var gain = volumeToGain(volume)

        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::setMusicVolume => id: \(id), volume: \(volume), gain: \(gain)")

        node.eq.globalGain = Float(gain)
    }

    func fadeOutNode(_ node: AVAudioPlayerNodeBundle) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::fadeOutNode => START - node \(node.id), volume \(node.volume)")
        var volume = gainToVolume(node.eq.globalGain)
        var increment = volume / 10
        fadeOut(node, volume, increment)
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::fadeOutNode => END - node \(node.id)")
    }

    func fadeOut(_ node: AVAudioPlayerNodeBundle, _ volume: Double, _ volumeIncrement: Double) {
        let vol = volume >= 0 ? volume : 0
        node.eq.globalGain = volumeToGain(volume)
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::fadeOut => START - node \(node.id), volume \(node.volume) currentVolume: \(volume)")

        if volume > 0 {
            let timeSecs = 0.001  /// 1 ms
            Thread.sleep(forTimeInterval: timeSecs)
            let nextStep = volume - volumeIncrement
            fadeOut(node, nextStep, volumeIncrement)
        }
    }

    func fadeInNode(_ node: AVAudioPlayerNodeBundle) {
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::fadeInNode => START - node \(node.id), volume \(node.volume)")
        var increment = node.volume / 10
        fadeIn(node, 0, increment)
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::fadeInNode => END - node \(node.id)")
    }

    func fadeIn(_ node: AVAudioPlayerNodeBundle, _ volume: Double, _ volumeIncrement: Double) {
        let vol = volume <= node.volume ? volume : node.volume
        node.eq.globalGain = volumeToGain(vol)
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::fadeIn => START - node \(node.id), volume \(node.volume) currentVolume: \(volume)")

        if volume < node.volume {
            let timeSecs = 0.001  /// 1 ms
            Thread.sleep(forTimeInterval: timeSecs)
            let nextStep = volume + volumeIncrement
            fadeIn(node, nextStep, volumeIncrement)
        }
    }

    /**
    * Convert volume range of 0 (silence) -> 1.0 to AVAudioUnitEQ globalGain range of -96.0 (silence) -> 0.0 db
    *
    * AVAudioUnitEQ supports a globalGain range of -96.0 - 24.0 db
    * While developing this it was found that increasing db beyond 0 (thus amplifying the original sound of the audio file) results in
    * audio artifacts during playback. As a result, limiting audio range from -96 db (silent) to 0 (normal volume)
    */
    func volumeToGain(_ vol: Double) -> Float {
        var gain = Float((vol * 96) - 96)
        gain = restrictGainRange(gain)
        return gain
    }

    func gainToVolume(_ gain: Float) -> Double {
        let boundedGain = restrictGainRange(gain)
        let volume = Double((boundedGain + 96) / 96)
        return volume
    }

    func restrictGainRange(_ gain: Float) -> Float {
        if gain < -96 {
            return -96
        } else if gain > 0 {
            return 0
        } else {
            return gain
        }
    }

    public func seekPosition(_ id: Int, _ positionInMillis: Int64) {
        guard let node = nodes[id] else {
            return
        }

        var framePosition = AVAudioFramePosition((Double(positionInMillis) * node.file.processingFormat.sampleRate) / 1000)
        if framePosition < 0 || framePosition >= node.file.length {
            framePosition = 0
        }
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::seekPosition => id: \(id), positionInMillis: \(positionInMillis), framePosition: \(framePosition), lengthInFrames: \(node.file.length)")

        node.playing = false
        node.player.stop()

        self.play(node.id, position: framePosition)
    }

    public func getPosition(_ id: Int) -> Int64 {
        guard let node = nodes[id] else {
            return 0
        }

        if node.player.isPlaying {
            /**
             *  Compute position in milliseconds.
             *  `lastRenderTime` has been observed to be invalid when position is retrieved immediately after
             *  starting playback, but before a render frame has taken place. As a result, we will consider the position
             *  to be the frame as which play was initiated.
             *
             *  `node.startFrame`                 => frame at which player was started
             *  `playerTime.sampleTime`    => frames elapsed since player started
             *  `node.file.length`               => number of frames in the file
             *  `playerTime.sampleRate`    => number of frames per second
             *  `1000`                                          => number of milliseconds in a second
             */
            let position: Int64 = {
                if let lastRenderTime = node.player.lastRenderTime,
                  lastRenderTime.isSampleTimeValid,
                  let playerTime = node.player.playerTime(forNodeTime: lastRenderTime) {
                    return Int64((Double((node.startFrame + playerTime.sampleTime) % node.file.length) / node.file.fileFormat.sampleRate) * 1000)
                } else {
                    return Int64((Double((node.startFrame) % node.file.length) / node.file.fileFormat.sampleRate) * 1000)
                }
            }()

            return position
        } else if isPaused(id),
                  let pauseTime = node.pauseTime {
            return pauseTime
        }

        return 0
    }

    public func anyPlaying() -> Bool {
        var result = false
        for nodeBundle in nodes.values where nodeBundle.player.isPlaying {
            SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::anyPlaying => node \(nodeBundle.id) is playing")
            result = true
            break
        }
        SwiftTwilioProgrammableVideoPlugin.debug("AVAudioPlayerNodeManager::anyPlaying => \(result)")
        return result
    }

    public func anyPaused() -> Bool {
        return !pausedNodes.values.isEmpty
    }

    func isPaused(_ id: Int) -> Bool {
        return pausedNodes[id] != nil
    }

    public func pauseAll(_ resumeAfterRendererStarted: Bool = false) {
        self.nodes.values.forEach { (node: AVAudioPlayerNodeBundle) in
            if node.player.isPlaying {
                self.pauseNode(node.id, resumeAfterRendererStarted)
            }
        }
    }

    public func resumeAll() {
        self.pausedNodes.values.forEach { (node: AVAudioPlayerNodeBundle) in
            if node.resumeAfterRendererStarted {
                self.resumeNode(node.id)
            }
        }
    }
}

class AVAudioPlayerNodeBundle {
    let id: Int
    let player: AVAudioPlayerNode
    let reverb: AVAudioUnitReverb
    let file: AVAudioFile
    let loop: Bool
    var pauseTime: Int64?
    var playing: Bool = false
    var startFrame: Int64 = 0
    var resumeAfterRendererStarted: Bool = false
    let eq: AVAudioUnitEQ
    var volume: Double

    init(_ id: Int, _ player: AVAudioPlayerNode, _ reverb: AVAudioUnitReverb, _ file: AVAudioFile, _ loop: Bool, _ eq: AVAudioUnitEQ, _ volume: Double = 0) {
        self.id = id
        self.player = player
        self.reverb = reverb
        self.file = file
        self.loop = loop
        self.eq = eq
        self.volume = volume
    }
}
