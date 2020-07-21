# FAQ

This file contains Frequently Asked Questions and their answers. Please feel free to make PRs to amend this file with new questions.

## I am experiencing an echo through the audio of a `RemoteParticipant`. What can I do about it?
The Twilio library performs acoustic echo cancellation (AEC) using the device hardware by default. But some devices do not implement these audio effects well.

If you are experiencing echo on certain devices please create a ~"type::bug" issue and report your build model with it. After creating an issue, you may also provide a MR for it to get it merged sooner.

You can add the following right before your `TwilioProgrammableVideo.connect` call to see in your logging which build model your device has:
```dart
TwilioProgrammableVideo.debug(dart: true, native: true);
```

In the `flutter run` log you can search/filter on `Build.MODEL` to get the model.

## I do not want to use Firebase Cloud Functions is there an example without it?
Unfortunately not. We have chosen to use Firebase Cloud Functions for the following reasons:
1. We wanted to prove for ourselves it can be done with Cloud Functions
2. We definitely wanted to have [Status Callbacks](https://www.twilio.com/docs/video/api/status-callbacks) and with Cloud Functions the functions are reachable over the internet.

But of course you are free to remove Firebase Cloud Functions and setup an own backend. You should focus on the next things:
1. Rewrite the [Firebase backend](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video/example/firebase) to your own backend.
2. Rewrite the [`backend_service.dart`](https://gitlab.com/twilio-flutter/programmable-video/-/blob/master/programmable_video/example/lib/shared/services/backend_service.dart) to call your backend

## I receive an `NOT_FOUND` error when calling the Firebase Cloud Function, what's going on?
There can be several reasons that could throw this exception, mostly misconfiguration. So let's check a few things:
1. Are your functions deployed? Which can be found here: `https://console.firebase.google.com/project/<FIREBASE PROJECT ID>/functions/list`. If the functions are not deployed, please deploy them!
2. If they are deployed, you can see on which URL it is deployed, it will be something like: `https://europe-west1-<FIREBASE PROJECT ID>.cloudfunctions.net/createRoom`. Keep an eye on the Firebase region here. In this URL our region is set to `europe-west1`. If yours is different you need to change some files in the example.
3. Set the correct region in the [`backend_service.dart`](https://gitlab.com/twilio-flutter/programmable-video/-/blob/master/programmable_video/example/lib/shared/services/backend_service.dart#L26)
4. To able to receive [Status Callbacks](https://www.twilio.com/docs/video/api/status-callbacks) events you also need to reconfigure the Firebase Cloud Functions with the correct region:
   - Configure the region where functions will be deployed [here](https://gitlab.com/twilio-flutter/programmable-video/-/blob/master/programmable_video/example/firebase/functions/src/index.ts#L19).
   - Configure status callbacks [here](https://gitlab.com/twilio-flutter/programmable-video/-/blob/master/programmable_video/example/firebase/functions/src/rooms/createRoom.ts#L29).

## Is it possible to only one broadcast and several others subscribe to it? Something like Facebook Live or any other broadcasting features?
Yes this is possible, but not included into any example. But for an heads-up you need to focus on implementing the next things:
1. Make sure to set [`enableAutomaticSubscription`](https://pub.dev/documentation/twilio_programmable_video/latest/twilio_programmable_video/ConnectOptions/enableAutomaticSubscription.html) to `false`
2. Make sure when you create a room, you will listen to [Status Callbacks](https://www.twilio.com/docs/video/api/status-callbacks) on your backend. Like we did in the [Firebase Cloud Functions](https://gitlab.com/twilio-flutter/programmable-video/-/blob/master/programmable_video/example/firebase/functions/src/rooms/createRoom.ts#L27) when creating a room.
3. Make sure [your backend](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video/example/firebase/functions/src/web-hooks) listens to these events.
4. In your backend you should filter on the [`participant-connected`](https://www.twilio.com/docs/video/api/status-callbacks#rooms-callback-events) event. In our example it will be received [here](https://gitlab.com/twilio-flutter/programmable-video/-/blob/master/programmable_video/example/firebase/functions/src/web-hooks/twilio/programmable-video/rooms/index.ts#L6). Content would be something like:
```json
{
    "RoomStatus":"in-progress",
    "RoomType":"group-small",
    "RoomSid":"RMxxxxxx",
    "RoomName":"m",
    "ParticipantStatus":"connected",
    "ParticipantIdentity":"yyyy",
    "SequenceNumber":"1",
    "StatusCallbackEvent":"participant-connected",
    "Timestamp":"2020-05-08T04:35:04.373Z",
    "ParticipantSid":"PAXXXX",
    "AccountSid":"ACXXX"
}

```
5. When you receive and catch the `participant-connected` event you need to implement your magic and logic following the [Track Subscriptions](https://www.twilio.com/docs/video/api/track-subscriptions) documentation.

## I need to develop a high quality video calling/broadcasting application, is it possible?
Yes it is, we recommend you start reading from [this point](https://www.twilio.com/docs/video/tutorials/developing-high-quality-video-applications).

## When I build for release mode the app crashes after joining a room, what should I do?
Follow the guidelines for adding the [`proguard-rules.pro`](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video#proguard) file.

## Other questions?
Didn't find what you need? Please head over to our [Discord](https://discord.gg/42x46NH) where the community might be able to answer your questions.