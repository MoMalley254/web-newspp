import { NextFunction, Request, Response } from "express";
import {
  getAllMagsService,
  createMagService,
  findSingleMagService,
  updateMagazineService,
} from "../../services/admin/magService";
import path from "path";

export const getAllMags = async (req: Request, res: Response) => {
  try {
    console.log("Getting mags");
    const getMagazines = await getAllMagsService();

    if (!getMagazines.status) {
      return res
        .status(500)
        .json({ error: getMagazines.error || "Unable to get magazines" });
    }

    return res.status(200).json({ magazines: getMagazines.mags });
  } catch (getAllMagsError: any) {
    return res
      .status(500)
      .json({ error: getAllMagsError.message || "Server error" });
  }
};

export const createNewMag = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { title, author, issue, date, tags, desc, adminId, credits } =
      req.body;

    const files = req.files as {
      [fieldname: string]: Express.Multer.File[];
    };

    const coverFile = files?.cover?.[0];

    // ✅ Directory path from multer setup
    const uploadFolder = (req as any).uploadFolder;
    const pagesDir = path.join(uploadFolder, "pages");

    if (!pagesDir) {
      return res.status(500).json({ error: "Upload directory missing" });
    }

    console.log("✅ Upload directory:", pagesDir);
    console.log("✅ Cover file path:", coverFile?.path ?? "None uploaded");

    let hasImage = false;

    // ✅ Construct paths
    const relativeUploadPath =
      "\\public\\" +
      pagesDir.split("public\\").slice(1).join("public");

      console.log(`Relative path ${relativeUploadPath}`);

    const newMagData = {
      title: title,
      author: author,
      issueNumber: parseInt(issue),
      publishDate: date,
      tags: tags,
      description: desc,
      publisher: "Business Unusual",
      adminId: adminId,
      credits: credits,
      htmlPath: relativeUploadPath, // ✅ Save directory path, not HTML
      coverImage: "",
    };

    if (coverFile) {
      newMagData.coverImage =
        "\\public\\" +
        coverFile.path.split("public\\").slice(1).join("public");
      hasImage = true;
    }

    const createMagResult = await createMagService(newMagData, hasImage);
    if (!createMagResult.status) {
      return res.status(500).json({ error: createMagResult.error });
    }

    return res.status(201).json({
      message: "Magazine uploaded successfully",
    });
  } catch (err) {
    console.error("❌ Error in createNewMag:", err);
    return res.status(500).json({ error: "Failed to upload magazine" });
  }
};


export const findMagazine = async (req: Request, res: Response) => {
  try {
    const { id } = req.body;

    const magazine = await findSingleMagService(id);
    if (magazine.status) {
      console.log(`Mag found ${JSON.stringify(magazine.magData)}`);

      return res.status(200).json({ mag: magazine.magData });
    } else {
      return res.status(500).json({ error: magazine.error });
    }
  } catch (findMagazineError: any) {
    console.error(`Find magazine error ${findMagazineError}`);
    return res.status(500).json({ error: findMagazineError });
  }
};

export const updateMagazine = async (req: Request, res: Response) => {
  try {
    const { id, name, field, value } = req.body;

    let valueToUse = value;

    if (field === "coverImage" || field === "htmlPath") {
      const cover = field === "coverImage" ? "cover" : "html";

      // Narrow type for req.files as Record<string, Express.Multer.File[]>
      const files = req.files as
        | Record<string, Express.Multer.File[]>
        | undefined;

      if (files && files[cover] && files[cover][0]) {
        valueToUse = files[cover][0].path.split("\\public\\").slice(1).join("\\public\\");
        if (!valueToUse.includes('\\public\\')) {
          valueToUse = `\\public\\${valueToUse}`;
        }
      } else {
        console.warn(`No file uploaded for field: ${cover}`);
      }
    }

    const isCredits = field.includes("credits");

    const updateMag = await updateMagazineService(
      { id: id, name: name, field: field, value: valueToUse },
      isCredits
    );
    if (updateMag?.status) {
      return res.status(201).json({ message: `${name} updated` });
    } else {
      return res.status(500).json({ error: updateMag?.error });
    }
  } catch (updateMagazineError: any) {
    console.error(`Update magazine error ${updateMagazineError}`);
    return res
      .status(500)
      .json({ error: updateMagazineError.message || "Server error" });
  }
};
