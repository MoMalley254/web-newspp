import { NextFunction, Request, Response } from "express";
import {
  getAllMagsService,
  createMagService,
  findSingleMagService,
  updateMagazineService,
  deleteMagService,
  addTocsService,
  removeAllTocsService
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

export const updateMagazine = async (req: Request, res: Response, next: NextFunction) => {
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
        // valueToUse = files[cover][0].path.split("\\public\\").slice(1).join("\\public\\");
        valueToUse = "\\public\\" + files[cover][0].path.split("public\\").slice(1).join("public");
        // if (!valueToUse.includes('\\public\\')) {
        //   valueToUse = `\\public\\${valueToUse}`;
        // }
      } else {
        console.warn(`No file uploaded for field: ${cover}`);
      }

      if (field === "htmlPath") {
        // ✅ Directory path from multer setup
        const uploadFolder = (req as any).uploadFolder;
        const pagesDir = path.join(uploadFolder, "pages");
        const relativeUploadPath =
      "\\public\\" +
      pagesDir.split("public\\").slice(1).join("public");
      valueToUse = relativeUploadPath;
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

export const updateMagazineWithPdf = async(req: Request, res: Response) => {
  try {
    const { id, name, field, value } = req.body;

    // let valueToUse = ;

    const fullUploadPath = path.join((req as any).uploadFolder, "pages");
    const relativeUploadPath = "\\public\\" + fullUploadPath.split("public\\").slice(1).join("public");

    const updateMag = await updateMagazineService(
      { id: id, name: name, field: 'htmlPath', value: relativeUploadPath },
      false
    );
    if (updateMag?.status) {
      return res.status(201).json({ message: `${name} updated` });
    } else {
      return res.status(500).json({ error: updateMag?.error });
    }
  } catch(updateMagazineWithPdfError: any) {
    console.error(`Update magazine with pdf error ${updateMagazineWithPdfError}`);
    return res.status(500).json({ error: updateMagazineWithPdfError.message || 'Internal server error'});
  }
}

export const deleteMagazine = async (req: Request, res: Response) => {
  try {
    const { magId, admin } = req.body;

    if (!magId || magId === '' || !admin || admin === '') {
      return res.status(400).json({ error: 'Bad request: magId and admin are required' });
    }

    const deleteResult = await deleteMagService(magId, admin);

    if (!deleteResult.status) {
      return res.status(500).json({ error: deleteResult.error });
    }

    return res.status(200).json({ mag: deleteResult.data });
  } catch (deleteMagazineError: any) {
    console.error(`Delete magazine error: ${deleteMagazineError.message || deleteMagazineError}`);
    return res.status(500).json({ error: deleteMagazineError.message || 'Internal server error' });
  }
};

export const addNewTocs = async(req:Request, res: Response) => {
  try {
    const { admin, mag, tocs} = req.body;
    if (!admin || !mag || !tocs) {
      return res.status(500).json({ error: "Missing required fields"});
    }

    const addedTocs = await addTocsService(admin, mag, tocs);
    if (addedTocs.status) {
      return res.status(201).json({});
    } else {
      return res.status(500).json({ error: addedTocs.error});
    }
  } catch(addNewTocsError: any) {
    console.error(`Add new tocs error ${addNewTocsError}`);
    return res.status(500).json({ error: addNewTocsError.message || "Internal server error"});
  }
}

export const removeAllTocs = async(req:Request, res: Response) => {
  try {
    const { admin, mag} = req.body;
    if (!admin || !mag) {
      return res.status(500).json({ error: "Missing required fields"});
    }

    const removedTocs = await removeAllTocsService(admin, mag);
    if (removedTocs.status) {
      return res.status(203).json({});
    } else {
      return res.status(500).json({ error: removedTocs.error});
    }
  } catch(removeAllTocsError: any) {
    console.error(`Add new tocs error ${removeAllTocsError}`);
    return res.status(500).json({ error: removeAllTocsError.message || "Internal server error"});
  }
}
