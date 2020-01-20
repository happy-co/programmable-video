// tslint:disable-next-line:no-implicit-dependencies
import * as express from 'express'; // The express library gets installed as part of the Firebase https provider package
import {Request}    from 'firebase-functions/lib/providers/https';

/*
Title: Rooms Status Callbacks
Twilio docs: https://www.twilio.com/docs/video/api/status-callbacks#rooms-callbacks
*/

module.exports = (req: Request, res: express.Response) => {
    console.log(JSON.stringify(req.body));
    res.send('Received');
};
