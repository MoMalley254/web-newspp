import express from 'express';
import {
    renderIndexPage,
    fetchMagazines,
    renderSingleMagazine,
    returnImageUrls,
    renderGroupedPage,
    renderTagsPage
} from '../controllers/front/frontMagController';

import {
    saveUserMail
} from "../controllers/front/frontUserController";

const router = express.Router();

router.get('/', renderIndexPage);
router.get('/all', fetchMagazines);
router.get('/view', renderSingleMagazine);
router.post('/view/images', returnImageUrls);
router.get('/tag', renderGroupedPage);
router.get('/categories', renderTagsPage);

router.post('/mail/create', saveUserMail);

export default router;