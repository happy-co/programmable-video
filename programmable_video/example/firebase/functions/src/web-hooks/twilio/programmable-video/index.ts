import * as express   from 'express';
import {rooms}        from './rooms';
import {compositions} from './compositions';

export const programmableVideo = (): express.Router => {
    const router: express.Router = express.Router();
    router.use('/rooms', rooms());
    router.use('/compositions', compositions());

    return router;
};
