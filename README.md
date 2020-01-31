# twilio_unofficial_programmable_video
Unofficial Twilio Programmable Video Flutter package.

This package is currently work-in-progress and should not be used for production apps. We can't guarantee that the current API implementation will stay the same between versions, until we have reached v1.0.0.

## Join the community
If you have any question or problems, please join us on [Discord](https://discord.gg/42x46NH)

## FAQ
Read the [Frequently Asked Questions](https://gitlab.com/twilio-flutter-unofficial/programmable-video/blob/master/FAQ.md) first before creating a new issue.

## Supported platforms
* Android
* ~~iOS~~ (not yet)
* ~~Web~~ (not yet)

## Getting started

### Prerequisites
Before you can start using the plugin you need to make sure you have everything setup for your project.

First add it as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).  
For example:
```yaml
dependencies:
  twilio_unofficial_programmable_video: '^0.0.1'
```

#### Proguard (Android only)
Add the following lines to your proguard-project.txt file.

```
-keep class tvi.webrtc.** { *; }
-keep class com.twilio.video.** { *; }
-keepattributes InnerClasses
```

#### Permissions
For this plugin to work you will have to add the right permissions for your platform.

##### Android
Open the `AndroidManifest.xml` file in your `android/app/src/main` directory and add the following device permissions:

```xml
...
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA"/>
...
```

### Connect to a Room
Call `TwilioUnofficialProgrammableVideo.connect()` to connect to a Room in your Flutter application. Once connected, you can send and receive audio and video streams with other Participants who are connected to the Room.

```dart
void _onConnected(RoomEvent roomEvent) {
  print('Connected to ${roomEvent.room.name}');
}

Future<Room> connectToRoom() async {
  var connectOptions = ConnectOptions(accessToken)
                          ..roomName(roomName) // Optional room name.
                          ..region(region) // Optional region.
                          ..preferAudioCodecs([OpusCodec()]) // Optional list of preferred AudioCodecs.
                          ..preferVideoCodecs([H264Codec()]) // Optional list of preferred VideoCodecs.
                          ..audioTracks([LocalAudioTrack(true)]) // Optional list of audio tracks.
                          ..videoTracks([LocalVideoTrack(true, CameraCapturer(CameraSource.FRONT_CAMERA))]); // Optional list of video tracks.
  var room = await TwilioUnofficialProgrammableVideo.connect(connectOptions);
  room.onConnected(_onConnected);
}
```

You **must** pass the Access Token when connecting to a Room.

### Join a Room
If you'd like to join a Room you know already exists, you handle that exactly the same way as creating a room: just pass the Room name to the `connect` method. Once in a Room, you'll receive a `participantConnected` event for each Participant that successfully joins. Querying the `remoteParticipants` getter will return any existing Participants who have already joined the Room.

```dart
void _onConnected(RoomEvent roomEvent) {
  print('Connected to ${roomEvent.room.name}');
}

Future<Room> connectToRoom() async {
  var connectOptions = ConnectOptions(accessToken)
                          ..roomName(roomName) // Optional room name.
                          ..region(region) // Optional region.
                          ..preferAudioCodecs([OpusCodec()]) // Optional list of preferred AudioCodecs.
                          ..preferVideoCodecs([H264Codec()]) // Optional list of preferred VideoCodecs.
                          ..audioTracks([LocalAudioTrack(true)]) // Optional list of audio tracks.
                          ..videoTracks([LocalVideoTrack(true, CameraCapturer(CameraSource.FRONT_CAMERA))]); // Optional list of video tracks.
  var room = await TwilioUnofficialProgrammableVideo.connect(connectOptions);
  room.onConnected(_onConnected);
}
```

### Set up local media
You can capture local media from your device's microphone or camera in the following ways:

```dart
// Create an audio track.
var localAudioTrack = LocalAudioTrack(true);

// A video track request an implementation of VideoCapturer.
var cameraCapturer = CameraCapturer(CameraSource.FRONT_CAMERA);

// Create a video track.
var localVideoTrack = LocalVideoTrack(true, cameraCapturer);

// Getting the local video track widget.
// This can only be called after the TwilioUnofficialProgrammableVideo.connect() is called.
var widget = localVideoTrack.widget();
```

### Connect as a publish-only Participant
It is currently not possible to connect as a publish-only participant.

### Working with Remote Participants

#### Handle Connected Participants
When you join a Room, Participants may already be present. You can check for existing Participants in the `connected` event by using the `remoteParticipants` getter.

```dart
// Connect to a room.
var room = await TwilioUnofficialProgrammableVideo.connect(connectOptions);

room.onConnected((RoomEvent roomEvent) {
  print('Connected to ${roomEvent.room.name}');
});

room.onConnectFailure((RoomEvent roomEvent) {
    print('Failed connecting, exception: ${roomEvent.exception.message}');
});

room.onDisconnected((RoomEvent roomEvent) {
  print('Disconnected from ${roomEvent.room.name}');
});

room.onRecordingStarted((RoomEvent roomEvent) {
  print('Recording started in ${roomEvent.room.name}');
});

room.onRecordingStopped((RoomEvent roomEvent) {
  print('Recording stopped in ${roomEvent.room.name}');
});

// ... Assume we have received the connected callback.

// After receiving the connected callback the LocalParticipant becomes available.
var localParticipant = room.localParticipant;
print('LocalParticipant ${room.localParticipant.identity}');

// Get the first participant from the room.
var remoteParticipant = room.remoteParticipants[0];
print('RemoteParticipant ${remoteParticipant.identity} is in the room');
```

#### Handle Participant Connection Events
When Participants connect to or disconnect from a Room that you're connected to, you'll be notified via an event listener. These events help your application keep track of the participants who join or leave a Room.

```dart
// Connect to a room.
var room = await TwilioUnofficialProgrammableVideo.connect(connectOptions);

room.onParticipantConnected((RoomEvent roomEvent) {
  print('Participant ${roomEvent.remoteParticipant.identity} has joined the room');
});

room.onParticipantDisconnected((RoomEvent roomEvent) {
  print('Participant ${roomEvent.remoteParticipant.identity} has left the room');
});

```

#### Display a Remote Participant's Widget
To see the Video Tracks being sent by remote Participants, we need to add their widgets to the tree.

```dart
room.onParticipantConnected((RoomEvent roomEvent) {
  // We can respond when the Participant adds a VideoTrack by adding the widget to the tree.
  roomEvent.remoteParticipant.onVideoTrackSubscribed((RemoteParticipantEvent remoteParticipantEvent) {
    var mirror = false;
    _widgets.add(remoteParticipantEvent.remoteParticipant.widget(mirror));
  });
});
```

### Participating in a Room

#### Display a Camera Preview
Just like Twilio we totally get you want to look fantastic before entering a Room. Sadly that isn't yet implemented so you should go analog and use a mirror.

#### Disconnect from a Room
You can disconnect from a Room you're currently participating in. Other Participants will receive a `participantDisconnected` event.

```dart
// To disconnect from a Room, we call:
await room.disconnect();

// This results in a call to Room#onDisconnected
room.onDisconnected((RoomEvent roomEvent) {
  print('Disconnected from ${roomEvent.room.name}');
});

```

### Room reconnection
A Room reconnection is triggered due to a signaling or media reconnection event.

```dart
/// Exception will be either TwilioException.SIGNALING_CONNECTION_DISCONNECTED_EXCEPTION or TwilioException.MEDIA_CONNECTION_ERROR_EXCEPTION
room.onReconnecting((RoomEvent roomEvent) {
  print('Reconnecting to room ${roomEvent.room.name}, exception = ${roomEvent.exception.message}');
});

room.onReconnected((RoomEvent roomEvent) {
  print('Reconnected to room ${roomEvent.room.name}');
});
```

## Configuring Audio, Video Input and Output devices
Taking advantage of the ability to control input and output devices lets you build a better end user experience.

### Selecting a specific Video Input
The `CameraCapturer` class is used to provide video frames for `LocalVideoTrack` from a given `CameraSource`.

```dart
// Share your camera.
var cameraCapturer = CameraCapturer(CameraSource.FRONT_CAMERA);
var localVideoTrack = LocalVideoTrack(true, cameraCapturer);

// Render camera to a widget (only after connect event).
var mirror = true;
var widget = localVideoTrack.widget(mirror);
_widgets.add(widget);

// Switch the camera source.
var cameraSource = cameraCapturer.getCameraSource();
cameraCapturer.switchCamera();
primaryVideoView.setMirror(cameraSource == CameraSource.BACK_CAMERA);
```

### Selecting a specific Audio output
Using the `TwilioUnofficialProgrammableVideo` class, you can specify if audio is routed through the headset or speaker.

```dart
// Route audio through speaker
TwilioUnofficialProgrammableVideo.setSpeakerphoneOn(true);

// Route audio through headset
TwilioUnofficialProgrammableVideo.setSpeakerphoneOn(false);
```

## Enable debug logging
Using the `TwilioUnofficialProgrammableVideo` class, you can enable native and dart logging of the plugin.

```dart
var nativeEnabled = true;
var dartEnabled = true;
TwilioUnofficialProgrammableVideo.debug(native: nativeEnabled, dart: dartEnabled);
```

## API
Keep in mind, you can't generate access tokens for programmable-video using the [TestCredentials](https://www.twilio.com/docs/iam/test-credentials#supported-resources), use your own.

You can easily generate an access token in the Twilio dashboard with the [Testing Tools](https://www.twilio.com/console/video/project/testing-tools)

## Events table
Reference table of all the events the plugin supports and their native platform counter part.

| Type              | Event name                   | Android                        | Implemented |
| :---------------- | ---------------------------- | ------------------------------ | ----------- |
| Room              | connectFailure               | onConnectFailure               | X           |
| Room              | connected                    | onConnected                    | X           | 
| Room              | disconnected                 | onDisconnected                 | X           |
| Room              | participantConnected         | onParticipantConnected         | X           |
| Room              | participantDisconnected      | onParticipantDisconnected      | X           |
| Room              | reconnected                  | onReconnected                  | X           |
| Room              | reconnecting                 | onReconnecting                 | X           |
| Room              | recordingStarted             | onRecordingStarted             | X           |
| Room              | recordingStopped             | onRecordingStopped             | X           |
| RemoteParticipant | audioTrackDisabled           | onAudioTrackDisabled           |             |
| RemoteParticipant | audioTrackEnabled            | onAudioTrackEnabled            |             |
| RemoteParticipant | audioTrackPublished          | onAudioTrackPublished          |             |
| RemoteParticipant | audioTrackSubscribed         | onAudioTrackSubscribed         |             |
| RemoteParticipant | audioTrackSubscriptionFailed | onAudioTrackSubscriptionFailed |             |
| RemoteParticipant | audioTrackUnpublished        | onAudioTrackUnpublished        |             |
| RemoteParticipant | audioTrackUnsubscribed       | onAudioTrackUnsubscribed       |             |
| RemoteParticipant | dataTrackPublished           | onDataTrackPublished           |             |
| RemoteParticipant | dataTrackSubscribed          | onDataTrackSubscribed          |             |
| RemoteParticipant | dataTrackSubscriptionFailed  | onDataTrackSubscriptionFailed  |             |
| RemoteParticipant | dataTrackUnpublished         | onDataTrackUnpublished         |             |
| RemoteParticipant | dataTrackUnsubscribed        | onDataTrackUnsubscribed        |             |
| RemoteParticipant | videoTrackDisabled           | onVideoTrackDisabled           |             |
| RemoteParticipant | videoTrackEnabled            | onVideoTrackEnabled            |             |
| RemoteParticipant | videoTrackPublished          | onVideoTrackPublished          |             |
| RemoteParticipant | vdeoTrackSubscribed          | onVideoTrackSubscribed         | X           |
| RemoteParticipant | videoTrackSubscriptionFailed | onVideoTrackSubscriptionFailed |             |
| RemoteParticipant | videoTrackUnpublished        | onVideoTrackUnpublished        |             |
| RemoteParticipant | videoTrackUnsubscribed       | onVideoTrackUnsubscribed       | X           |

# Example
Check out our comprehensive [example](https://gitlab.com/twilio-flutter-unofficial/programmable-video/tree/master/example) provided with this plugin.

# Development and Contributing
Interested in contributing? We love merge requests! See the [Contribution](https://gitlab.com/twilio-flutter-unofficial/programmable-video/blob/master/CONTRIBUTING.md) guidelines.
