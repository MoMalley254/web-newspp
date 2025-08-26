import { Request, Response } from "express";
import {
    fetchMagazinesService
} from '../../services/front/frontMagService';

export const renderIndexPage = async(req: Request, res: Response) => {
    try {
        return res.render('front/front');
    } catch(renderIndexPageError: any) {
        console.error(`Render index page error ${renderIndexPageError}`);
        return res.status(500).json({ error: renderIndexPageError.message || 'Server error'});
    }
}

export const fetchMagazines = async(req: Request, res: Response) => {
    try {
        const getMagazines = await fetchMagazinesService();
        if (!getMagazines.status) {
            return res.status(500).json({ error: getMagazines.error});
        } else {
            return res.status(200).json({ mags: getMagazines.mags});
        }
    } catch(fetchMagazinesError: any) {
        console.error(`Fetch magazines error ${fetchMagazinesError}`);
        return res.status(500).json({ error: fetchMagazinesError.message || 'Server error'});
    }
}