# twilio_unofficial_programmable_video

Unofficial Twilio Programmable Video Flutter package.

This package is currently work-in-progress and should not be used for production apps. We can't guarantee that the current API implementation will stay the same between versions, until we have reached v1.0.0.

## Join the community
If you have any question or problems, please join us on [Discord](https://discord.gg/42x46NH)

## Supported platforms
* Android
* ~~iOS~~ (not yet)
* ~~Web~~ (not yet)

## Prerequisites
Before you can start using the plugin you need to make sure you have everything setup for your project.

First add it as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).  
For example:
```yaml
dependencies:
  twilio_unofficial_programmable_video: '^0.0.1'
```

### Permissions
For this plugin to work you will have to add the right permissions for your platform.

#### Android
Open the `AndroidManifest.xml` file in your `android/app/src/main` directory and add the following device permissions:
```xml
...
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA"/>
...
```

## API

Keep in mind, you can't generate access tokens for programmable-video using the [TestCredentials](https://www.twilio.com/docs/iam/test-credentials#supported-resources), use your own.

You can easily generate an access token in the Twilio dashboard with the [Testing Tools](https://www.twilio.com/console/video/project/testing-tools)

## Connecting

To connect to a room you can do the following:

```dart
Future<void> connectToRoom() async {
  var connectOptions = ConnectOptions("<ACCESS_TOKEN>")
                          ..roomName("<ROOM_NAME>") // Optional room name.
                          ..region("<REGION>") // Optional region.
                          ..preferAudioCodecs([OpusCodec()]) // Optional list of preferred AudioCodecs.
                          ..audioTracks([LocalAudioTrack(true)]) // Optional list of audio tracks.
                          ..videoTracks([LocalVideoTrack(true, VideoCapturer.FRONT_CAMERA)]); // Optional list of video tracks.
  var room = await TwilioUnofficialProgrammableVideo.connect(connectOptions);
}
```

## Events table
Reference table of all the events the plugin supports and their native platform counter part.

| Type              | Event name                   | Android                        | iOS |
| :---------------- | ---------------------------- | ------------------------------ | --- |
| Room              | connectFailure               | onConnectFailure               |     |
| Room              | connected                    | onConnected                    |     | 
| Room              | disconnected                 | onDisconnected                 |     |
| Room              | participantConnected         | onParticipantConnected         |     |
| Room              | participantDisconnected      | onParticipantDisconnected      |     |
| Room              | reconnected                  | onReconnected                  |     |
| Room              | reconnecting                 | onReconnecting                 |     |
| Room              | recordingStarted             | onRecordingStarted             |     |
| Room              | recordingStopped             | onRecordingStopped             |     |
| RemoteParticipant | audioTrackDisabled           | onAudioTrackDisabled           |     |
| RemoteParticipant | audioTrackEnabled            | onAudioTrackEnabled            |     |
| RemoteParticipant | audioTrackPublished          | onAudioTrackPublished          |     |
| RemoteParticipant | audioTrackSubscribed         | onAudioTrackSubscribed         |     |
| RemoteParticipant | audioTrackSubscriptionFailed | onAudioTrackSubscriptionFailed |     |
| RemoteParticipant | audioTrackUnpublished        | onAudioTrackUnpublished        |     |
| RemoteParticipant | audioTrackUnsubscribed       | onAudioTrackUnsubscribed       |     |
| RemoteParticipant | dataTrackPublished           | onDataTrackPublished           |     |
| RemoteParticipant | dataTrackSubscribed          | onDataTrackSubscribed          |     |
| RemoteParticipant | dataTrackSubscriptionFailed  | onDataTrackSubscriptionFailed  |     |
| RemoteParticipant | dataTrackUnpublished         | onDataTrackUnpublished         |     |
| RemoteParticipant | dataTrackUnsubscribed        | onDataTrackUnsubscribed        |     |
| RemoteParticipant | videoTrackDisabled           | onVideoTrackDisabled           |     |
| RemoteParticipant | videoTrackEnabled            | onVideoTrackEnabled            |     |
| RemoteParticipant | videoTrackPublished          | onVideoTrackPublished          |     |
| RemoteParticipant | vdeoTrackSubscribed          | onVideoTrackSubscribed         |     |
| RemoteParticipant | videoTrackSubscriptionFailed | onVideoTrackSubscriptionFailed |     |
| RemoteParticipant | videoTrackUnpublished        | onVideoTrackUnpublished        |     |
| RemoteParticipant | videoTrackUnsubscribed       | onVideoTrackUnsubscribed       |     |

# Example
Check out our comprehensive [example](/example) provided with this plugin.

# Development and Contributing
Interested in contributing? We love merge requests! See the [Contribution](CONTRIBUTING.md) guidelines.
