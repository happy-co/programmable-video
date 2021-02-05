# twilio_programmable_video
Flutter plugin for [Twilio Programmable Video](https://www.twilio.com/video?utm_source=opensource&utm_campaign=flutter-plugin), which enables you to build real-time videocall applications (WebRTC) \
This Flutter plugin is a community-maintained project for [Twilio Programmable Video](https://www.twilio.com/video?utm_source=opensource&utm_campaign=flutter-plugin) and not maintained by Twilio. If you have any issues, please file an issue instead of contacting support.

This package is currently work-in-progress and should not be used for production apps. We can't guarantee that the current API implementation will stay the same between versions, until we have reached v1.0.0.

# Example
Check out our comprehensive [example](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video/example) provided with this plugin.

[![Twilio Programmable Video Example](https://j.gifs.com/5QEyOB.gif)](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video/example "Twilio Programmable Video Example")

## Join the community
If you have any question or problems, please join us on [Discord](https://discord.gg/MWnu4nW)

## FAQ
Read the [Frequently Asked Questions](https://gitlab.com/twilio-flutter/programmable-video/-/blob/master/programmable_video/FAQ.md) first before creating a new issue.

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
Add the following lines to your `android/app/proguard-rules.pro` file.

```
-keep class tvi.webrtc.** { *; }
-keep class com.twilio.video.** { *; }
-keep class com.twilio.common.** { *; }
-keepattributes InnerClasses
```

Also do not forget to reference this `proguard-rules.pro` in your
`android/app/build.gradle` file.

```
android {

    ...

    buildTypes {

        release {

            ...    

            minifyEnabled true
            useProguard true

            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'

        }
    }
}
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
    roomName: roomName,                   // Optional name for the room
    region: region,                       // Optional region.
    preferredAudioCodecs: [OpusCodec()],  // Optional list of preferred AudioCodecs
    preferredVideoCodecs: [H264Codec()],  // Optional list of preferred VideoCodecs.
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
    videoTracks: ([LocalVideoTrack(true, CameraCapturer(CameraSource.FRONT_CAMERA))]), // Optional list of video tracks.
  );
  _room = await TwilioProgrammableVideo.connect(connectOptions);
  _room.onConnected.listen(_onConnected);
  _room.onConnectFailure.listen(_onConnectFailure);
  return _completer.future;
}
```

You **must** pass the [Access Token](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video/README.md#access-tokens) when connecting to a Room.

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

Currently the only way you can start using a DataTrack is by specifying it in the ConnectOptions when [connecting to a room](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video/README.md#connect-to-a-room)

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

### Playing audio files to provide a rich user experience

For the purposes of playing audio files while using this plugin, we recommend the [`ocarina`](https://pub.dev/packages/ocarina) plugin (v0.0.5 and upwards).

This recommendation comes after surveying the available plugins for this functionality in the Flutter ecosystem for plugins that play nice with this one.

The primary problem observed with other plugins that provide this functionality is that on iOS the majority of them modify the `AVAudioSession` mode, putting it into a playback only mode, and as a result preventing the video call from recording audio.

The secondary problem with audio file playback in iOS is that [the operating system gives priority to the `VoiceProcessingIO` Audio Unit](https://developer.apple.com/forums/thread/22133), causing other audio sources to be played at a greatly diminished volume when this AudioUnit is in use. To address this issue, we provide the custom `AVAudioEngineDevice` which users of the plugin may enable with the example that follows. `AVAudioEngineDevice` was designed with `ocarina` in mind, providing an interface for delegating audio file playback and management from that plugin to the `AVAudioEngineDevice`. It was adapted from [Twilio's example](https://github.com/twilio/video-quickstart-ios/commit/9fffebbef4f2d3cb2a5cf78bcb76949939c810f8).

To enable usage of the `AVAudioEngineDevice`, and delegate audio file playback management from ocarina to it, update your `AppDelegate.swift`s `didFinishLaunch` method as follows:

```swift
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let audioDevice = AVAudioEngineDevice()
    SwiftTwilioProgrammableVideoPlugin.audioDevice = audioDevice
    SwiftOcarinaPlugin.useDelegate(
        load: audioDevice.addMusicNode,
        dispose: audioDevice.disposeMusicNode,
        play: audioDevice.playMusic,
        pause: audioDevice.pauseMusic,
        resume: audioDevice.resumeMusic,
        stop: audioDevice.stopMusic,
        volume: audioDevice.setMusicVolume,
        seek: audioDevice.seekPosition,
        position: audioDevice.getPosition
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
```

Once you have done this, you should be able to continue using this plugin, and `ocarina` as normal.

## Enable debug logging
Using the `TwilioProgrammableVideo` class, you can enable native and dart logging of the plugin.

```dart
var nativeEnabled = true;
var dartEnabled = true;
TwilioProgrammableVideo.debug(native: nativeEnabled, dart: dartEnabled);
```

## Access Tokens
Keep in mind, you can't generate access tokens for programmable-video using the [TestCredentials](https://www.twilio.com/docs/iam/test-credentials#supported-resources), make use of the LIVE credentials.

You can easily generate an access token in the Twilio dashboard with the [Testing Tools](https://www.twilio.com/console/video/project/testing-tools) to start testing your code. But we recommend you setup a backend to generate these tokens for you and secure your Twilio credentials. Like we do in our [example app](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video/example).

## Events table
Reference table of all the events the plugin currently supports

| Type              | Event streams                  | Event data                                | Implemented  |
| :---------------- | :----------------------------- | :---------------------------------------- | ------------ |
| LocalParticipant  | onAudioTrackPublished          | LocalAudioTrackPublishedEvent             | Android Only |
| LocalParticipant  | onAudioTrackPublicationFailed  | LocalAudioTrackPublicationFailedEvent     | Android Only |
| LocalParticipant  | onDataTrackPublished           | LocalDataTrackPublishedEvent              | Android Only |
| LocalParticipant  | onDataTrackPublicationFailed   | LocalDataTrackPublicationFailedEvent      | Android Only |
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
Interested in contributing? We love merge requests! See the [Contribution](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video/CONTRIBUTING.md) guidelines.

# Contributions By

[![HomeX - Home Repairs Made Easy](https://homex.com/static/brand/homex-logo-green.svg)](https://homex.com)
