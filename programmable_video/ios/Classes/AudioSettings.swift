internal class AudioSettings: NSObject {
    var speakerEnabled: Bool = true
    var bluetoothPreferred: Bool = true

    init(speakerEnabled: Bool = true, bluetoothEnabled: Bool = true) {
        self.speakerEnabled = speakerEnabled
        self.bluetoothPreferred = bluetoothEnabled
    }

    func reset() {
        self.speakerEnabled = true
        self.bluetoothPreferred = true
    }
}
