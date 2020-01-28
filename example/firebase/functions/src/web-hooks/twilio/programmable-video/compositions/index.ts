import * as express from 'express';

export const compositions = (): express.Router => {
    const router: express.Router = express.Router();
    router.post('/', ((req: express.Request, res: express.Response) => {
        console.log(JSON.stringify(req.body));
        res.sendStatus(200);
    }));

    return router;
};
