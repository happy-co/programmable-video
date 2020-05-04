# Contributing Guidelines
If you're interested in contributing to this project, here are a few ways to do so:

### Bug fixes
* If you find a bug, please first report it using [Gitlab issues](https://gitlab.com/twilio-flutter/programmable-video/issues/new).
* Issues that have already been identified as a bug will be labelled ~"type::bug" .
* If you'd like to submit a fix for a bug, send a [Merge Request](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#merging-upstream) from your own fork, also read the [How To](#how-to) and [Development Guidelines](#development-guidelines).
* Include a test that isolates the bug and verifies that it was fixed.
* Also update the example and documentation if necessary.

### New Features
* If you'd like to add a feature to the library that doesn't already exist, feel free to describe the feature in a new [Gitlab issue](https://gitlab.com/twilio-flutter/programmable-video/issues/new).
* Issues that have been identified as a feature request will be labelled ~"type::feature".
* If you'd like to implement the new feature, please wait for feedback from the project maintainers before spending too much time writing the code. In some cases, enhancements may not align well with the project objectives at the time.
* Implement your code and please read the [How To](#how-to) and [Development Guidelines](#development-guidelines).
* Also update the example and documentation where needed.

### Documentation & Miscellaneous
* If you think the documentation could be clearer, or you have an alternative implementation of something that may have more advantages, we would love to hear it.
* As always first file a report in a [Gitlab issue](https://gitlab.com/twilio-flutter/programmable-video/issues/new).
* Issues that have been identified as a documentation change will be labelled ~"type::documentation".
* Implement the changes to the documentation, please read the [How To](#how-to) and [Development Guidelines](#development-guidelines).

# Requirements
For a contribution to be accepted:

* Take note of the [Development Guidelines](#development-guidelines)
* Code must follow existing styling conventions
* Commit message should start with a [issue number](#how-to) and should also be descriptive.

If the contribution doesn't meet these criteria, a maintainer will discuss it with you on the issue. You can still continue to add more commits to the branch you have sent the Merge Request from.

# How To
* First of all [file an bug or feature report](https://gitlab.com/twilio-flutter/programmable-video/issues/new) on this repository.
* [Fork the project](https://docs.gitlab.com/ee/gitlab-basics/fork-project.html) on Gitlab
* Clone the forked repository to your local development machine (e.g. `git clone https://gitlab.com/<YOUR_GITLAB_USER>/programmable-video.git`)
* Run `flutter pub get` in the cloned repository to get all the dependencies
* Create a new local branch based on issue number from first step (e.g. `git checkout -b 12-new-feature`)
* Make your changes
* When committing your changes, make sure to start the commit message with `#<issue-number>` (e.g. `git commit -m '#12 - New Feature added'`)
* Push your new branch to your own fork into the same remote branch (e.g. `git push origin 12-new-feature`)
* On Gitlab goto the [merge request page](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#merging-upstream) on your own fork and create a merge request to this reposistory

# Development Guidelines
* Backend code for the example app should be written for Cloud Functions, see the `example/firebase` folder.
* Documentation should be updated.
* Example application should be updated.
* Format the Flutter code accordingly.
* Note the [`analysis_options.yaml`](https://gitlab.com/twilio-flutter/programmable-video/-/blob/master/analysis_options.yaml) and write code as stated in this file

# Test generating of `dartdoc`
* On local development make sure the `dartdoc` program is mentioned in your `$PATH`
* `dartdoc` can be found here: `<FLUTTER_INSTALL_DIR>/bin/cache/dart-sdk/bin/dartdoc`
* Generate docs with the following command: `dartdoc --no-auto-include-dependencies --quiet`
* Output will be placed into `doc/api/`

# Communicating between Dart and Native

The communication between Native code and Dart goes via EventChannels. Below you will find a table with all the currently identified events we want to implement and their implementation status.

[Check this link](https://flutter.dev/docs/development/platform-integration/platform-channels?tab=ios-channel-swift-tab#codec) for more information on platform channel data types support and codecs.

### Events table
Reference table of all the events the plugin targets to support and their native platform counter part.

| Type              | Dart Event name              | Android                        | iOS                                     | Implemented  |
| :---------------- | ---------------------------- | ------------------------------ | --------------------------------------- | ------------ |
| LocalParticipant  | audioTrackPublished          | onAudioTrackPublished          | didPublishAudioTrack                    | Android Only |
| LocalParticipant  | audioTrackPublicationFailed  | onAudioTrackPublicationFailed  | didFailToPublishAudioTrack              | Android Only |
| LocalParticipant  | dataTrackPublished           | onDataTrackPublished           | didPublishDataTrack                     | Android Only |
| LocalParticipant  | dataTrackPublicationFailed   | onDataTrackPublicationFailed   | didFailToPublishDataTrack               | Android Only |
| LocalParticipant  | networkQualityLevelChanged   | onNetworkQualityLevelChanged   | networkQualityLevelDidChange            | No           |
| LocalParticipant  | videoTrackPublished          | onVideoTrackPublished          | didPublishVideoTrack                    | Android Only |
| LocalParticipant  | videoTrackPublicationFailed  | onVideoTrackPublicationFailed  | didFailToPublishVideoTrack              | Android Only |
| RemoteDataTrack   | stringMessage                | onMessage                      | didReceiveString                        | Android Only |
| RemoteDataTrack   | bufferMessage                | onMessage                      | didReceiveData                          | Android Only |
| RemoteParticipant | audioTrackDisabled           | onAudioTrackDisabled           | remoteParticipantDidDisableAudioTrack   | Yes          |
| RemoteParticipant | audioTrackEnabled            | onAudioTrackEnabled            | remoteParticipantDidEnableAudioTrack    | Yes          |
| RemoteParticipant | audioTrackPublished          | onAudioTrackPublished          | remoteParticipantDidPublishAudioTrack   | Yes          |
| RemoteParticipant | audioTrackSubscribed         | onAudioTrackSubscribed         | didSubscribeToAudioTrack                | Yes          |
| RemoteParticipant | audioTrackSubscriptionFailed | onAudioTrackSubscriptionFailed | didFailToSubscribeToAudioTrack          | Yes          |
| RemoteParticipant | audioTrackUnpublished        | onAudioTrackUnpublished        | remoteParticipantDidUnpublishAudioTrack | Yes          |
| RemoteParticipant | audioTrackUnsubscribed       | onAudioTrackUnsubscribed       | didUnsubscribeFromAudioTrack            | Yes          |
| RemoteParticipant | dataTrackPublished           | onDataTrackPublished           | remoteParticipantDidPublishDataTrack    | Android Only |
| RemoteParticipant | dataTrackSubscribed          | onDataTrackSubscribed          | didSubscribeToDataTrack                 | Android Only |
| RemoteParticipant | dataTrackSubscriptionFailed  | onDataTrackSubscriptionFailed  | didFailToSubscribeToDataTrack           | Android Only |
| RemoteParticipant | dataTrackUnpublished         | onDataTrackUnpublished         | remoteParticipantDidUnpublishDataTrack  | Android Only |
| RemoteParticipant | dataTrackUnsubscribed        | onDataTrackUnsubscribed        | didUnsubscribeFromDataTrack             | Android Only |
| RemoteParticipant | videoTrackDisabled           | onVideoTrackDisabled           | remoteParticipantDidDisableVideoTrack   | Yes          |
| RemoteParticipant | videoTrackEnabled            | onVideoTrackEnabled            | remoteParticipantDidEnableVideoTrack    | Yes          |
| RemoteParticipant | videoTrackPublished          | onVideoTrackPublished          | remoteParticipantDidPublishVideoTrack   | Yes          |
| RemoteParticipant | vdeoTrackSubscribed          | onVideoTrackSubscribed         | didSubscribeToVideoTrack                | Yes          |
| RemoteParticipant | videoTrackSubscriptionFailed | onVideoTrackSubscriptionFailed | didFailToSubscribeToVideoTrack          | Yes          |
| RemoteParticipant | videoTrackUnpublished        | onVideoTrackUnpublished        | remoteParticipantDidUnpublishVideoTrack | Yes          |
| RemoteParticipant | videoTrackUnsubscribed       | onVideoTrackUnsubscribed       | didUnsubscribeFromVideoTrack            | Yes          |
| Room              | connectFailure               | onConnectFailure               | roomDidFailToConnect                    | Yes          |
| Room              | connected                    | onConnected                    | roomDidConnect                          | Yes          |
| Room              | disconnected                 | onDisconnected                 | roomDidDisconnect                       | Yes          |
| Room              | participantConnected         | onParticipantConnected         | participantDidConnect                   | Yes          |
| Room              | participantDisconnected      | onParticipantDisconnected      | participantDidDisconnect                | Yes          |
| Room              | reconnected                  | onReconnected                  | roomDidReconnect                        | Yes          |
| Room              | reconnecting                 | onReconnecting                 | roomIsReconnecting                      | Yes          |
| Room              | recordingStarted             | onRecordingStarted             | roomDidStartRecording                   | Yes          |
| Room              | recordingStopped             | onRecordingStopped             | roomDidStopRecording                    | Yes          |
| Room              | dominantSpeakerChanged       | onDominantSpeakerChanged       | dominantSpeakerDidChange                | Yes          |

