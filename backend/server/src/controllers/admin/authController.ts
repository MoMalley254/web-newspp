import { Request, Response } from "express";
import { AdminData } from "../../types/admin/adminTypes";
import { 
    createAdminService,
    loginService,
    updateAdminPassword
} from "../../services/admin/authService";

export const createAdmin = async(req: Request, res: Response) => {
    try {
        console.log('Creating new admin fr');
        const sampleAdmin: AdminData  = {
            email: 'notclankr@gmail.com', 
            name: 'Not Clankr', 
            password: 'superClankr1'
        };

        const createAdminResult = await createAdminService(sampleAdmin);
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
        const loginData: AdminData = {
            email: 'notclankr@gmail.com',
            name: '',
            password: 'superClankr1'
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
        const newPass: string = 'superClankr1';
        const email: string = 'notclankr@gmail.com';
        const oldPass: string = 'newClankrPass';

        const tryUpdate = await updateAdminPassword(email, oldPass, newPass);
        if (!tryUpdate.status) {
            return res.status(500).json({ error: tryUpdate.error});
        } else {
            console.log(`Update successful to ${newPass}`);
            return res.status(201).json({ message: 'Update successful'});
        }

    } catch (updateAdminPassError: any) {
        console.error(`Error loging in ${updateAdminPassError}`);
        const status = updateAdminPassError.status || 500;
        return res.status(status).json({ error: updateAdminPassError.message || 'Server error'});
    }
}
