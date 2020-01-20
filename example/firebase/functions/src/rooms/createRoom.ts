import * as functions    from 'firebase-functions';
import {CallableContext} from 'firebase-functions/lib/providers/https';
import * as _            from 'lodash';

/*
Title: Create a Room
Twilio NodeJS Example: https://www.twilio.com/docs/video/api/rooms-resource?code-sample=code-create-a-room&code-language=Node.js&code-sdk-version=3.x
Request: https://www.twilio.com/docs/video/api/rooms-resource?code-sample=code-retrieve-an-in-progress-room-instance-by-uniquename&code-language=Node.js&code-sdk-version=3.x#post-list-resource
*/

module.exports = async (data: any, context: CallableContext) => {
    // If you plan to use Firebase Authentication, you could do some checks on the context.auth, like this:
    // if (!(context.auth && context.auth.token)) {
    //     throw new functions.https.HttpsError(
    //         'permission-denied',
    //         'Must be an authorized user to execute this function.'
    //     );
    // }

    try {
        const accountSid = functions.config().twilio.live.account_sid;
        const authToken = functions.config().twilio.live.auth_token;

        const client = require('twilio')(accountSid, authToken);

        const defaultOptions = {
            statusCallbackMethod: 'POST',
            statusCallback: `https://europe-west1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/programmableVideo-rooms-statusCallback`
        };
        const options = _.merge({}, defaultOptions, _.omitBy(data, _.isNil));
        console.log('Request: ', JSON.stringify(options));
        const response = JSON.stringify(await client.video.rooms.create(options));
        console.log('Response: ', response);
        return JSON.parse(response);
    } catch (e) {
        console.error(e);
        throw new functions.https.HttpsError(
            'aborted',
            `${e}`
        );
    }
};
