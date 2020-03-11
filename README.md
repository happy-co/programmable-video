# twilio_programmable_video
Flutter plugin for [Twilio Programmable Video](https://www.twilio.com/video?utm_source=opensource&utm_campaign=flutter-plugin), which enables you to build real-time videocall applications (WebRTC) \
This Flutter plugin is a community-maintained project for [Twilio Programmable Video](https://www.twilio.com/video?utm_source=opensource&utm_campaign=flutter-plugin) and not maintained by Twilio. If you have any issues, please file an issue instead of contacting support.

This package is currently work-in-progress and should not be used for production apps. We can't guarantee that the current API implementation will stay the same between versions, until we have reached v1.0.0.

# Example
Check out our comprehensive [example](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/example) provided with this plugin.

[![Twilio Programmable Video Example](https://j.gifs.com/5QEyOB.gif)](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/example "Twilio Programmable Video Example")

## Join the community
If you have any question or problems, please join us on [Discord](https://discord.gg/42x46NH)

## FAQ
Read the [Frequently Asked Questions](https://gitlab.com/twilio-flutter/programmable-video/blob/master/FAQ.md) first before creating a new issue.

## Supported platforms
* Android
* iOS
* ~~Web~~ (not yet)

## Getting started

### Prerequisites
Before you can start using the plugin you need to make sure you have everything setup for your project.

#### Android
For this plugin to work for Android, you will have to tweak a few files.

##### Permissions
Open the `AndroidManifest.xml` file in your `android/app/src/main` directory and add the following device permissions:

```xml
...
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
...
```

##### Proguard
Add the following lines to your proguard-project.txt file.

```
-keep class tvi.webrtc.** { *; }
-keep class com.twilio.video.** { *; }
-keepattributes InnerClasses
```

##### Create an `attrs.xml` file
Due to a [known bug](https://github.com/twilio/video-quickstart-android/issues/479) in the Twilio SDK for Android you could encounter the following error:
```
FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:processDebugResources'.
  > A failure occurred while executing com.android.build.gradle.internal.tasks.Workers$ActionFacade
    > Android resource linking failed
     /home/username/.gradle/caches/transforms-2/files-2.1/f4e760f55cdecc03c707f67f08b08f3d/jetified-video-android-5.1.0/res/values/values.xml:13:5-17:25: AAPT: error: resource attr/overlaySurface (aka twilio.flutter.programmable_video_example:attr/overlaySurface) not found.
```

To solve this issue create a file named `attrs.xml` to path
`android/app/src/main/res/values/` with the following content:
```
<?xml version="1.0" encoding="utf-8"?>
<!-- this file is necessary until the bug below is solved! -->
<!-- https://github.com/twilio/video-quickstart-android/issues/479 -->
<resources>
    <attr name="overlaySurface" format="boolean" />
</resources>
```

#### iOS
For this plugin to work for iOS, you will have to tweak a few files.

##### Permissions
Open the `Info.plist` file in your `ios/Runner` directory and add the following permissions:
```
...
<key>NSCameraUsageDescription</key>
<string>Your message to user when the camera is accessed for the first time</string>
<key>NSMicrophoneUsageDescription</key>
<string>Your message to user when the microphone is accessed for the first time</string>
<key>io.flutter.embedded_views_preview</key>
<true/>
...
```

##### Setting minimal iOS target to 11
1. In Xcode, open `Runner.xcworkspace` in your app's `ios` folder.
2. To view your app’s settings, select the **Runner** project in the Xcode project navigator. Then, in the main view sidebar, select the **Runner** target.
3. Select the **General** tab.
4. In the **Deployment Info** section, set the Target to iOS 11.

##### Background Modes
To allow a connection to a Room to be persisted while an application is running in the background, you must select the Audio, AirPlay, and Picture in Picture background mode from the Capabilities project settings page. See [Twilio Docs](https://www.twilio.com/docs/video/ios-v3-getting-started#background-modes) for more information.

### Connect to a Room
Call `TwilioProgrammableVideo.connect()` to connect to a Room in your Flutter application. Once connected, you can send and receive audio and video streams with other Participants who are connected to the Room.

```dart
Room _room;
final Completer<Room> _completer = Completer<Room>();

void _onConnected(RoomConnectedEvent event) {
  print('Connected to ${event.room.name}');
  _completer.complete(_room);
}

void _onConnectFailure(RoomConnectFailureEvent event) {
  print('Failed to connect to room ${event.room.name} with exception: ${event.exception}');
  _completer.completeError(event.exception);
}
  
Future<Room> connectToRoom() async {
  var connectOptions = ConnectOptions(
    accessToken,
    roomName: roomName,                   // Optional name for the room
    region: region,                       // Optional region.
    preferAudioCodecs: [OpusCodec()],     // Optional list of preferred AudioCodecs
    preferVideoCodecs: [H264Codec()],     // Optional list of preferred VideoCodecs.
    audioTracks: [LocalAudioTrack(true)], // Optional list of audio tracks.
    dataTracks: [
      LocalDataTrack(
        DataTrackOptions(
          ordered: ordered,                      // Optional, Ordered transmission of messages. Default is `true`.
          maxPacketLifeTime: maxPacketLifeTime,  // Optional, Maximum retransmit time in milliseconds. Default is [DataTrackOptions.defaultMaxPacketLifeTime]
          maxRetransmits: maxRetransmits,        // Optional, Maximum number of retransmitted messages. Default is [DataTrackOptions.defaultMaxRetransmits]
          name: name                             // Optional
        ),                                // Optional
      ),
    ],                                    // Optional list of data tracks   
    videoTracks([LocalVideoTrack(true, CameraCapturer(CameraSource.FRONT_CAMERA))]), // Optional list of video tracks. 
    enableNetworkQuality: true,           // Optional enable or disable the Network Quality API. Default is `false`
    // The following is optional if you only want to monitor the LocalParticipant, but required if you
    // want to monitor the Network Quality of RemoteParticipants
    // It sets the verbosity level for network quality information returned by the Network Quality API
    networkQualityConfiguration: NetworkQualityConfiguration(
      remote: NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_MINIMAL,
    ),
  );
  _room = await TwilioProgrammableVideo.connect(connectOptions);
  _room.onConnected.listen(_onConnected);
  _room.onConnectFailure.listen(_onConnectFailure);
  return _completer.future;
}
```

You **must** pass the [Access Token](https://gitlab.com/twilio-flutter/programmable-video/blob/master/README.md#access-tokens) when connecting to a Room.

### Join a Room
If you'd like to join a Room you know already exists, you handle that exactly the same way as creating a room: just pass the Room name to the `connect` method. Once in a Room, you'll receive a `RoomParticipantConnectedEvent` for each Participant that successfully joins. Querying the `room.remoteParticipants` getter will return any existing Participants who have already joined the Room.

```dart
Room _room;
final Completer<Room> _completer = Completer<Room>();

void _onConnected(Room room) {
  print('Connected to ${room.name}');
  _completer.complete(_room);
}

void _onConnectFailure(RoomConnectFailureEvent event) {
  print('Failed to connect to room ${event.room.name} with exception: ${event.exception}');
  _completer.completeError(event.exception);
}
  
Future<Room> connectToRoom() async {
  var connectOptions = ConnectOptions(
    accessToken,
    roomName: roomName,
    region: region,                       // Optional region.
    preferAudioCodecs: [OpusCodec()],     // Optional list of preferred AudioCodecs
    preferVideoCodecs: [H264Codec()],     // Optional list of preferred VideoCodecs.
    audioTracks: [LocalAudioTrack(true)], // Optional list of audio tracks.
    dataTracks: [
      LocalDataTrack(
        DataTrackOptions(
          ordered: ordered,                      // Optional, Ordered transmission of messages. Default is `true`.
          maxPacketLifeTime: maxPacketLifeTime,  // Optional, Maximum retransmit time in milliseconds. Default is [DataTrackOptions.defaultMaxPacketLifeTime]
          maxRetransmits: maxRetransmits,        // Optional, Maximum number of retransmitted messages. Default is [DataTrackOptions.defaultMaxRetransmits]
          name: name                             // Optional
        ),                                // Optional
      ),
    ],                                    // Optional list of data tracks
    videoTracks([LocalVideoTrack(true, CameraCapturer(CameraSource.FRONT_CAMERA))]), // Optional list of video tracks. 
    enableNetworkQuality: true,           // Optional enable or disable the Network Quality API. Default is `false`
    // The following is optional if you only want to monitor the LocalParticipant, but required if you
    // want to monitor the Network Quality of RemoteParticipants
    // It sets the verbosity level for network quality information returned by the Network Quality API
    networkQualityConfiguration: NetworkQualityConfiguration(
      remote: NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_MINIMAL,
    ),
  );
  _room = await TwilioProgrammableVideo.connect(connectOptions);
  _room.onConnected.listen(_onConnected);
  _room.onConnectFailure.listen(_onConnectFailure);
  return _completer.future;
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
// This can only be called after the TwilioProgrammableVideo.connect() is called.
var widget = localVideoTrack.widget();
```

### Connect as a publish-only Participant
It is currently not possible to connect as a publish-only participant.

### Working with Remote Participants

#### Handle Connected Participants
When you join a Room, Participants may already be present. You can check for existing Participants when the `Room.onConnected` listener gets called by using the `room.remoteParticipants` getter.

```dart
// Connect to a room.
var room = await TwilioProgrammableVideo.connect(connectOptions);

room.onConnected((Room room) {
  print('Connected to ${room.name}');
});

room.onConnectFailure((RoomConnectFailureEvent event) {
    print('Failed connecting, exception: ${event.exception.message}');
});

room.onDisconnected((RoomDisconnectEvent event) {
  print('Disconnected from ${event.room.name}');
});

room.onRecordingStarted((Room room) {
  print('Recording started in ${room.name}');
});

room.onRecordingStopped((Room room) {
  print('Recording stopped in ${room.name}');
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
var room = await TwilioProgrammableVideo.connect(connectOptions);

room.onParticipantConnected((RoomParticipantConnectedEvent event) {
  print('Participant ${event.remoteParticipant.identity} has joined the room');
});

room.onParticipantDisconnected((RoomParticipantDisconnectedEvent event) {
  print('Participant ${event.remoteParticipant.identity} has left the room');
});
```

#### Display a Remote Participant's Widget
To see the Video Tracks being sent by remote Participants, we need to add their widgets to the tree.

```dart
room.onParticipantConnected((RoomParticipantConnectedEvent roomEvent) {
  // We can respond when the Participant adds a VideoTrack by adding the widget to the tree.
  roomEvent.remoteParticipant.onVideoTrackSubscribed((RemoteVideoTrackSubscriptionEvent event) {
    var mirror = false;
    _widgets.add(event.remoteParticipant.widget(mirror));
  });
});
```

### Using the DataTrack API
The DataTrack API lets you create a DataTrack channel which can be used to send low latency messages to zero or more receivers subscribed to the data.

Currently the only way you can start using a DataTrack is by specifying it in the ConnectOptions when [connecting to a room](https://gitlab.com/twilio-flutter/programmable-video/blob/master/README.md#connect-to-a-room)

After you have connected to the Room, you have to wait until you receive the `LocalDataTrackPublishedEvent` before you can start sending data to the track. You can start listening for this event once you have connected to the room using the `Room.onConnected` listener:

```dart
// Connect to a room.
var room = await TwilioProgrammableVideo.connect(connectOptions);

room.onConnected((Room room) {
  // Once connected to the room start listening for the moment the LocalDataTrack gets published to the room.
  room.localParticipant.onDataTrackPublished.listen(_onLocalDataTrackPublished);
});

  // Once connected to the room start listening for the moment the LocalDataTrack gets published to the room.
  event.room.localParticipant.onDataTrackPublished.listen(_onLocalDataTrackPublished);
});

void _onLocalDataTrackPublished(LocalDataTrackPublishedEvent event) {
  // This event contains a localDataTrack you can use to send data.
  event.localDataTrackPublication.localDataTrack.send('Hello world');
}
```

If you want to receive data from a RemoteDataTrack you have to start listening to the track once the RemoteParticipant has started publishing it and you are subscribed to it:

```dart
// Connect to a room.
var room = await TwilioProgrammableVideo.connect(connectOptions);

room.onParticipantConnected((RoomParticipantConnectedEvent event) {
  // A participant connected, now you can start listening to RemoteParticipant events
  event.remoteParticipant.onDataTrackSubscribed.listen(_onDataTrackSubscribed)
});

void _onDataTrackSubscribed(RemoteDataTrackSubscriptionEvent event) {
  final dataTrack = event.remoteDataTrackPublication.remoteDataTrack;
  dataTrack.onMessage.listen(_onMessage);
}

void _onMessage(RemoteDataTrackStringMessageEvent event) {
  print('onMessage => ${event.remoteDataTrack.sid}, ${event.message}');
}
```

Remember, you will not receive messages that were send before you started listening.

### Participating in a Room

#### Display a Camera Preview
Just like Twilio we totally get that you want to look fantastic before entering a Room. Sadly that isn't yet implemented so you should go analog and use a mirror.

#### Disconnect from a Room
You can disconnect from a Room you're currently participating in. Other Participants will receive a `RoomParticipantDisconnectedEvent`.

```dart
// To disconnect from a Room, we call:
await room.disconnect();

// This results in a call to Room#onDisconnected
room.onDisconnected((RoomDisconnectEvent event) {
  print('Disconnected from ${event.room.name}');
});

```

### Room reconnection
A Room reconnection is triggered due to a signaling or media reconnection event.

```dart
/// Exception will be either TwilioException.signalingConnectionDisconnectedException or TwilioException.mediaConnectionErrorException
room.onReconnecting((RoomReconnectingEvent event) {
  print('Reconnecting to room ${event.room.name}, exception = ${event.exception.message}');
});

room.onReconnected((Room room) {
  print('Reconnected to room ${room.name}');
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
Using the `TwilioProgrammableVideo` class, you can specify if audio is routed through the headset or speaker.

**Note:**
> Calling this method before being connected to a room on iOS will result in nothing. If you wish to route audio through the headset or speaker call this method in the `onConnected` event.

```dart
// Route audio through speaker
TwilioProgrammableVideo.setSpeakerphoneOn(true);

// Route audio through headset
TwilioProgrammableVideo.setSpeakerphoneOn(false);
```

## Enable debug logging
Using the `TwilioProgrammableVideo` class, you can enable native and dart logging of the plugin.

```dart
var nativeEnabled = true;
var dartEnabled = true;
TwilioProgrammableVideo.debug(native: nativeEnabled, dart: dartEnabled);
```

## Access Tokens
Keep in mind, you can't generate access tokens for programmable-video using the [TestCredentials](https://www.twilio.com/docs/iam/test-credentials#supported-resources), make use of the LIVE credentials.

You can easily generate an access token in the Twilio dashboard with the [Testing Tools](https://www.twilio.com/console/video/project/testing-tools) to start testing your code. But we recommend you setup a backend to generate these tokens for you and secure your Twilio credentials. Like we do in our [example app](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/example).

## Events table
Reference table of all the events the plugin currently supports

| Type              | Event streams                  | Event data                                | Implemented  |
| :---------------- | :----------------------------- | :---------------------------------------- | ------------ |
| LocalParticipant  | onAudioTrackPublished          | LocalAudioTrackPublishedEvent             | Android Only |
| LocalParticipant  | onAudioTrackPublicationFailed  | LocalAudioTrackPublicationFailedEvent     | Android Only |
| LocalParticipant  | onDataTrackPublished           | LocalDataTrackPublishedEvent              | Android Only |
| LocalParticipant  | onDataTrackPublicationFailed   | LocalDataTrackPublicationFailedEvent      | Android Only |
| LocalParticipant  | onNetworkQualityLevelChanged   | LocalNetworkQualityLevelChangedEvent      | Android Only |
| LocalParticipant  | onVideoTrackPublished          | LocalVideoTrackPublishedEvent             | Android Only |
| LocalParticipant  | onVideoTrackPublicationFailed  | LocalVideoTrackPublicationFailedEvent     | Android Only |
| RemoteDataTrack   | onStringMessage                | RemoteDataTrackStringMessageEvent         | Android Only |
| RemoteDataTrack   | onBufferMessage                | RemoteDataTrackBufferMessageEvent         | Android Only |
| RemoteParticipant | onAudioTrackDisabled           | RemoteAudioTrackEvent                     | Yes          |
| RemoteParticipant | onAudioTrackEnabled            | RemoteAudioTrackEvent                     | Yes          |
| RemoteParticipant | onAudioTrackPublished          | RemoteAudioTrackEvent                     | Yes          |
| RemoteParticipant | onAudioTrackSubscribed         | RemoteAudioTrackSubscriptionEvent         | Yes          |
| RemoteParticipant | onAudioTrackSubscriptionFailed | RemoteAudioTrackSubscriptionFailedEvent   | Yes          |
| RemoteParticipant | onAudioTrackUnpublished        | RemoteAudioTrackEvent                     | Yes          |
| RemoteParticipant | onAudioTrackUnsubscribed       | RemoteAudioTrackSubscriptionEvent         | Yes          |
| RemoteParticipant | onDataTrackPublished           | RemoteDataTrackEvent                      | Yes          |
| RemoteParticipant | onDataTrackSubscribed          | RemoteDataTrackSubscriptionEvent          | Yes          |
| RemoteParticipant | onDataTrackSubscriptionFailed  | RemoteDataTrackSubscriptionFailedEvent    | Yes          |
| RemoteParticipant | onDataTrackUnpublished         | RemoteDataTrackEvent                      | Yes          |
| RemoteParticipant | onDataTrackUnsubscribed        | RemoteDataTrackSubscriptionEvent          | Yes          |
| RemoteParticipant | onNetworkQualityLevelChanged   | RemoteNetworkQualityLevelChangedEvent     | Android Only |
| RemoteParticipant | onVideoTrackDisabled           | RemoteVideoTrackEvent                     | Yes          |
| RemoteParticipant | onVideoTrackEnabled            | RemoteVideoTrackEvent                     | Yes          |
| RemoteParticipant | onVideoTrackPublished          | RemoteVideoTrackEvent                     | Yes          |
| RemoteParticipant | onVideoTrackSubscribed         | RemoteVideoTrackSubscriptionEvent         | Yes          |
| RemoteParticipant | onVideoTrackSubscriptionFailed | RemoteVideoTrackSubscriptionFailedEvent   | Yes          |
| RemoteParticipant | onVideoTrackUnpublished        | RemoteVideoTrackEvent                     | Yes          |
| RemoteParticipant | onVideoTrackUnsubscribed       | RemoteVideoTrackSubscriptionEvent         | Yes          |
| Room              | onConnectFailure               | RoomConnectFailureEvent                   | Yes          |
| Room              | onConnected                    | Room                                      | Yes          |
| Room              | onDisconnected                 | RoomDisconnectedEvent                     | Yes          |
| Room              | onParticipantConnected         | RoomParticipantConnectedEvent             | Yes          |
| Room              | onParticipantDisconnected      | RoomParticipantDisconnectedEvent          | Yes          |
| Room              | onReconnected                  | Room                                      | Yes          |
| Room              | onReconnecting                 | RoomReconnectingEvent                     | Yes          |
| Room              | onRecordingStarted             | Room                                      | Yes          |
| Room              | onRecordingStopped             | Room                                      | Yes          |


# Development and Contributing
Interested in contributing? We love merge requests! See the [Contribution](https://gitlab.com/twilio-flutter/programmable-video/blob/master/CONTRIBUTING.md) guidelines.
