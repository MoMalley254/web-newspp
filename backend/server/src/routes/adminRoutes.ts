import express from 'express';
import { authenticateAccessToken } from '../middlewares/admin/authMiddleware';
import {
    createAdmin,
    loginAdmin,
    updateAdminPass
} from '../controllers/admin/authController';

const router = express.Router();

router.get('/', async(req, res) => {
    res.redirect('/login');
});

router.get('/create', authenticateAccessToken, createAdmin);
router.get('/login', loginAdmin);
router.get('/update', authenticateAccessToken, updateAdminPass);

export default router;