import express from 'express';
import {
    renderIndexPage,
    fetchMagazines,
    renderSingleMagazine
} from '../controllers/front/frontMagController';

const router = express.Router();

router.get('/', renderIndexPage);
router.get('/all', fetchMagazines);
router.get('/view', renderSingleMagazine);

export default router;