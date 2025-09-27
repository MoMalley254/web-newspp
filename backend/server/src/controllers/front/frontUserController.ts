import { Request, Response } from "express";

import {
    saveUserMailService
} from "../../services/front/frontUserService";

export const saveUserMail = async(req: Request, res: Response) => {
    try {
        const userMail = req.body.mail;
        if (!userMail) {
            return res.status(500).json({ error: "Email cannot be empty"});
        }

        const savedMail = await saveUserMailService(userMail);
        if (!savedMail.status) {
            return res.status(500).json({ error: savedMail.error});
        } else {
            return res.status(201).json({});
        }
    } catch(saveUserMailError: any) {
        console.error(`Save user mail error ${saveUserMailError}`);
        return res.status(500).json({ error: saveUserMailError.message || "Internal server error"});
    }
};