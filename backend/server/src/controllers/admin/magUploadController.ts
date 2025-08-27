import { Request, Response } from "express";

export const newMagazineUpload = async(req: Request, res: Response) => {
    try {
        
    } catch (newMagazineUploadError: any) {
        console.error(`Error uploading magazine ${newMagazineUpload}`);
        return res.status(500).json({ error: newMagazineUploadError.message || 'Internal server error'});
    }
}