import * as functions    from 'firebase-functions';
import {CallableContext} from 'firebase-functions/lib/providers/https';

/*
Title: Retrieve an in-progress Room instance by UniqueName
Twilio Docs Access Tokens: https://www.twilio.com/docs/video/tutorials/user-identity-access-tokens
*/

module.exports = async (data: any, context: CallableContext) => {
    // If you plan to use Firebase Authentication, you could do some checks on the context.auth, like this:
    // if (!(context.auth && context.auth.token)) {
    //     throw new functions.https.HttpsError(
    //         'permission-denied',
    //         'Must be an authorized user to execute this function.'
    //     );
    // }
    if (!data.uniqueName) {
        throw new functions.https.HttpsError('invalid-argument', 'uniqueName is required!');
    }
    // Make sure the identity is unique. When a
    if (!data.identity) {
        throw new functions.https.HttpsError('invalid-argument', 'identity is required!');
    }

    try {
        const accountSid = functions.config().twilio.live.account_sid;
        const apiKey = functions.config().twilio.api_key;
        const apiSecret = functions.config().twilio.api_secret;

        const AccessToken = require('twilio').jwt.AccessToken;

        // Create an access token which we will sign and return to the client,
        // containing the grant we just created
        const token = new AccessToken(
            accountSid,
            apiKey,
            apiSecret,
            {
                identity: data.identity
            }
        );

        // Grant the access token Twilio Video capabilities
        token.addGrant(new AccessToken.VideoGrant({room: data.uniqueName}));

        console.log(`Identity ${data.identity} requested a token for room ${data.uniqueName}`);

        // Serialize the token to a JWT string
        return {
            uniqueName: data.uniqueName,
            identity: data.identity,
            token: token.toJwt()
        };
    } catch (e) {
        console.error(e);
        throw new functions.https.HttpsError(
            'aborted',
            `${e}`
        );
    }
};
