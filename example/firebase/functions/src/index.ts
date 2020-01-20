import * as functions   from 'firebase-functions';
import {RuntimeOptions} from 'firebase-functions/lib/function-configuration';

// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript

const region = functions.region('europe-west1');
const runtimeOptions: RuntimeOptions = {timeoutSeconds: 10, memory: '128MB'};

const rooms = require('./rooms');
const roomStatusCallback = require('./status-callbacks/programmable-video/rooms');
const compositionStatusCallback = require('./status-callbacks/programmable-video/compositions');

module.exports = {
    completeRoomBySid: region.runWith(runtimeOptions).https.onCall(rooms.completeRoomBySid),
    createRoom: region.runWith(runtimeOptions).https.onCall(rooms.createRoom),
    createToken: region.runWith(runtimeOptions).https.onCall(rooms.createToken),
    getRoomBySid: region.runWith(runtimeOptions).https.onCall(rooms.getRoomBySid),
    getRoomByUniqueName: region.runWith(runtimeOptions).https.onCall(rooms.getRoomByUniqueName),
    listRooms: region.runWith(runtimeOptions).https.onCall(rooms.listRooms),
    programmableVideo: {
        compositions: {
            statusCallback: region.runWith(runtimeOptions).https.onRequest(compositionStatusCallback)
        },
        rooms: {
            statusCallback: region.runWith(runtimeOptions).https.onRequest(roomStatusCallback)
        }
    }
};
