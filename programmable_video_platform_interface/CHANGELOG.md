## 0.5.0

- **BREAKING** Made `exception` property of ConnectFailure, Reconnecting and Disconnected events nullable.

## 0.4.0+1

- Removed incorrect `!` from `local_video_track_model.dart`.

## 0.4.0

- **BREAKING CHANGE**: Added null safety support.

## 0.3.2

- Added method for fetching stats.

## 0.3.1

- Added method for checking if device has a builtin earpiece.

## 0.3.0

- **BREAKING CHANGE**: Updated plugin_platform_interface dep.

## 0.2.3

- Added support for Network Quality API.

## 0.2.2

- Added `enableRemoteAudioTrack({bool enable, String sid})` and `isRemoteAudioTrackPlaybackEnabled(String sid)` methods.

## 0.2.1+0

- Added `hasTorch()` and `setTorch(bool enabled)` methods.

## 0.2.0+1

- Fixed unhandled exception when receiving a remote data track message.

## 0.2.0

- **BREAKING CHANGE**: SwitchCamera() can now throw a FormatException if it failed to parse to a CameraSource
- **BREAKING CHANGE**: `DataTrackModel` has been replaced by `LocalDataTrackModel`
- **BREAKING CHANGE**: `RemoteDataTrackModel` no longer extends `DataTrackModel` as `DataTrackModel`
    has been removed.
- **BREAKING CHANGE**: `TrackModel` is now an abstract class and is no longer meant to be used directly.
    Various implementations of `TrackModel` should now be used depending on the use case.
- **BREAKING CHANGE**: `LocalAudioTrackModel` has been added so the `TrackModel` should not be used
    anymore to represent LocalAudioTrack's.
- The models now assert that all needed data is available when using the `FromEventChannelMap`
    factory. To see what data is needed for a model see the asserts on the model's constructor.
- `LocalDataTrackModel` now has a toMap function.

## 0.1.0+3

- Removed wrong assertion of `localParticipant` in `Room` model

## 0.1.0+2

- Removed wrong assertion of `mediaRegion` in `Room` model

## 0.1.0+1

- All the files are now correctly exported from the `twilio_programmable_video_platform_interface.dart` file

## 0.1.0

- Get rid of pre-release version

## 0.0.1

- Initial release.
