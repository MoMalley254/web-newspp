import express from 'express';
import {
    renderIndexPage,
    fetchMagazines,
    renderSingleMagazine,
    returnImageUrls
} from '../controllers/front/frontMagController';

const router = express.Router();

router.get('/', renderIndexPage);
router.get('/all', fetchMagazines);
router.get('/view', renderSingleMagazine);
router.post('/view/images', returnImageUrls);

export default router;