import * as express   from 'express';
import * as twilioSdk from 'twilio';
import {twilio}       from './twilio';

export const routes = (): express.Router => {
    const router: express.Router = express.Router();
    /**
     * As middleware we use the by Twilio provided [webhook] function. This
     * guarantees that the incoming request is really originating from Twilio.
     *
     * More information here:
     * https://www.twilio.com/docs/usage/tutorials/how-to-secure-your-express-app-by-validating-incoming-twilio-requests
     */
    router.use('/twilio', twilioSdk.webhook({validate: !(!!process.env.FUNCTIONS_EMULATOR), protocol: 'https'}), twilio());
    return router;
};
