import express from 'express';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { authenticateAccessToken } from '../middlewares/admin/authMiddleware';
import {
  createAdmin,
  loginAdmin,
  updateAdminPass,
} from '../controllers/admin/authController';

import {
  getAllMags,
  createNewMag,
} from '../controllers/admin/magController';

const router = express.Router();

// ✅ Generate a timestamp folder name
function generateFolderName(): string {
  const now = new Date();
  const formatted = now.toISOString().replace(/[:.]/g, '-'); // e.g. "2025-08-22T15-36-22-123Z"
  return formatted;
}

// ✅ Dynamic Multer storage config
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const folderName = generateFolderName();
    const folderPath = path.join(__dirname, '..', '..', 'public', 'magazines', folderName);

    // Create folder if it doesn't exist
    if (!fs.existsSync(folderPath)) {
      fs.mkdirSync(folderPath, { recursive: true });
    }

    // Attach folder path to req so controller can find uploaded file if needed
    (req as any).uploadFolder = folderPath;

    cb(null, folderPath);
  },
  filename: function (req, file, cb) {
    cb(null, file.fieldname + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 500 * 1024 * 1024, // 500MB
  },
});

router.get('/', async (req, res) => {
  res.redirect('/login');
});

router.post('/create', authenticateAccessToken, createAdmin);
router.post('/login', loginAdmin);
router.post('/update', authenticateAccessToken, updateAdminPass);

// 🔥 Magazine upload — handles ALL file logic in route layer
router.post(
  '/mag/new',
  authenticateAccessToken,
  upload.fields([
    { name: 'html', maxCount: 1 },
    { name: 'cover', maxCount: 1 },
  ]),
  createNewMag // Only reads req.files, not involved in file saving
);

router.get('/mag/All', authenticateAccessToken, getAllMags);

export default router;
