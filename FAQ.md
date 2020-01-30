# FAQ

This file contains Frequently Asked Questions and their answers. Please feel free to make PRs to amend this file with new questions.

## I am experiencing an echo through the audio of a `RemoteParticipant`. What can I do about it?
The Twilio library performs acoustic echo cancellation (AEC) using the device hardware by default. But some devices do not implement these audio effects well.

If you are experiencing echo on certain devices please create a ~"type::bug" issue and report your build model with it. After creating an issue, you may also provide a MR for it to get it merged sooner.

You can add the following right before your `TwilioUnofficialProgrammableVideo.connect` call to see in your logging which build model your device has:
```dart
TwilioUnofficialProgrammableVideo.debug(dart: true, native: true);
```

In the `flutter run` log you can search/filter on `Build.MODEL` to get the model.

## Other questions?
Didn't find what you need? Please head over to our [Discord](https://discord.gg/42x46NH) where the community might be able to answer your questions.