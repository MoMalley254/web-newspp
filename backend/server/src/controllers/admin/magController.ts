import { Request, Response } from "express";
import {
    getAllMagsService,
    createMagService
} from '../../services/admin/magService';

export const getAllMags = async (req: Request, res: Response) => {
    try {
        console.log('Getting mags');
        const getMagazines = await getAllMagsService();

        if(!getMagazines.status) {
            return res.status(500).json({ error: getMagazines.error || 'Unable to get magazines'});
        }

        return res.status(200).json({ magazines: getMagazines.mags});
    } catch(getAllMagsError: any) {
        return res.status(500).json({ error: getAllMagsError.message || 'Server error'});
    }
}

export const createNewMag = async (req: Request, res: Response) => {
  try {
    const { title, author, issue, date, tags, desc, adminId, credits} = req.body;
    const files = req.files as {
      [fieldname: string]: Express.Multer.File[];
    };

    const htmlFile = files?.html?.[0];
    const coverFile = files?.cover?.[0];

    if (!htmlFile) {
      return res.status(400).json({ error: 'HTML file is required' });
    }

    console.log('✅ HTML file path:', htmlFile.path);
    console.log('✅ Cover file path:', coverFile?.path ?? 'None uploaded');

    const newMagData = {
        title: title,
        author: author,
        issueNumber: parseInt(issue),
        publishDate: date,
        tags: tags,
        description: desc,
        publisher: 'Business Unusual',
        adminId: adminId,
        credits: credits,
        htmlPath: '\\public\\' + htmlFile.path.split('\\public\\').slice(1).join('\\public\\'),
        // coverImage: coverFile.path
    }

    const createMagResult = await createMagService(newMagData);
    if (!createMagResult.status) {
        return res.status(500).json({ error: createMagResult.error});
    }

    return res.status(201).json({
      message: 'Magazine uploaded successfully',
    });
  } catch (err) {
    console.error('❌ Error in createNewMag:', err);
    return res.status(500).json({ error: 'Failed to upload magazine' });
  }
};