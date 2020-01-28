import * as express        from 'express';
import {programmableVideo} from './programmable-video';

export const twilio = (): express.Router => {
    const router: express.Router = express.Router();
    router.use('/programmable-video', programmableVideo());

    return router;
};
