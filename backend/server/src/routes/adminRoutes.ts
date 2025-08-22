import express from 'express';
import { authenticateAccessToken } from '../middlewares/admin/authMiddleware';
import {
    createAdmin,
    loginAdmin,
    updateAdminPass
} from '../controllers/admin/authController';

import {
    getAllMags
} from '../controllers/admin/magController';

const router = express.Router();

router.get('/', async(req, res) => {
    res.redirect('/login');
});

router.post('/create', authenticateAccessToken, createAdmin);
router.post('/login', loginAdmin);
router.post('/update', authenticateAccessToken, updateAdminPass);

//Mag routes
router.get('/mag/All', authenticateAccessToken, getAllMags);

export default router;