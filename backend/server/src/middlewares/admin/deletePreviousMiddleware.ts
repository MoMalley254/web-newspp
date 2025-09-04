import express, { Request, Response, NextFunction } from "express";
import path from "path";
import fs from "fs";

// Middleware to delete old magazine files
export const deletePreviousMagazineFiles = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    console.log(`Request ${JSON.stringify(req.query)}`);
    const pagesPath = req.query.pagesPath;

    if (!pagesPath || typeof pagesPath !== "string") {
      return res
        .status(400)
        .json({ error: "pagesPath is required and must be a string" });
    }

    // Remove leading slashes to avoid path.resolve treating it as root-relative
    const safePath = pagesPath.replace(/^[/\\]+/, "");

    const magazineDir = path.join(__dirname, "..", "..", "..", safePath);

    if (fs.existsSync(magazineDir)) {
      fs.rmSync(magazineDir, { recursive: true, force: true });
      console.log(`✅ Deleted old files at: ${magazineDir}`);
    } else {
      console.log(`ℹ️ No files to delete at: ${magazineDir}`);
    }

    next();
  } catch (err) {
    console.error("❌ Error deleting previous files:", err);
    return res.status(500).json({ error: "Failed to delete previous files" });
  }
};
