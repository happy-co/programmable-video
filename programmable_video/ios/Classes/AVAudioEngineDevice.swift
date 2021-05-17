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
    
    static var instance: AVAudioEngineDevice = AVAudioEngineDevice()

    public static func getInstance() -> AVAudioEngineDevice {
        return instance
    }

    // MARK: Init & Dealloc
    override private init() {
        debug("AVAudioEngineDevice::init => START")
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
            debug("AVAudioEngineDevice::init => Failed to setup AVAudioEngine")
        }
//        // TODO: cleanup if not needed
//        self.setupAVAudioSession()

        debug("AVAudioEngineDevice::init => END")
    }

    deinit {
        debug("AVAudioEngineDevice::deinit")
        self.disposeAllNodes()
        self.stopRendering()
        self.stopCapturing()
        NotificationCenter.default.removeObserver(self)
        self.teardownAudioEngine()
        // TODO: teardownAudioUnit?

        deallocateMemoryForAudioBuffers()
    }

    // Allocating pointers explicitly exempts them from Automatic Reference Counting
    func allocateMemoryForAudioBuffers() {
        let audioBufferListSize = MemoryLayout<AudioBufferList>.size
        let renderingCapacity = Int(AVAudioEngineDevice.kMaximumFramesPerBuffer * AVAudioEngineDevice.kPreferredNumberOfChannels * AVAudioEngineDevice.kAudioSampleSize)

        debug("AVAudioEngineDevice::allocateMemoryForAudioBuffers => renderCapacity: \(renderingCapacity)")
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
        debug("AVAudioEngineDevice::deallocateMemoryForAudioBuffers")
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
     * Determine at runtime the maximum slice size used by VoiceProcessingIO. Setting the stream format and sample rate
     * doesn't appear to impact the maximum size so we prefer to read this value once at initialization time.
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
        debug("This device uses a maximum slice size of \(framesPerSlice) frames.\n\taudioUnit: \(audioUnit)")
        AVAudioEngineDevice.kMaximumFramesPerBuffer = framesPerSlice
        // TODO: consider if this is the right spot for setting renderingContext.maxFramesPerBuffer
//        self.renderingContext.maxFramesPerBuffer = framesPerSlice
    }

    // MARK: Private (AVAudioEngine)
    func setupAudioEngine() -> Bool {
        debug("AVAudioEngineDevice::setupAudioEngine")
        return self.setupPlayoutAudioEngine() && self.setupRecordAudioEngine()
    }

    func setupRecordAudioEngine() -> Bool {
        debug("AVAudioEngineDevice::setupRecordAudioEngine")
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
        debug("AVAudioEngineDevice::setupPlayoutAudioEngine")
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
            debug("AVAudioEngineDevice::setupPlayoutAudioEngine =>\n\tformat: \(format)\n\tmaxFrameCount: \(UInt32(activeFormat.framesPerBuffer))\n\tsampleRate: \(format.sampleRate)")
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

        debug("AVAudioEngineDevice::setupPlayoutAudioEngine => end")
        return true
    }

    func teardownRecordAudioEngine() {
        debug("AVAudioEngineDevice::teardownRecordAudioEngine")
        if let engine = self.recordEngine {
            engine.stop()
            self.recordEngine = nil
            self.capturingFormat = nil
        }
    }

    func teardownPlayoutAudioEngine() {
        debug("AVAudioEngineDevice::teardownPlayoutAudioEngine")
        if let engine = self.playoutEngine, engine.isRunning {
            engine.stop()
        }
        self.playoutEngine = nil
        self.renderingFormat = nil
    }

    func teardownAudioEngine() {
        debug("AVAudioEngineDevice::teardownAudioEngine")
        self.teardownPlayoutAudioEngine()
        self.teardownRecordAudioEngine()
    }

    
    public func onConnected() {
        // TODO: Add in conditional to handle scenario where engine is running prior to connection
        self.isConnected = true
        self.setupAVAudioSession()
    }

    public func onDisconnected() {
        self.isConnected = false
        self.teardownAVAudioSession()
        // TODO: Add in conditional to handle scenario where engine should remain running after disconnection
//        do {
//            NotificationCenter.default.removeObserver(self)
//            let session = AVAudioSession.sharedInstance()
//            try session.setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
//        } catch let error {
//            debug("Error deactivating AVAudioSession: \(error)")
//        }
    }
    
    // MARK: Audio File Playback API
    public func playMusic(_ id: Int) {
        safelyPlayMusic {
            debug("AVAudioEngineDevice::playMusic => QUEUE - DispatchQueue.main.async")
            DispatchQueue.main.async {
                debug("AVAudioEngineDevice::playMusic => START - DispatchQueue.main.async id: \(id)")
                // TODO: don't just leave this here, figure out the right thing to do with it
//                self.setupAVAudioSession()
                self.audioPlayerNodeManager.playNode(id)
                debug("AVAudioEngineDevice::playMusic => END - DispatchQueue.main.async: \(id)")
            }
            debug("AVAudioEngineDevice::playMusic => END")
        }
    }

    func safelyPlayMusic(_ playCallback: @escaping () -> Void) {
        // TODO: cleanup if not needed
        self.setupAVAudioSession()
        
        myPropertyQueue.async {
            debug("AVAudioEngineDevice::safelyPlayMusic => START - myPropertyQueue.async" +
                "\n\tstartingRenderer: \(self.isStartingRenderer)" +
                "\n\tisRendering: \(self.isRendering)" +
                "\n\tstoppingRenderer: \(self.isStoppingRenderer)")

            // Could collapse isRendering/isStartingRenderer/isStoppingRenderer into a single state enum
            if self.isRendering {
                    debug("AVAudioEngineDevice::safelyPlayMusic => scheduleMusicOnPlayoutEngine => dispatch")
                // Since the engine is already rendering, no need to queue playCallback on myPropertyQueue to ensure that it occurs after rendering is started
                playCallback()
            } else if self.isStartingRenderer {
                debug("AVAudioEngineDevice::safelyPlayMusic => playCallback: QUEUE - self.myPropertyQueue.async")
                self.myPropertyQueue.async {
                    playCallback()
                }
            } else {
                debug("AVAudioEngineDevice::safelyPlayMusic => startRendering")
                if self.startRenderingInternal(context: nil) {
                    debug("AVAudioEngineDevice::safelyPlayMusic => startRendering => scheduleMusicOnPlayoutEngine")
                    self.myPropertyQueue.async {
                        playCallback()
                    }
                } else {
                    debug("AVAudioEngineDevice::safelyPlayMusic => startRendering failed")
                }
            }
            debug("AVAudioEngineDevice::safelyPlayMusic => END - myPropertyQueue.async")
        }
    }

    public func stopMusic(_ id: Int) {
        debug("AVAudioEngineDevice::stopMusic => node: \(id)")
        self.audioPlayerNodeManager.stopNode(id)

        // TODO: review case where playMusic/is starting rendering/waiting to start rendering before starting music
        if !self.audioPlayerNodeManager.isActive(),
//           !self.audioPlayerNodeManager.anyPaused(),
//           self.renderingContext.deviceContext == nil,
           !self.isConnected,
            !self.isStartingRenderer,
            !self.isStoppingRenderer {
            debug("AVAudioEngineDevice::stopMusic => node: \(id) => stopRendering")
            self.stopRendering()
            
            // TODO: review
            // Ensure AVAudioSession is deactivated after audioUnit is stopped
            self.myPropertyQueue.async {
                self.teardownAVAudioSession()
            }
        }
    }

    public func pauseMusic(_ id: Int) {
        debug("AVAudioEngineDevice::pauseNode => \(id)")
        self.audioPlayerNodeManager.pauseNode(id)
    }

    public func resumeMusic(_ id: Int) {
        debug("AVAudioEngineDevice::resumeMusic => \(id)")
        self.audioPlayerNodeManager.resumeNode(id)
    }

    public func setMusicVolume(_ id: Int, _ volume: Double) {
        self.audioPlayerNodeManager.setMusicVolume(id, volume)
    }

    public func seekPosition(_ id: Int, _ positionInMillis: Int) {
        safelyPlayMusic {
            debug("AVAudioEngineDevice::seekPosition => QUEUE - DispatchQueue.main.async")
            DispatchQueue.main.async {
                debug("AVAudioEngineDevice::seekPosition => START - DispatchQueue.main.async")
                debug("AVAudioEngineDevice::seekPosition => id: \(id), positionInMillis: \(positionInMillis)")
                self.audioPlayerNodeManager.seekPosition(id, Int64(positionInMillis))
                debug("AVAudioEngineDevice::seekPosition => END - DispatchQueue.main.async")
            }
        }
    }

    public func getPosition(_ id: Int) -> Int64 {
        debug("AVAudioEngineDevice::getPosition => id: \(id)")
        return self.audioPlayerNodeManager.getPosition(id)
    }

    func disposeAllNodes() {
        self.audioPlayerNodeManager.nodes.keys.forEach { (id) in
            disposeMusicNode(id)
        }
    }

    public func disposeMusicNode(_ id: Int) {
        debug("AVAudioEngineDevice::disposeMusicNode => id: \(id)")
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
        debug("AVAudioEngineDevice::reattachMusicNodes")
        self.audioPlayerNodeManager.nodes.values.forEach { (_ node: AVAudioPlayerNodeBundle) in
            attachMusicNode(node)
        }
    }

    func attachMusicNode(_ nodeBundle: AVAudioPlayerNodeBundle) {
        debug("AVAudioEngineDevice::attachMusicNode => node: \(nodeBundle.id)")
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
        debug("AVAudioEngineDevice::renderFormat => format: \(self.renderingFormat)")
//        if renderingFormat == nil, let activeFormat = activeFormat() {
//            /*
//             * Assume that the AVAudioSession has already been configured and started and that the values
//             * for sampleRate and IOBufferDuration are final.
//             */
//            renderingFormat = activeFormat
//            self.renderingContext.maxFramesPerBuffer = activeFormat.framesPerBuffer
//        }
//
        return renderingFormat
    }

    public func initializeRenderer() -> Bool {
        debug("AVAudioEngineDevice::initializeRenderer")
        /*
         * In this example we don't need any fixed size buffers or other pre-allocated resources. We will simply write
         * directly to the AudioBufferList provided in the AudioUnit's rendering callback.
         */
        return true
    }

    public func startRendering(context: AudioDeviceContext?) -> Bool {
        if !self.didFormatChangeWhileDisconnected {
            var result: Bool = false
            self.isStartingRenderer = true
            self.isRendering = false
            
            debug("AVAudioEngineDevice::startRendering => START - deviceContext: \(context), onMain: \(Thread.current.isMainThread), isRendering: \(self.isRendering)")
            myPropertyQueue.sync {
                debug("AVAudioEngineDevice::startRendering => START - myPropertyQueue.sync")
                result = self.startRenderingInternal(context: context)
                debug("AVAudioEngineDevice::startRendering => END - myPropertyQueue.sync")
            }

            debug("AVAudioEngineDevice::startRendering => END - result: \(result)")
            return result
        } else {
            self.notifyVideoSdkOfFormatChange(context: context)
            return false
        }
    }

    // swiftlint:disable:next function_body_length
    internal func startRenderingInternal(context: AudioDeviceContext?) -> Bool {
        debug("AVAudioEngineDevice::startRenderingInternal => START - current thread main: \(Thread.current.isMainThread)")

        var result = false

        self.isStartingRenderer = true
        self.isRendering = false
        self.renderingContext.deviceContext = context

        // Pause active audio player nodes while engine is restarted
        if self.audioPlayerNodeManager.anyPlaying() {
            debug("AVAudioEngineDevice::startRenderingInternal => pause active audio nodes")
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
            debug("AVAudioEngineDevice::startRenderingInternal => reset audioUnit")
            self.stopAudioUnit()
            self.teardownAudioUnit()
        }
        
        self.setupAudioUnit()

//        if !self.setupAudioUnitWithRenderContext(renderContext: &self.renderingContext, captureContext: &self.capturingContext) {
//            result = false
//            self.isStartingRenderer = false
//            self.isRendering = false
//            return false
//        }

        debug("AVAudioEngineDevice::startRenderingInternal => QUEUE - DispatchQueue.main.async")
        // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.
        DispatchQueue.main.async {
            debug("AVAudioEngineDevice::startRenderingInternal => START - DispatchQueue.main.async")

            if let engine = self.playoutEngine,
               let engineFormat = AudioFormat(
                channels: Int(engine.manualRenderingFormat.channelCount),
                sampleRate: UInt32(engine.manualRenderingFormat.sampleRate),
                framesPerBuffer: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)),
               let activeFormat = self.activeFormat(),
               engineFormat.isEqual(activeFormat) {
                if engine.isRunning {
                    debug("AVAudioEngineDevice::startRenderingInternal => stopping engine.\n\tengineFormat: \(engineFormat)\n\tactiveFormat: \(activeFormat)")
                    engine.stop()
                }

                do {
                    debug("AVAudioEngineDevice::startRenderingInternal => starting engine")
                    try engine.start()
                } catch let error {
                    debug("Failed to start AVAudioEngine, error = \(error)")
                }
            } else {
            /*
             * If the engine is not configured properly we will tear it down,
             * restart it, reattach audio nodes as needed.
             */
                debug("AVAudioEngineDevice::startRenderingInternal => teardown and setup audio engine\n\tengineFormat: \(self.renderingFormat)\n\tactiveFormat: \(self.activeFormat)")
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
            debug("AVAudioEngineDevice::startRenderingInternal => END - DispatchQueue.main.async")
        }

        result = self.startAudioUnit()

        self.isStartingRenderer = false
        self.isRendering = true

        debug("AVAudioEngineDevice::startRenderingInternal => END")

        return result
    }

    public func stopRendering() -> Bool {
        debug("AVAudioEngineDevice::stopRendering => nodes playing: \(self.audioPlayerNodeManager.anyPlaying()), nodes paused: \(self.audioPlayerNodeManager.anyPaused())")
        self.isStoppingRenderer = true
        self.isRendering = false
        self.myPropertyQueue.async {
            debug("AVAudioEngineDevice::stopRendering => START - myPropertyQueue.async")
            // If the capturer is running, we will not stop the audio unit.
            if self.capturingContext.deviceContext == nil,
               !self.audioPlayerNodeManager.anyPlaying(),
               !self.audioPlayerNodeManager.anyPaused() {
                debug("AVAudioEngineDevice::stopRendering => stopAudioUnit")
                self.stopAudioUnit()
                self.teardownAudioUnit()
            }

            self.renderingContext.deviceContext = nil
            if let engine = self.playoutEngine,
               engine.isRunning,
               !self.audioPlayerNodeManager.anyPlaying(),
               !self.audioPlayerNodeManager.anyPaused() {
                debug("AVAudioEngineDevice::stopRendering => QUEUE - DispatchQueue.main.async")
                // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.
                DispatchQueue.main.async {
                    debug("AVAudioEngineDevice::stopRendering => START - DispatchQueue.main.async")

                    // If audio player nodes are in use, we will not stop the engine
                    if let engine = self.playoutEngine {
                        debug("AVAudioEngineDevice::stopRendering => stop playoutEngine")
                        engine.stop()
                    }
                    debug("AVAudioEngineDevice::stopRendering => END - DispatchQueue.main.async")
                    self.isStoppingRenderer = false
                }
            } else {
                self.isStoppingRenderer = false
            }
            debug("AVAudioEngineDevice::stopRendering => END - myPropertyQueue.async")
        }

        return true
    }

    // MARK: AudioDeviceCapturer
    public func captureFormat() -> AudioFormat? {
        debug("AVAudioEngineDevice::captureFormat => format: \(self.capturingFormat)")
//        if capturingFormat == nil {
//            /*
//             * Assume that the AVAudioSession has already been configured and started and that the values
//             * for sampleRate and IOBufferDuration are final.
//             */
//            capturingFormat = activeFormat()
//        }
//
        return capturingFormat
    }

    public func initializeCapturer() -> Bool {
        debug("AVAudioEngineDevice::initializeCapturer")
        
//        if self.capturingContext.mixedAudioBufferList?.pointee == nil {
//            // TODO: Decide if this is necessary, and if it is, maybe allocate mixedAudioBufferList
//            var pMixedAudioBufferListData = UnsafeMutablePointer<Int8>.allocate(capacity: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer * AVAudioEngineDevice.kPreferredNumberOfChannels * AVAudioEngineDevice.kAudioSampleSize))
//            self.capturingContext.mixedAudioBufferList?.pointee = AudioBufferList(
//                                                   mNumberBuffers: 1,
//                                                   mBuffers: AudioBuffer(
//                                                    mNumberChannels: AVAudioEngineDevice.kPreferredNumberOfChannels,
//                                                    mDataByteSize: UInt32(0),
//                                                    mData: pMixedAudioBufferListData
//                                                   ))
//            debug("AVAudioEngineDevice::initializeCapturer => initialized mixAudioBufferList")
//        }

        return true
    }

    public func startCapturing(context: AudioDeviceContext) -> Bool {
        if !self.didFormatChangeWhileDisconnected {
            debug("AVAudioEngineDevice::startCapturing")
            var result: Bool = true
            myPropertyQueue.sync {
                debug("AVAudioEngineDevice::startCapturing - START - myPropertyQueue.async")
                // Restart the audio unit if the audio graph is alreay setup and if we publish an audio track.
                if self.audioUnit != nil {
                    debug("AVAudioEngineDevice::startCapturing => reset audioUnit")
                    self.stopAudioUnit()
                    self.teardownAudioUnit()
                }
                
                self.setupAudioUnit()

                debug("AVAudioEngineDevice::startCapturing => QUEUE - DispatchQueue.main.async")
                // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.
                DispatchQueue.main.async {
                    debug("AVAudioEngineDevice::startCapturing => START - DispatchQueue.main.async")
                    if let engine = self.recordEngine,
                       let engineFormat = AudioFormat(
                        channels: Int(engine.manualRenderingFormat.channelCount),
                        sampleRate: UInt32(engine.manualRenderingFormat.sampleRate),
                        framesPerBuffer: Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)),
                       let activeFormat = self.activeFormat(),
                       engineFormat.isEqual(activeFormat) {
                        if engine.isRunning {
                            debug("AVAudioEngineDevice::startCapturing => stopping engine")
                            engine.stop()
                        }

                        do {
                            debug("AVAudioEngineDevice::startCapturing => starting engine")
                            try engine.start()
                        } catch let error {
                            debug("Failed to start AVAudioEngine, error = \(error)")
                        }
                    } else {
                        self.teardownRecordAudioEngine()
                        self.setupRecordAudioEngine()
                    }
                    debug("AVAudioEngineDevice::startCapturing => END - DispatchQueue.main.async")
    //                result = self.startAudioUnit()
                }

                self.capturingContext.deviceContext = context

    //            if !self.setupAudioUnitWithRenderContext(renderContext: &self.renderingContext, captureContext: &self.capturingContext) {
    //                result = false
    //                return
    //            }

            debug("AVAudioEngineDevice::startCapturing => startAudioUnit")
            result = self.startAudioUnit()
            debug("AVAudioEngineDevice::startCapturing - END - myPropertyQueue.async")
            return
        }

            debug("AVAudioEngineDevice::startCapturing - END - result: \(result)")
            return result
        } else {
            self.notifyVideoSdkOfFormatChange(context: context)
            return false
        }
    }

    public func stopCapturing() -> Bool {
        debug("AVAudioEngineDevice::stopCapturing => nodes playing: \(self.audioPlayerNodeManager.anyPlaying()), nodes paused: \(self.audioPlayerNodeManager.anyPaused())")
        myPropertyQueue.async {
            debug("AVAudioEngineDevice::stopCapturing => START - myPropertyQueue.async")
            // If the renderer is in use by a remote participants audio track, or audio player nodes, we will not stop the audio unit.
            if self.renderingContext.deviceContext == nil,
               !self.audioPlayerNodeManager.anyPlaying(),
               !self.audioPlayerNodeManager.anyPaused() {
                self.stopAudioUnit()
                self.teardownAudioUnit()
            }
            self.capturingContext.deviceContext = nil
//            self.capturingContext.audioUnit = nil

            // We will make sure AVAudioEngine and AVAudioPlayerNode is accessed on the main queue.
            debug("AVAudioEngineDevice::stopCapturing => QUEUE - DispatchQueue.main.async")
            DispatchQueue.main.async {
                debug("AVAudioEngineDevice::stopCapturing => START - DispatchQueue.main.async")
                if let engine = self.recordEngine, engine.isRunning {
                    debug("AVAudioEngineDevice::stopCapturing => stop recordEngine")
                    engine.stop()
                }
                debug("AVAudioEngineDevice::stopCapturing => END - DispatchQueue.main.async")
            }
            debug("AVAudioEngineDevice::stopCapturing => END - myPropertyQueue.async")
        }

        return true
    }

    // MARK: Private (AVAudioSession and CoreAudio)
    func activeFormat() -> AudioFormat? {
        debug("AVAudioEngineDevice::activeFormat =>\n\tmaxFramesPerBuffer: \(AVAudioEngineDevice.kMaximumFramesPerBuffer)\n\tsampleRate: \(AVAudioSession.sharedInstance().sampleRate)")
        /*
         * Use the pre-determined maximum frame size. AudioUnit callbacks are variable, and in most sitations will be close
         * to the `AVAudioSession.preferredIOBufferDuration` that we've requested.
         */
        let sessionFramesPerBuffer: Int = Int(AVAudioEngineDevice.kMaximumFramesPerBuffer)
        let sessionSampleRate: UInt32 = UInt32(AVAudioSession.sharedInstance().sampleRate)

        return AudioFormat(channels: AudioFormat.ChannelsMono, sampleRate: sessionSampleRate, framesPerBuffer: sessionFramesPerBuffer)
    }

    static func audioUnitDescription() -> AudioComponentDescription {
        debug("AVAudioEngineDevice::audioUnitDescription")
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
        debug("AVAudioEngineDevice::setupAVAudioSession => AVAudioSession:\n\tpreferredSampleRate: \(session.preferredSampleRate)\n\tpreferredOutputNumberOfChannels: \(session.preferredOutputNumberOfChannels)\n\tpreferredIOBufferDuration: \(session.preferredIOBufferDuration)")

        do {
            try session.setPreferredSampleRate(Double(AVAudioEngineDevice.kPreferredSampleRate))
            try session.setPreferredOutputNumberOfChannels(Int(AVAudioEngineDevice.kPreferredNumberOfChannels))
            /*
             * We want to be as close as possible to the 10 millisecond buffer size that the media engine needs. If there is
             * a mismatch then TwilioVideo will ensure that appropriately sized audio buffers are delivered.
             */
            try session.setPreferredIOBufferDuration(AVAudioEngineDevice.kPreferredIOBufferDuration)
            try session.setCategory(AVAudioSession.Category.playAndRecord)
            // TODO: ensure AVAudioSession configuration that should be handled by PluginHandler us bit overwritten here
//            try session.setMode(AVAudioSession.Mode.videoChat)
        } catch let error {
            debug("Error setting up AudioSession: \(error)")
        }

        self.registerAVAudioSessionObservers()

        do {
            try session.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch let error {
            debug("Error activating AVAudioSession: \(error)")
        }

        if session.maximumInputNumberOfChannels > 0 {
            do {
                try session.setPreferredInputNumberOfChannels(AudioFormat.ChannelsMono)
            } catch let error {
                debug("Error setting number of input channels: \(error)")
            }
        }
    }
    
    func teardownAVAudioSession() {
        // TODO: Add in conditional to handle scenario where engine should remain running after disconnection
        if !self.audioPlayerNodeManager.isActive() && !self.isConnected {
            do {
                NotificationCenter.default.removeObserver(self)
                let session = AVAudioSession.sharedInstance()
                try session.setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
            } catch let error {
                debug("Error deactivating AVAudioSession: \(error)")
            }
        }
    }
    
    func setupAudioUnit() {
        debug("AVAudioEngineDevice::setupAudioUnit")
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
            AudioComponentInstanceDispose(audioUnit)
            self.audioUnit = nil
//            return false
            return
        }

        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Output, AVAudioEngineDevice.kInputBus,
                                      &streamDescription, streamDescriptionSize)
        if status != 0 {
            debug("Could not set stream format on input bus!")
//            return false
            return
        }

        debug("AVAudioEngineDevice::setupAudioUnit => setStreamDescription \n\tsize: \(streamDescriptionSize)\n\tstreamDescription: \(streamDescription)")
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Input, AVAudioEngineDevice.kOutputBus,
                                      &streamDescription, streamDescriptionSize)
        if status != 0 {
            debug("Could not set stream format on output bus!")
//            return false
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
//            return false
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
//            return false
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
//            return false
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
//            return false
            return
        }

        self.capturingContext.audioUnit = audioUnit

        return
    }

    func startAudioUnit() -> Bool {
        debug("AVAudioEngineDevice::startAudioUnit => START")
        guard let audioUnitUnwrapped = self.audioUnit else {
            return false
        }

        var result = false
        var failedInitializeAttempts: NSInteger = 0
        while failedInitializeAttempts < AVAudioEngineDevice.kMaxNumberOfAudioUnitInitializeAttempts {
            debug("AVAudioEngineDevice::startAudioUnit => failed attempts: \(failedInitializeAttempts)")
            let status: OSStatus = AudioOutputUnitStart(audioUnitUnwrapped)
            if status == noErr {
                result = true
                break
            }
            debug("Failed to start output on the Voice Processing I/O unit. Error= \(status).")
            failedInitializeAttempts += 1

            debug("Pause 100ms and try audio unit initialization again.")
            // TODO: review whether Thread.sleep causes synchronicity issues
            Thread.sleep(forTimeInterval: 0.1)
        }

        debug("AVAudioEngineDevice::startAudioUnit => END => started: \(result)")
        return result
    }

    func stopAudioUnit() -> Bool {
        debug("AVAudioEngineDevice::stopAudioUnit")
        guard let audioUnitUnwrapped = self.audioUnit else {
            return false
        }

        let status: OSStatus = AudioOutputUnitStop(audioUnitUnwrapped)
        if status != 0 {
            debug("Could not stop the audio unit!")
            return false
        }
        return true
    }

    func teardownAudioUnit() {
        debug("AVAudioEngineDevice::teardownAudioUnit => audioUnit: \(self.audioUnit)")
        if let audioUnitUnwrapped = self.audioUnit {
            AudioUnitUninitialize(audioUnitUnwrapped)
            AudioComponentInstanceDispose(audioUnitUnwrapped)
            self.audioUnit = nil
        }
    }

    // MARK: NSNotification Observers
    func deviceContext() -> AudioDeviceContext? {
        debug("AVAudioEngineDevice::deviceContext => rendering: \(self.renderingContext.deviceContext) capturing: \(self.capturingContext.deviceContext)")
        if self.renderingContext.deviceContext != nil {
            return self.renderingContext.deviceContext
        } else if self.capturingContext.deviceContext != nil {
            return self.capturingContext.deviceContext
        }
        return nil
    }

    func registerAVAudioSessionObservers() {
        debug("AVAudioEngineDevice::registerAVAudioSessionObservers")
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
        debug("AVAudioEngineDevice::handleAudioInterruption => type: \(notification)")
        guard let userInfo = notification.userInfo,
              let reasonRaw = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type: AVAudioSession.InterruptionType = AVAudioSession.InterruptionType(rawValue: reasonRaw) else {
            debug("AVAudioEngineDevice::handleAudioInterruption => parse error")
            return
        }

        myPropertyQueue.async {
            // If the worker block is executed, then context is guaranteed to be valid.
            if let context = self.deviceContext() {
                AudioDeviceExecuteWorkerBlock(context: context) {
                    if type == AVAudioSession.InterruptionType.began {
                        debug("Interruption began.")
                        self.interrupted = true
                        self.stopAudioUnit()
                    } else {
                        debug("Interruption ended.")
                        self.interrupted = false
                        self.startAudioUnit()
                    }
                }
            }
        }
    }

    @objc private func handleApplicationDidBecomeActive(notification: Notification) {
        debug("AVAudioEngineDevice::handleApplicationDidBecomeActive")
        myPropertyQueue.async {
            // If the worker block is executed, then context is guaranteed to be valid.
            if let context = self.deviceContext() {
                AudioDeviceExecuteWorkerBlock(context: context) {
                    if self.interrupted {
                        debug("Synthesizing an interruption ended event for iOS 9.x devices.")
                        self.interrupted = false
                        self.startAudioUnit()
                    }
                }
            }
        }
    }

    @objc private func handleRouteChange(notification: NSNotification) {
        debug("AVAudioEngineDevice::handleRouteChange => notification: \(notification)")
        // Check if the sample rate, or channels changed and trigger a format change if it did.
        guard let userInfo = notification.userInfo,
              let reasonRaw = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw) else {
            debug("AVAudioEngineDevice::handleRouteChange => parse error")
            return
        }
        let session = AVAudioSession.sharedInstance()
        debug("AVAudioEngineDevice::handleRouteChange =>\n\treason: \(reason.rawValue)\n\tcategory: \(session.category)\n\tmode: \(session.mode)\n\tsampleRate: \(session.sampleRate)")

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
                    debug("AVAudioEngineDevice::handleRouteChange => QUEUE - myPropertyQueue.async")
                    myPropertyQueue.async {
                        debug("AVAudioEngineDevice::handleRouteChange => START - myPropertyQueue.async")
                        // If the worker block is executed, then context is guaranteed to be valid.
                        if let context = self.deviceContext() {
                            debug("AVAudioEngineDevice::handleRouteChange => QUEUE - AudioDeviceExecuteWorkerBlock")
                            AudioDeviceExecuteWorkerBlock(context: context) {
                                debug("AVAudioEngineDevice::handleRouteChange => START - AudioDeviceExecuteWorkerBlock")
                                self.handleValidRouteChange()
                            }
                        } else {
                            debug("AVAudioEngineDevice::handleRouteChange => QUEUE - handleValidRouteChange - myPropertyQueue.async")
                            self.myPropertyQueue.async {
                                debug("AVAudioEngineDevice::handleRouteChange => START - handleValidRouteChange - myPropertyQueue.async")
                                self.handleValidRouteChange()
                            }
                        }
                        debug("AVAudioEngineDevice::handleRouteChange => END - myPropertyQueue.async")
                    }
            default:
                break
        }
    }

    func handleValidRouteChange() {
        debug("AVAudioEngineDevice::handleValidRouteChange")
        // Nothing to process while we are interrupted. We will interrogate the AVAudioSession once the interruption ends.
        if self.interrupted || self.audioUnit == nil {
            debug("AVAudioEngineDevice::handleValidRouteChange => do nothing")
            return
        }

        debug("A route change ocurred while the AudioUnit was started. Checking the active audio format.")

        // Determine if the format actually changed. We only care about sample rate and number of channels.
        guard let activeFormat: AudioFormat = activeFormat() else {
            return
        }

        if !activeFormat.isEqual(renderingFormat) || !activeFormat.isEqual(capturingFormat) {
            debug("Format changed, restarting with \(activeFormat)")

            // Signal a change by clearing our cached format, and allowing TVIAudioDevice to drive the process.
//            renderingFormat = nil
//            capturingFormat = nil

            self.myPropertyQueue.async {
                if let context = self.deviceContext() {
                    // Video SDK is connected
                    debug("AVAudioEngineDevice::handleValidRouteChange => BEGIN AudioDeviceFormatChanged")
                    self.handleFormatChange()
                    // Notify Video SDK about the format change
                    self.notifyVideoSdkOfFormatChange(context: context)
                    debug("AVAudioEngineDevice::handleValidRouteChange => END AudioDeviceFormatChanged")
                } else {
                    // Video SDK is disconnected or connecting
                    debug("AVAudioEngineDevice::handleValidRouteChange => BEGIN handleFormatChange")
                    // TODO: look at format change when playing audio node but not connected
                    self.callAudioDeviceFormatChangedOnStart()
                    self.handleFormatChange()
                    if self.audioPlayerNodeManager.anyPaused() {
                        debug("AVAudioEngineDevice::handleValidRouteChange => BEGIN startRenderingInternal to resume audio nodes")
                        self.startRenderingInternal(context: nil)
//                        self.setupAVAudioSession()
//                        AVAudioSession.sharedInstance().setActive(true, , options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
                    }
                    debug("AVAudioEngineDevice::handleValidRouteChange => END handleFormatChange")
                }
            }
        } else {
            debug("Format unchanged, ignoring")
        }
    }
    
    func callAudioDeviceFormatChangedOnStart() {
        self.didFormatChangeWhileDisconnected = true
    }
    
    func notifyVideoSdkOfFormatChange(context: AudioDeviceContext?) {
        if let context = context {
            self.didFormatChangeWhileDisconnected = false
            // Notify Video SDK about the format change
            // `AudioDeviceFormatChanged` will cause the Video SDK to
            // read the new rendering/capturing formats from the AVAudioEngineDevice
            // using `renderFormat()` and `captureFormat()`, and subsequently
            // instruct the AVAudioEngineDevice to stop/start capturing and rendering.
            AudioDeviceFormatChanged(context: context)
        }
    }
    
    func handleFormatChange() {
        debug("AVAudioEngineDevice::handleFormatChange => START")
        self.stopAudioUnit()
        DispatchQueue.main.sync {
            self.audioPlayerNodeManager.pauseAll(true)
        }
        self.teardownAudioUnit()
        self.setupAudioUnit()
        self.detachMusicNodes()
        self.teardownAudioEngine()
        do {
            let result = try AVAudioSession.sharedInstance().setPreferredSampleRate(Double(AVAudioEngineDevice.kPreferredSampleRate))
            debug("AVAudioEngineDevice::handleFormatChange => setPreferredSampleRate result: \(result) sampleRate: \(AVAudioEngineDevice.kPreferredSampleRate)")
        } catch let error {
            debug("AVAudioEngineDevice::handleFormatChange => setPreferredSampleRate error: \(error)")
        }
        self.getMaximumSliceSize()
        self.deallocateMemoryForAudioBuffers()
        self.allocateMemoryForAudioBuffers()

        // Nodes will be reattached as part of setupPlayoutAudioEngine
        self.setupAudioEngine()
        // TODO: restart rendering if there are paused nodes?
//            self.startRenderingInternal(context: self.renderingContext.deviceContext)
        debug("AVAudioEngineDevice::handleFormatChange => END")
    }

    @objc private func handleMediaServiceLost(notification: Notification) {
        debug("AVAudioEngineDevice::handleMediaServiceLost")

        myPropertyQueue.async {
            DispatchQueue.main.async {
                self.teardownAudioEngine()
            }
            // If the worker block is executed, then context is guaranteed to be valid.
            if let context = self.deviceContext() {
                AudioDeviceExecuteWorkerBlock(context: context) {
                    self.teardownAudioUnit()
                }
            }
        }
    }

    @objc private func handleMediaServiceRestored(notification: Notification) {
        debug("AVAudioEngineDevice::handleMediaServiceRestored")

        myPropertyQueue.async {
            DispatchQueue.main.async {
                self.setupAudioEngine()
            }
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

    // Next log statement left in for debugging purposes. Commented out to minimize operations on the real time audio thread
    debug("AVAudioEngineDevicePlayoutCallback =>\n\tinNumberOfFrames: \(inNumberFrames)\n\taudioBufferSizeInBytes: \(audioBufferSizeInBytes)\n\tabl buffer: \(abl?.first?.mData?.assumingMemoryBound(to: Int8.self).pointee)\n\tinput buffer: \(ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: Int8.self).pointee)\n\tmNumberChannels: \(ioData.pointee.mBuffers.mNumberChannels)\n\taudioSession sampleRate: \(AVAudioSession.sharedInstance().sampleRate)\n\taudioSession preferredSampleRate: \(AVAudioSession.sharedInstance().preferredSampleRate)")
    let status: AVAudioEngineManualRenderingStatus = renderBlock(inNumberFrames, ioData, &outputStatus)

    /*
     * Render silence if there are temporary mismatches between CoreAudio and our rendering format or AVAudioEngine
     * could not render the audio samples.
     */
    if inNumberFrames > maxFramesPerBuffer || status != AVAudioEngineManualRenderingStatus.success {
        if inNumberFrames > maxFramesPerBuffer {
            debug("Can handle a max of \(maxFramesPerBuffer) frames but got \(inNumberFrames). Status: \(status.rawValue) OutputStatus: \(outputStatus)")
        }
        // Next line left in for debugging purposes. Commented out to minimize operations on the real time audio thread
        debug("AVAudioEngineDevicePlayoutCallback => render silence - outputStatus: \(outputStatus) status: \(status.rawValue)")
        ioActionFlags.pointee = AudioUnitRenderActionFlags(rawValue: ioActionFlags.pointee.rawValue | AudioUnitRenderActionFlags.unitRenderAction_OutputIsSilence.rawValue)
        memset(ioData.pointee.mBuffers.mData, 0, Int(audioBufferSizeInBytes))
    }

    // Next line left in for debugging purposes. Commented out to minimize operations on the real time audio thread
//    debug("AVAudioEngineDevicePlayoutCallback => END inputData: \(ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: Int8.self).pointee) outputStatus: \(outputStatus) status: \(status.rawValue)")
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
        debug("Expected no more than \(AVAudioEngineDevice.kMaximumFramesPerBuffer) frames but got \(inNumberFrames).")
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
        debug("Expected AudioCapturerContext to have AudioUnit.")
        return noErr
    }

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
//    debug("RecordCallback => BEGIN renderBlock:\n\tmixedAudioBufferList: \(mixedAudioBufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Int8.self).pointee)\n\tinNumberFrames: \(inNumberFrames)")
    let ret: AVAudioEngineManualRenderingStatus = renderBlock(inNumberFrames, mixedAudioBufferList, &outputStatus)

    if ret != AVAudioEngineManualRenderingStatus.success {
        debug("AVAudioEngine failed mix audio => \(String(describing: ret.rawValue)), outputStatus: \(outputStatus)")
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
func debug(_ msg: String) {
    SwiftTwilioProgrammableVideoPlugin.debug(msg)
}
