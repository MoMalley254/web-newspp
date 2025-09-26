import express from 'express';
import {
    renderIndexPage,
    fetchMagazines,
    renderSingleMagazine,
    returnImageUrls,
    renderGroupedPage,
    renderTagsPage
} from '../controllers/front/frontMagController';

const router = express.Router();

router.get('/', renderIndexPage);
router.get('/all', fetchMagazines);
router.get('/view', renderSingleMagazine);
router.post('/view/images', returnImageUrls);
router.get('/tag', renderGroupedPage);
router.get('/categories', renderTagsPage);

export default router;