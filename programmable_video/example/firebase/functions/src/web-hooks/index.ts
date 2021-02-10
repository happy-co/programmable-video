import * as express     from 'express';
import * as bearerToken from 'express-bearer-token';
import {routes}         from './routes';

/**
 * More information on how to build and structure a serverless REST API with
 * Firebase Functions + Express can be found here:
 * https://medium.com/@jasonbyrne/how-to-structure-a-serverless-rest-api-with-firebase-functions-express-1d7b93aaa6af
 */
export const webHooks = (): express.Application => {
    const wHooks: express.Application = express();

    wHooks.use((req: express.Request, res: express.Response, next: express.NextFunction) => {
        console.log(`Incoming request: ${req.url}`);
        // Due to the nature of CloudFunctions, the first part [webHooksApi] is not part
        // of the url anymore. Twilio however has used the full url to sign their response.
        // It uses the [req.originalUrl] property to validate their signature, so we
        // need to put [webHooksApi] back in at the right position.
        if (!(!!process.env.FUNCTIONS_EMULATOR)) {
            req.originalUrl = req.url = `/webHooksApi${req.originalUrl}`;
        } else {
            req.url = `/webHooksApi${req.url}`
        }
        // Overriding settings like the 'x-powered-by' cannot be done on the [wHooks]
        // instance like you would normally do, but it needs to be done on the
        // [res] object.
        res.set('x-powered-by', 'twilio-flutter/programmable-video');
        next();
    });

    // Parse bearer token
    wHooks.use(bearerToken());

    // Parse Query String
    wHooks.use(express.urlencoded({extended: false}));

    // Parse posted body as JSON
    wHooks.use(express.json());

    // Configure the routes
    wHooks.use('/webHooksApi/web-hooks', routes());

    return wHooks;
};
