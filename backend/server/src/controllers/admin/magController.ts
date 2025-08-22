import { Request, Response } from "express";
import {
    getAllMagsService
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