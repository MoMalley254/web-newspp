import { Request, Response } from "express";

export const renderIndexPage = async(req: Request, res: Response) => {
    try {
        return res.render('front/front');
    } catch(renderIndexPageError: any) {
        console.error(`Render index page error ${renderIndexPageError}`);
        return res.status(500).json({ error: renderIndexPageError.message || 'Server error'});
    }
}