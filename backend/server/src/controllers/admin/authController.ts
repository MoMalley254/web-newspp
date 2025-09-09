import { Request, Response } from "express";
import { AdminData } from "../../types/adminTypes";
import {
  createAdminService,
  loginService,
  updateAdminPassword,
  refreshAccessTokenService,
  getAdminsService,
  updateAccountService,
  deleteAccountService,
} from "../../services/admin/authService";

export const createAdmin = async (req: Request, res: Response) => {
  try {
    const { email, name, password, role, creator } = req.body;
    const sampleAdmin: AdminData = {
      email: email,
      name: name,
      password: password,
    };

    const createAdminResult = await createAdminService(
      sampleAdmin,
      role,
      creator
    );
    if (createAdminResult.status) {
      return res.status(201).json();
    } else {
      return res.status(500).json({ error: createAdminResult.error });
    }
  } catch (createAdminError: any) {
    console.error("Error creating admin:", createAdminError);
    return res
      .status(500)
      .json({ error: createAdminError.message || "Internal server error" });
  }
};

export const loginAdmin = async (req: Request, res: Response) => {
  try {
    if (!req.body || req.body.email === "" || req.body.password === "") {
      return res
        .status(400)
        .json({ error: "Email or password cannot be empty" });
    }
    const loginData: AdminData = {
      email: req.body.email,
      name: "",
      password: req.body.password,
    };

    const login = await loginService(loginData);
    if (!login.status) {
      return res.status(500).json({ error: login.error || "Unable to login" });
    } else {
      return res.status(200).json({ admin: login.admin });
    }
  } catch (loginError: any) {
    console.error(`Error loging in ${loginError}`);
    const status = loginError.status || 500;
    return res
      .status(status)
      .json({ error: loginError.message || "Server error" });
  }
};

export const updateAdminPass = async (req: Request, res: Response) => {
  try {
    const { admin, oldPass, newPass } = req.body;

    const tryUpdate = await updateAdminPassword(admin, oldPass, newPass);
    if (!tryUpdate.status) {
      return res.status(500).json({ error: tryUpdate.error });
    } else {
      return res.status(201).json({ message: "Update successful" });
    }
  } catch (updateAdminPassError: any) {
    console.error(`Error loging in ${updateAdminPassError}`);
    const status = updateAdminPassError.status || 500;
    return res
      .status(status)
      .json({ error: updateAdminPassError.message || "Server error" });
  }
};

export const refreshAccessToken = async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: "Refresh token not found" });
    }

    const refresh = await refreshAccessTokenService(refreshToken);
    if (!refresh?.status) {
      return res.status(500).json({ error: refresh?.error });
    }

    return res
      .status(201)
      .json({ newAToken: refresh.newAToken, rToken: refreshToken });
  } catch (refreshAccessTokenError: any) {
    console.error(`Refresh access token error ${refreshAccessTokenError}`);
    return res
      .status(500)
      .json({
        error: refreshAccessTokenError || "Unable to refresh access token",
      });
  }
};

export const getAdmins = async (req: Request, res: Response) => {
  try {
    const { admin } = req.body;
    if (!admin || admin === "") {
      return res.status(500).json({ error: "Not authorized" });
    }

    const allAdmins = await getAdminsService(admin);
    if (allAdmins.status) {
      return res.status(200).json({ admins: allAdmins.admins });
    } else {
      return res.status(500).json({ error: allAdmins.error });
    }
  } catch (error) {
    console.error(`Get admins error ${error}`);
    return res.status(500).json({ error: error || "Server error" });
  }
};

export const updateAccount = async (req: Request, res: Response) => {
  try {
    const { account, field, value, admin } = req.body;

    if (!account || !field || !value || !admin) {
      return res.status(500).json({ error: "Missing required fields" });
    }

    const doUpdate = await updateAccountService(admin, account, field, value);
    if (doUpdate.status) {
      return res.status(201).json({ message: "Account updated successfully" });
    } else {
      return res.status(500).json({ error: doUpdate.error });
    }
  } catch (updateAccountError: any) {
    console.error(`Update account error ${updateAccountError}`);
    return res.status(500).json({ error: updateAccountError });
  }
};

export const deleteAccount = async (req: Request, res: Response) => {
  try {
    const { admin, account } = req.body;
    if (!admin || !account) {
      return res.status(500).json({ error: "Missing required fields" });
    }

    const doDelete = await deleteAccountService(admin, account);
    if (!doDelete.status) {
      return res.status(500).json({ error: doDelete.error });
    } else {
      return res.status(203).json();
    }
  } catch (deleteAccountError: any) {
    console.error(`Delete account error ${deleteAccountError}`);
    return res
      .status(500)
      .json({ error: deleteAccountError.message || "Server error" });
  }
};
