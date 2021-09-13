# twilio_programmable_video_example

Demonstrates how to use the `twilio_programmable_video` plugin in a save manner as you would production like.

![Twilio Programmable Video Example](https://j.gifs.com/5QEyOB.gif)

## Join the community

If you have any question or problems, please join us on [Discord](https://discord.gg/42x46NH)

## Supported platforms

- Android
- iOS
- Web

## Prerequisites

This example makes use of a backend, to setup a backend and make it reachable on the internet we decided
to use Firebase in this project. Therefore you need to do some setup steps to get this example up and
running. Also we are going to be using Twilio Programmable Video, which also needs some setup before
getting started.

1. [Create a Twilio account](https://www.twilio.com/referral/j7GFTv)
2. [Create a Firebase account](https://firebase.google.com/)

## Required plans on Twilio

Please note the following about costs and required plans on these accounts. On Twilio you will get $15
on your Trial account. This should be enough to start testing Programmable Video.

## Required plans on Firebase

On Firebase you will kick off in the [Spark plan](https://firebase.google.com/pricing). But you will need
to upgrade to the Blaze plan. Don't be scared for any costs, because:

> The Spark plan allows outbound network requests only to Google-owned services. Inbound invocation requests are
> allowed within the quota. On the Blaze plan, Cloud Functions provides a perpetual free tier. The first 2,000,000
> invocations, 400,000 GB-sec, 200,000 CPU-sec, and 5 GB of Internet egress traffic is provided for free each month.
> You are only charged on usage past this free allotment. Pricing is based on total number of invocations, and
> compute time. Compute time is variable based on the amount of memory and CPU provisioned for a function. Usage
> limits are also enforced through daily and 100s quotas. For more information, see [Cloud Functions Pricing](https://cloud.google.com/functions/pricing).

## Getting started

Now that we are aware of the specific needed plans as stated above we can get this party started.

### Install NodeJS & Firebase command-line tools

We are going to use Firebase command-line tools to easily deploy functions. Therefore we need to install NodeJS.

To install NodeJS, follow the installation documentation for your OS from [https://nodejs.org/](https://nodejs.org/).

After successful installation of NodeJS you can install Firebase command-line tools globally like this:

```bash
npm install -g firebase-tools
```

### Setting up Firebase

1. Create a project on Firebase. Any project name would be okay. Google Analytics is not needed, but if you want you can add it.
2. Below the project name you will see the project id that will be created. You can change this when you press on it. Write this
   project id down.
3. Go to your project settings and select your resource location in the `Google Cloud Platform (GCP) resource location`. Keep in mind, you can't change this afterwards.
4. Open the file `.firebaserc` and change the value `twilio-flutter-plugin-dev` to your project id from step 2.
5. Make sure the project is on [Blaze plan](#required-plans-on-firebase)
6. In a terminal run `firebase login` and login with the same account as used in step 1.
7. In a terminal go to the firebase functions directory in this example: `cd firebase/functions` and run `npm install`
8. You will need to get the following information from your Twilio account for the next step:

| Variable                | Example value                      | Where to find/create                                                                            |
| ----------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------------- |
| twilio.live.account_sid | ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX | [Twilio console - Dashboard](https://www.twilio.com/console)                                    |
| twilio.live.auth_token  | your_auth_token                    | [Twilio console - Dashboard](https://www.twilio.com/console)                                    |
| twilio.test.account_sid | ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX | [Twilio console - Dashboard](https://www.twilio.com/console)                                    |
| twilio.test.auth_token  | your_auth_token                    | [Twilio console - Dashboard](https://www.twilio.com/console)                                    |
| twilio.api_key          | SKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX | [Twilio Console - Settings -> API Keys](https://www.twilio.com/console/project/api-keys/create) |
| twilio.api_secret       | your_api_secret                    | [Twilio Console - Settings -> API Keys](https://www.twilio.com/console/project/api-keys/create) |

9. Configure [the environment variables](https://firebase.google.com/docs/functions/config-env) for the Cloud Functions

```
firebase functions:config:set twilio.live.account_sid="ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" \
                              twilio.live.auth_token="your_auth_token" \
                              twilio.test.account_sid="ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" \
                              twilio.test.auth_token="your_auth_token" \
                              twilio.api_key="SKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" \
                              twilio.api_secret="your_api_secret"
```

10. Deploy the firebase project: `firebase deploy`

### Configure Flutter app

This example uses the `cloud_functions` plugin from [pub.dev](https://pub.dev/packages/cloud_functions) and therefore we should also follow [the setup](https://pub.dev/packages/cloud_functions#setup) from this plugin.

Below we will take you through this setup for each platform.

#### Configure Android

1. Open your [firebase console](https://console.firebase.google.com/)
2. Open the project you created before
3. On this project overview page click the Android icon to add an Android app or if you do not see this option, click the `Add app` button
4. Android package name: `twilio.flutter.programmable_video_example`
5. App nickname: `Twilio Programmable Video Example`
6. Debug signing certificate SHA-1: leave empty
7. Click `Register app`
8. Click `Download google-services.json`
9. Move the downloaded `google-services.json` file to this folder `android/app/` and make sure to keep the filename exactly the same!
10. In the firebase console hit the `Next` button
11. Add Firebase SDK, these steps are already done in this example, so just hit `Next`
12. Finally hit `Continue to the console`

#### Configure iOS

1. Open your [firebase console](https://console.firebase.google.com/)
2. Open the project you created before
3. On this project overview page click the iOS icon to add an iOS app or if you do not see this option, click the `Add app` button
4. iOS bundle ID: `twilio.flutter.ProgrammableVideoExample`
5. App nickname: `Twilio Programmable Video Example`
6. App Store ID: leave empty
7. Click `Register app`
8. Click `Download GoogleService-Info.plist`
9. Move the downloaded `GoogleService-Info.plist` file to this folder `ios/Runner/` and make sure to keep the filename exactly the same!
10. In the firebase console hit the `Next` button
11. Add Firebase SDK, these steps are already done in this example, so just hit `Next`
12. Add initialisation code, these are handled with the cloud_functions package, just hit `Next`
13. Finally hit `Continue to the console`

#### Configure web

1. Open your [firebase console](https://console.firebase.google.com/)
2. Open the project you created before
3. On this project overview page click the web icon to add an web app or if you do not see this option, click the `Add app` button
4. App nickname: `Twilio Programmable Video Example`
5. Click `Register app`
6. Copy the `firebaseConfig` constant data
7. Create a file called `configuration.js` in the `web` folder and copy the `firebaseConfig` constant into it
8. Finally hit `Continue to the console`

### Run the application

Before opening XCode, run `flutter build ios --debug` from the `example` directory.

Connect a device and/or emulator and run the Flutter application on it. Join the same room on several devices to talk with each other.
