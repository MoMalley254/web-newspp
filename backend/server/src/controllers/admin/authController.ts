import { Request, Response } from "express";
import { AdminData } from "../../types/adminTypes";
import { 
    createAdminService,
    loginService,
    updateAdminPassword,
    refreshAccessTokenService
} from "../../services/admin/authService";

export const createAdmin = async(req: Request, res: Response) => {
    try {
        console.log('Creating new admin fr');
        const { email, name, password, creator } = req.body;
        const sampleAdmin: AdminData  = {
            email: email, 
            name: name, 
            password: password
        };

        const createAdminResult = await createAdminService(sampleAdmin, creator);
        if (createAdminResult.status) {
            console.log('Created new admin');
            return res.status(201).json(`Logged in successfully admin: ${createAdminResult}`);
        } else {
            return res.status(200).json(`Error : ${createAdminResult.error}`);
        }

        
    } catch(createAdminError: any) {
        console.error('Error creating admin:', createAdminError);
        const status = createAdminError.status || 500;
        return res.status(status).json({ error: createAdminError.message || 'Internal server error' });
    }
}

export const loginAdmin = async(req: Request, res: Response) => {
    try {
        if (!req.body || req.body.email === '' || req.body.password === '') {
            return res.status(400).json({ error: 'Email or password cannot be empty'});
        }
        const loginData: AdminData = {
            email: req.body.email,
            name: '',
            password: req.body.password
        }

        const login = await loginService(loginData);
        if (!login.status) {
            return res.status(500).json({ error: login.error || 'Unable to login'})
        } else {
            return res.status(200).json({ admin: login.admin});
        }
        
    } catch(loginError: any) {
        console.error(`Error loging in ${loginError}`);
        const status = loginError.status || 500;
        return res.status(status).json({ error: loginError.message || 'Server error'});
    }
}

export const updateAdminPass = async(req: Request, res: Response) => {
    try {
        const { admin, oldPass, newPass } = req.body;

        const tryUpdate = await updateAdminPassword(admin, oldPass, newPass);
        if (!tryUpdate.status) {
            return res.status(500).json({ error: tryUpdate.error});
        } else {
            return res.status(201).json({ message: 'Update successful'});
        }

    } catch (updateAdminPassError: any) {
        console.error(`Error loging in ${updateAdminPassError}`);
        const status = updateAdminPassError.status || 500;
        return res.status(status).json({ error: updateAdminPassError.message || 'Server error'});
    }
}

export const refreshAccessToken = async(req: Request, res: Response) => {
    try {
        const { refreshToken } = req.body;
        if (!refreshToken) {
            return res.status(400).json({ error: 'Refresh token not found'});
        }
        
        const refresh = await refreshAccessTokenService(refreshToken);
        if (!refresh?.status) {
            return res.status(500).json({ error: refresh?.error});
        }

        return res.status(201).json({ newAToken: refresh.newAToken, rToken: refreshToken});
    } catch(refreshAccessTokenError: any) {
        console.error(`Refresh access token error ${refreshAccessTokenError}`);
        return res.status(500).json({ error: refreshAccessTokenError || 'Unable to refresh access token'});
    }
}
