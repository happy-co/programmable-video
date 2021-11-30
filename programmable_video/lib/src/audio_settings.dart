part of twilio_programmable_video;

class AudioSettings {
  bool speakerphoneEnabled;
  bool bluetoothPreferred;

  AudioSettings({
    required this.speakerphoneEnabled,
    required this.bluetoothPreferred,
  });

  factory AudioSettings._fromMap(Map<String, dynamic> settingsMap) {
    return AudioSettings(
      speakerphoneEnabled: settingsMap['speakerphoneEnabled'] as bool? ?? false,
      bluetoothPreferred: settingsMap['bluetoothPreferred'] as bool? ?? false,
    );
  }
}
