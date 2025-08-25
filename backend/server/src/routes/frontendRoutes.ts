import express from 'express';
import {
    renderIndexPage
} from '../controllers/front/frontMagController';

const router = express.Router();

router.get('/', renderIndexPage);

export default router;