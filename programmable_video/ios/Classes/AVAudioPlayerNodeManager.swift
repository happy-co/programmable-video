import Foundation
import TwilioVideo

internal class AVAudioPlayerNodeManager {
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

        debug("AVAudioPlayerNodeManager::addNode =>\n\tid: \(id)\n\tfile: \(fileName(nodeBundle.file))\n\tloop: \(nodeBundle.loop)")
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

    func isActive() -> Bool {
        return self.anyQueued() || self.anyPaused() || self.anyPlaying()
    }

    func getNode(_ id: Int) -> AVAudioPlayerNodeBundle? {
        guard let node = nodes[id] else {
            debug("AVAudioPlayerNodeManager::getNode => node not found for id: \(id)")
            return nil
        }

        return node
    }

    public func queueNode(_ id: Int) {
        guard let node = nodes[id] else {
            return
        }

        debug("AVAudioPlayerNodeManager::queueNode =>\n\tid: \(id)\n\tfile: \(fileName(node.file))\n\tloop: \(node.loop)\n\tplaying: \(node.playing)")
        node.queued = true
    }

    public func playNode(_ id: Int) {
        play(id)
    }

    func play(_ id: Int, position: AVAudioFramePosition = 0) {
        guard let node = nodes[id] else {
            return
        }
        node.queued = false

        debug("AVAudioPlayerNodeManager::play =>\n\tfile: \(fileName(node.file))\n\tloop: \(node.loop)\n\tplaying: \(node.playing)\n\tposition: \(position)")

        if !node.playing {
            let frameCount: AVAudioFrameCount = AVAudioFrameCount(node.file.length - position)

            node.playing = true

            node.player.scheduleSegment(node.file, startingFrame: position, frameCount: frameCount, at: nil) {
                debug("AVAudioPlayerNodeManager::segmentComplete => file: \(self.fileName(node.file)). playing: \(node.playing), startedAt: \(position), loop: \(node.loop), paused: \(self.isPaused(node.id))")
                if node.loop && node.playing && !self.isPaused(node.id) {
                    node.playing = false
                    self.play(node.id)
                } else {
                    node.playing = false
                }
            }
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
        debug("AVAudioPlayerNodeManager::stopNode => file: \(fileName(node.file))")

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
        debug("AVAudioPlayerNodeManager::pauseNode => paused node \(node.id) pauseTime: \(node.pauseTime)")
    }

    public func resumeNode(_ id: Int) {
        guard let node = nodes[id],
              let pausePosition = node.pauseTime else {
            return
        }

        if node.playing {
            return
        }

        debug("AVAudioPlayerNodeManager::resumeNode => node \(node.id), frame: \(pausePosition), volume: \(node.volume)")
        node.resumeAfterRendererStarted = false
        pausedNodes.removeValue(forKey: node.id)
        seekPosition(id, pausePosition)
    }

    public func setMusicVolume(_ id: Int, _ volume: Double) {
        guard let node = nodes[id] else {
            return
        }

        node.volume = volume
        var gain = volumeToGain(volume)

        debug("AVAudioPlayerNodeManager::setMusicVolume => id: \(id), volume: \(volume), gain: \(gain)")

        node.eq.globalGain = Float(gain)
    }

    func fadeOutNode(_ node: AVAudioPlayerNodeBundle) {
        debug("AVAudioPlayerNodeManager::fadeOutNode => START - node \(node.id), volume \(node.volume)")
        var volume = gainToVolume(node.eq.globalGain)
        var increment = volume / 10
        fadeOut(node, volume, increment)
        debug("AVAudioPlayerNodeManager::fadeOutNode => END - node \(node.id)")
    }

    func fadeOut(_ node: AVAudioPlayerNodeBundle, _ volume: Double, _ volumeIncrement: Double) {
        let vol = volume >= 0 ? volume : 0
        node.eq.globalGain = volumeToGain(volume)
        debug("AVAudioPlayerNodeManager::fadeOut => node \(node.id), volume \(node.volume) currentVolume: \(volume)")

        if volume > 0 {
            let timeSecs = 0.001  /// 1 ms
            Thread.sleep(forTimeInterval: timeSecs)
            let nextStep = volume - volumeIncrement
            fadeOut(node, nextStep, volumeIncrement)
        }
    }

    func fadeInNode(_ node: AVAudioPlayerNodeBundle) {
        debug("AVAudioPlayerNodeManager::fadeInNode => START - node \(node.id), volume \(node.volume), fadingIn: \(node.fadingIn)")
        if !node.fadingIn {
            let increment = node.volume / 10
            node.fadingIn = true
            fadeIn(node, 0, increment)
            node.fadingIn = false
        }
        debug("AVAudioPlayerNodeManager::fadeInNode => END - node \(node.id)")
    }

    func fadeIn(_ node: AVAudioPlayerNodeBundle, _ volume: Double, _ volumeIncrement: Double) {
        let vol = volume <= node.volume ? volume : node.volume
        node.eq.globalGain = volumeToGain(vol)
        debug("AVAudioPlayerNodeManager::fadeIn => node \(node.id), volume \(node.volume) currentVolume: \(volume)")

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
        debug("AVAudioPlayerNodeManager::seekPosition => id: \(id), positionInMillis: \(positionInMillis), framePosition: \(framePosition), lengthInFrames: \(node.file.length)")

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
        for nodeBundle in nodes.values where nodeBundle.playing {
            debug("AVAudioPlayerNodeManager::anyPlaying => node \(nodeBundle.id) is playing")
            result = true
            break
        }
        debug("AVAudioPlayerNodeManager::anyPlaying => \(result)")
        return result
    }

    public func anyQueued() -> Bool {
        var result = false
        for nodeBundle in nodes.values where nodeBundle.queued {
            debug("AVAudioPlayerNodeManager::anyQueued => node \(nodeBundle.id) is queued")
            result = true
            break
        }
        debug("AVAudioPlayerNodeManager::anyQueued => \(result)")
        return result
    }

    public func anyPaused() -> Bool {
        let anyPaused = !pausedNodes.values.isEmpty
        debug("AVAudioPlayerNodeManager::anyPaused => \(anyPaused)")
        return anyPaused
    }

    func isPaused(_ id: Int) -> Bool {
        return pausedNodes[id] != nil
    }

    public func pauseAll(_ resumeAfterRendererStarted: Bool = false) {
        self.nodes.values.forEach { (node: AVAudioPlayerNodeBundle) in
            let nodeIsPlaying = node.player.isPlaying
            debug("AVAudioPlayerNodeManager::pauseAll => node \(node.id) isPlaying: \(nodeIsPlaying)")
            if nodeIsPlaying {
                self.pauseNode(node.id, resumeAfterRendererStarted)
            }
        }
    }

    public func resumeAll() {
        debug("AVAudioPlayerNodeManager::resumeAll => pausedNodes: \(self.pausedNodes.count)")
        self.pausedNodes.values.forEach { (node: AVAudioPlayerNodeBundle) in
            if node.resumeAfterRendererStarted {
                self.resumeNode(node.id)
            }
        }
    }
}

internal class AVAudioPlayerNodeBundle {
    let id: Int
    let player: AVAudioPlayerNode
    let reverb: AVAudioUnitReverb
    let file: AVAudioFile
    let loop: Bool
    var pauseTime: Int64?
    var queued: Bool = false
    var playing: Bool = false
    var fadingIn: Bool = false
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
