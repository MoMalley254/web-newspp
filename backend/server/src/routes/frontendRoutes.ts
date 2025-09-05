import express from 'express';
import {
    renderIndexPage,
    fetchMagazines,
    renderSingleMagazine,
    returnImageUrls,
    renderGroupedPage
} from '../controllers/front/frontMagController';

const router = express.Router();

router.get('/', renderIndexPage);
router.get('/all', fetchMagazines);
router.get('/view', renderSingleMagazine);
router.post('/view/images', returnImageUrls);
router.get('/tag', renderGroupedPage)

export default router;