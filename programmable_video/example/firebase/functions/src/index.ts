import * as admin       from 'firebase-admin';
import * as functions   from 'firebase-functions';
import {RuntimeOptions} from 'firebase-functions/lib/function-configuration';
import * as rooms       from './rooms';
import {webHooks}       from './web-hooks';

// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript

// Initialize our project application
admin.initializeApp(functions.config().firebase);

// Initialize environment variables
process.env.TWILIO_AUTH_TOKEN = functions.config().twilio.live.auth_token;
process.env.TWILIO_ACCOUNT_SID = functions.config().twilio.live.account_sid;
process.env.TWILIO_API_KEY = functions.config().twilio.api_key;
process.env.TWILIO_API_SECRET = functions.config().twilio.api_secret;

const region = functions.region('europe-west1');
const runtimeOptions: RuntimeOptions = {timeoutSeconds: 10, memory: '128MB'};

// Callable functions
export const createRoom = region.runWith(runtimeOptions).https.onCall(rooms.createRoom);
export const completeRoomBySid = region.runWith(runtimeOptions).https.onCall(rooms.completeRoomBySid);
export const createToken = region.runWith(runtimeOptions).https.onCall(rooms.createToken);
export const getRoomBySid = region.runWith(runtimeOptions).https.onCall(rooms.getRoomBySid);
export const getRoomByUniqueName = region.runWith(runtimeOptions).https.onCall(rooms.getRoomByUniqueName);
export const listRooms = region.runWith(runtimeOptions).https.onCall(rooms.listRooms);
// Web-hooks Serverless API
export const webHooksApi = region.runWith(runtimeOptions).https.onRequest(webHooks());
