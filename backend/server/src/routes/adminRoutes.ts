import express from "express";
import multer from "multer";
import fs from "fs";
import path from "path";
import { authenticateAccessToken } from "../middlewares/admin/authMiddleware";
import {
  createAdmin,
  loginAdmin,
  updateAdminPass,
  refreshAccessToken,
} from "../controllers/admin/authController";

import {
  getAllMags,
  createNewMag,
  findMagazine,
  updateMagazine,
  deleteMagazine
} from "../controllers/admin/magController";

const router = express.Router();

// ✅ Generate a timestamp folder name
function generateFolderName(): string {
  const now = new Date();

  const day = String(now.getDate()).padStart(2, "0"); // DD
  const month = String(now.getMonth() + 1).padStart(2, "0"); // MM (getMonth() is zero-based)
  const year = now.getFullYear(); // YYYY

  const formatted = `${day}-${month}-${year}`;
  return formatted;
}

// 🕒 Generate folder name: "DD-MM-YYYY"
function generateDateFolder(): string {
  const now = new Date();
  const day = String(now.getDate()).padStart(2, "0");
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const year = now.getFullYear();
  return `${day}-${month}-${year}`;
}

// 🕒 Generate subfolder: "HH-MM-SS"
function generateTimeFolder(): string {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, "0");
  const minutes = String(now.getMinutes()).padStart(2, "0");
  const seconds = String(now.getSeconds()).padStart(2, "0");
  return `${hours}`;
}

// ✅ Dynamic Multer storage config
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dateFolder = generateDateFolder();    // e.g. "27-08-2025"
    const timeFolder = generateTimeFolder();    // e.g. "14"
    const folderPath = path.join(
      __dirname,
      "..",
      "..",
      "public",
      "magazines",
      dateFolder,
      timeFolder
    );

    // Create folder if it doesn't exist
    if (!fs.existsSync(folderPath)) {
      fs.mkdirSync(folderPath, { recursive: true });
    }

    // Attach folder path to req so controller can find uploaded file if needed
    (req as any).uploadFolder = folderPath;

    const targetFolder =
      file.fieldname === "images"
        ? path.join(folderPath, "pages")
        : folderPath;

    if (!fs.existsSync(targetFolder)) {
      fs.mkdirSync(targetFolder, { recursive: true });
    }

    cb(null, targetFolder);
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname);
  },
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 500 * 1024 * 1024, // 500MB
  },
});

router.get("/", async (req, res) => {
  res.redirect("/login");
});

router.post("/create", authenticateAccessToken, createAdmin);
router.post("/login", loginAdmin);
router.post("/update", authenticateAccessToken, updateAdminPass);
router.post("/refresh", refreshAccessToken);

router.post(
  "/mag/new",
  authenticateAccessToken,
  upload.fields([
    { name: "cover", maxCount: 1 },
    { name: "images", maxCount: 100 },
  ]),
  async (req, res, next) => {
    try {
      const files = req.files as {
        cover?: Express.Multer.File[];
        images?: Express.Multer.File[];
      };

      const images = files.images || [];

      // 🔁 If no cover, use the first image as cover
      if (!files.cover || files.cover.length === 0) {
        if (images.length > 0) {
          files.cover = [images[0]]; 
        } else {
          return res.status(400).json({
            error: "No cover provided and no images available to use as cover.",
          });
        }
      }

      // ✅ Hand off to controller
      await createNewMag(req, res, next);
    } catch (err) {
      console.error("Error processing magazine pages:", err);
      res.status(500).json({ error: "Failed to upload magazine" });
    }
  }
);

router.get("/mag/All", authenticateAccessToken, getAllMags);

router.get("/mag/one", authenticateAccessToken, findMagazine);

router.post(
  "/mag/update",
  authenticateAccessToken,
  upload.fields([
    { name: "html", maxCount: 1 },
    { name: "cover", maxCount: 1 },
  ]),
  updateMagazine
);

router.post("/mag/del", authenticateAccessToken, deleteMagazine);

export default router;
