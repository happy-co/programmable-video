## 0.6.4

- **iOS**: Adjusted `AudioDevice` initialization logic to allow users of the plugin to provide a custom `AudioDevice`.
- **iOS**: Added `AVAudioEngineDevice`, a custom `AudioDevice`. Details in README.md.
- **Android**: Fixed build issue with gradle version 4.1.0 and higher

## 0.6.3+1

- Added fallback logic for when `Camera2Capturer` is not supported on Android.

## 0.6.3

- Introduced `networkQualityLevel` property and `onNetworkQualityLevelChanged` event to the `ParticipantWidget`.

## 0.6.2

- Upgraded TwilioVideo iOS SDK to '3.7'.
- Upgraded TwilioVideo Android SDK to '5.12.+'.

## 0.6.1

- Introduced `enablePlayback` and `isPlaybackEnabled` methods to the `RemoteAudioTrack`.

## 0.6.0+1

- Abort connect and throw `MissingCameraException` if no camera is found for specified `CameraSource`.

## 0.6.0+0

- **BREAKING CHANGE**: Switched over to `Camera2Capturer` from `CameraCapturer` on Android.
- **BREAKING CHANGE**: Increased minSdk for Android to `21`.
- Introduced `hasTorch()` and `setTorch(bool enabled)` methods on `CameraCapturer`.
- Introduced `onCameraSwitched`, `onFirstFrameAvailable`, `onCameraError` streams on `CameraCapturer`.

## 0.5.0+4

- Fixed unhandled exception when dominant speaker event contains no remote participant.

## 0.5.0+3

* Remote participants that have left the room will no longer be in the `Room.remoteParticipants` list.

## 0.5.0+2

* Upgraded Twilio SDK for Android from version `5.7.+` to `5.8.+`
* Upgraded Twilio SDK for iOS from version `3.3` to `3.4`

## 0.5.0+1

* `Room` now updates correctly again from `ParticipantConnected` and
    `DominantSpeakerChanged` events.
* `Room.onReconnecting` is now instantiated in the constructor of
    `Room`.

## 0.5.0

* **BREAKING CHANGE**: The 'send' method of the 'LocalDataTrack'
    class can now throw a 'TwilioException'.
* **BREAKING CHANGE**: The 'sendBuffer' method of the 'LocalDataTrack'
    class can now throw a 'TwilioException'.
* **BREAKING CHANGE**: The 'connect' method of the 'TwilioProgrammableVideo'
    class can now throw a 'TwilioException'.
* 'TwilioException' now has more error codes available through static properties.

## 0.4.0

* **BREAKING CHANGE**: The 'SwitchCamera' method of the 'CameraCapturer'
    class can now throw a 'FormatException' on IOS and Android.
* `LocalDataTrack` now uses the DataTrackOptions correctly again.
    
## 0.3.3+4

* Upgraded Twilio SDK for Android from version `5.6.+` to `5.7.+`
* Upgraded Twilio SDK for iOS from version `3.2` to `3.3`
* Upgraded `permission_handler` to latest version

## 0.3.3+3

* AudioTracks, VideoTracks and DataTracks are optional in
  `ConnectOptions`. Stopped mapping them when equals to `null`.

## 0.3.3+2

* Stopped importing implementation files from the platform interface
* Upgraded the platform interface version

## 0.3.3+1

* More like a house-keeping release after platform release

## 0.3.3

* Implemented the platform interface

## 0.3.2+1

* Fix passing `key` into the local participant widget

## 0.3.2

* Implemented DataTrack on IOS

## 0.3.1+5

* Upgraded Twilio SDK for Android from version `5.1.+` to `5.6.+`

## 0.3.1+4

* Fixes broken release `0.3.1+3`
* Added Flutter SDK constraint to meet new `pubspec.yaml` formatting

## 0.3.1+3

* **Note:** This version is BROKEN, do not use
* Added Automatic Subscription connection option

## 0.3.1+2

* Added Dominant Speaker Changed Events

## 0.3.1+1

* Add `getSpeakerphoneOn` method for reading the speakerphone mode

## 0.3.1

* Added Region enums for both `ConnectOptions.region` and `Room.mediaRegion` instead of string values

## 0.3.0+2

* Android: Fix Bluetooth crash on emulators
* Upgraded `permission_handler` to latest version

## 0.3.0+1

* Align `README.md` with Twilio OSS law
* Added workaround for build failure due to a bug in the Twilio SDK for Android
* Upgraded Twilio SDK for Android from version `5.1.0` to `5.1.+`
* Upgraded Android Studio Gradle plugin from version `3.5.0` to `3.6.0`

## 0.3.0

* Removed occurrence of the `unofficial` word

## 0.2.0

* Implemented iOS functionality, matching the android side.
* Added DataTrack API (Android only)
* Added Local Participant Events (Android only)
* Android: Route audio through Bluetooth headset

## 0.1.2

* Android: Switch speaker mode based on headset plug

## 0.1.1+1

* Fixed Android crashes when joining/disconnecting multiple times

## 0.1.1

* Better error handling on denied permissions
* Android: Improved re-requesting permission and otherwise open App Settings

## 0.1.0+2

* Added animated GIF to show of the example app
* Fixed typo in kotlin error message

## 0.1.0+1

* Applied health suggestions

## 0.1.0

* Initial Android release
