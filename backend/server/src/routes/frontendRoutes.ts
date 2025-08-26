import express from 'express';
import {
    renderIndexPage,
    fetchMagazines
} from '../controllers/front/frontMagController';

const router = express.Router();

router.get('/', renderIndexPage);
router.get('/all', fetchMagazines);

export default router;