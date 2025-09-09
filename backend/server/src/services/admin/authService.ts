import prisma from "../../config/prismaClient";
import * as argon2 from "argon2";
import { AdminData, RefreshTokenValidationResult } from "../../types/adminTypes";
import jwt, { JwtPayload } from "jsonwebtoken";
import { Role } from "@prisma/client";

export const createAdminService = async (newAdminData: AdminData, role: Role, creatorId: string) => {
  try {
    const creator = await prisma.admin.findUnique({
      where: { id: creatorId}
    });

    if (!creator || creator.role !== 'ADMIN') {
      return {
        status: false,
        error: "Unauthorized"
      }
    }
    // Hash the password
    const hashedPass = await argon2.hash(newAdminData.password);

    // Prepare new admin object with hashed password
    const newAdminWithPass= {
      email: newAdminData.email,
      name: newAdminData.name,
      password: hashedPass,
    };

    // Check if admin with the same email exists
    const adminExists = await prisma.admin.findUnique({
      where: { email: newAdminWithPass.email },
    });

    if (adminExists) {
      return {
        status: false,
        error: "Admin with the same email already exists",
      };
    }

    // Create the new admin in the database
    const createdAdmin = await prisma.admin.create({
      data: {...newAdminWithPass, role: role},
    });

    // Exclude password from returned object
    const { password, ...adminWithoutPassword } = createdAdmin;

    return {
      status: true,
      data: adminWithoutPassword,
    };
  } catch (createError: any) {
    console.error(`Create admin error: ${createError}`);
    return {
      status: false,
      error: createError.message || "Failed to create admin",
    };
  }
};

export const loginService = async (loginData: AdminData) => {
  try {
    const adminExists = await prisma.admin.findFirst({
      where: { email: loginData.email },
    });

    if (!adminExists) {
      return {
        status: false,
        error: `${loginData.email} does not exist`,
      };
    }

    if (!loginData.password || typeof loginData.password !== "string") {
      return {
        status: false,
        error: `Invalid password provided`,
      };
    }

    //Verify Pass
    const passwordMatch: boolean = await argon2.verify(
      adminExists.password,
      loginData.password
    );
    if (!passwordMatch) {
      return {
        status: false,
        error: `Incorrect password`,
      };
    }

    const tokens = generateTokens(adminExists.id);

    const { password, ...adminWithoutPass } = adminExists;

    return {
      status: true,
      admin: {
        ...adminWithoutPass,
        ...tokens,
      },
    };
  } catch (loginError: any) {
    console.error(`Login service error ${loginError}`);
    return {
      status: false,
      error: loginError,
    };
  }
};

function generateTokens(userId: string) {
  if (!process.env.JWT_SECRET || !process.env.REFRESH_SECRET) {
    throw new Error(
      "Missing JWT_SECRET or REFRESH_SECRET in environment variables."
    );
  }

  const accessToken = jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: "1d",
  });
  const refreshToken = jwt.sign({ userId }, process.env.REFRESH_SECRET, {
    expiresIn: "30d",
  });

  return {
    aToken: accessToken,
    rToken: refreshToken,
  };
}

export const updateAdminPassword = async (
  id: string,
  oldPass: string,
  newPass: string
) => {
  try {
    const adminToUpdate = await prisma.admin.findFirst({
      where: { id },
    });

    if (!adminToUpdate) {
      return {
        status: false,
        error: `User does not exist`,
      };
    }

    const passwordMatch: boolean = await argon2.verify(
      adminToUpdate.password,
      oldPass
    );
    if (!passwordMatch) {
      console.log(`Password dont match`);
      return {
        status: false,
        error: `Incorrect password`,
      };
    }

    const newHash = await argon2.hash(newPass);
    const update = await prisma.admin.update({
      where: { id },
      data: { password: newHash },
    });

    if (!update) {
      return {
        status: false,
        error: "Unable to update",
      };
    } else {
      return {
        status: true,
      };
    }
  } catch (updateAdminPasswordError: any) {
    console.error(
      `Update admin password error: ${updateAdminPasswordError.message}`
    );
    return {
      status: false,
      error: updateAdminPasswordError,
    };
  }
};

export const refreshAccessTokenService = async (rToken: string) => {
  try {
    if (!process.env.REFRESH_SECRET || !process.env.JWT_SECRET) {
      throw new Error("Missing required environment variables.");
    }

    const validationResult = await validateRefreshToken(rToken);

    if (!validationResult.valid || !validationResult.userId) {
      return {
        status: false,
        error: 'Session expired, unable to refresh',
      };
    }

    const accessToken = jwt.sign(
      { userId: validationResult.userId },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    return {
      status: true,
      newAToken: accessToken,
      // newAToken: '',
    };

  } catch (err: any) {
    console.error(`Refresh access token service error:`, err);

    return {
      status: false,
      error: 'Failed to refresh access token.',
    };
  }
};


async function validateRefreshToken(rToken: string): Promise<RefreshTokenValidationResult> {
  try {
    const decoded = jwt.verify(rToken, process.env.REFRESH_SECRET!) as JwtPayload;

    if (!decoded.userId) {
      return { valid: false };
    }

    return {
      valid: true,
      userId: decoded.userId,
    };
  } catch (err: any) {
    console.error('Refresh token validation error:', err);
    return {
      valid: false,
      error: err,
    };
  }
}

export const getAdminsService = async(adminId: string) => {
  try {
    const getAdmin = await prisma.admin.findUnique({
      where: { id: adminId}
    });

    if (!getAdmin || getAdmin.role !== 'ADMIN') {
      return {
        status: false,
        error: 'Unable to authorize'
      }
    }

    const allAdmins = await prisma.admin.findMany({
      select: {
        name: true,
        id: true,
        email: true,
        role: true
      }
    });

    return {
      status: true,
      admins: allAdmins || []
    }
  } catch(getAdminsServiceError: any) {
    return {
      status: false,
      error: getAdminsServiceError.message
    }
  }
}

export const updateAccountService = async (
  adminId: string,
  accountId: string,
  field: string,
  value: string
) => {
  try {
    // 1. Verify the updater is an ADMIN
    const updater = await prisma.admin.findUnique({
      where: { id: adminId }
    });

    if (!updater || updater.role !== 'ADMIN') {
      return {
        status: false,
        error: "Unauthorized"
      };
    }

    // 2. Verify the target account exists
    const accountExists = await prisma.admin.findUnique({
      where: { id: accountId }
    });

    if (!accountExists) {
      return {
        status: false,
        error: "Account does not exist"
      };
    }

    // 3. Validate allowed fields
    const allowedFields = ['name', 'email', 'role', 'password']; 
    if (!allowedFields.includes(field)) {
      return {
        status: false,
        error: `Field '${field}' is not allowed to be updated.`
      };
    }

    // 4. Prepare update object dynamically
    const updateData: Record<string, any> = {};
    if (field === 'password') {
      const hashedPass = await argon2.hash(value);
      updateData[field] = hashedPass;
    } else {
      updateData[field] = value;
    }

    // 5. Perform update
    const updatedAccount = await prisma.admin.update({
      where: { id: accountId },
      data: updateData
    });

    return {
      status: true,
      data: updatedAccount
    };

  } catch (updateAccountServiceError: any) {
    console.error(`Update account service error:`, updateAccountServiceError);
    return {
      status: false,
      error: updateAccountServiceError.message || "Unable to update"
    };
  }
};

export const deleteAccountService = async(adminId: string, accountId: string) => {
  try {
     // 1. Verify the updater is an ADMIN
    const updater = await prisma.admin.findUnique({
      where: { id: adminId }
    });

    if (!updater || updater.role !== 'ADMIN') {
      return {
        status: false,
        error: "Unauthorized"
      };
    }

    // 2. Verify the target account exists
    const accountExists = await prisma.admin.findUnique({
      where: { id: accountId }
    });

    if (!accountExists) {
      return {
        status: false,
        error: "Account does not exist"
      };
    }

    const deleteAccount = await prisma.admin.delete({
      where: { id: accountId}
    });

    if (!deleteAccount) {
      return {
        status: false,
        error: "Unable to delete"
      };
    }

    return {
      status: true
    };
  } catch(deleteAccountServiceError: any) {
    console.error(`Delete account service error ${deleteAccountServiceError}`);
    return {
      status: false,
      error: deleteAccountServiceError.message || "Unable to delete"
    };
  }
};

export const logoutService = async(admin: string, aToken: string, rToken: string) => {
  try {
    return {
      status: true,
      message: "Logged out successfully",
    };
  } catch(logoutServiceError: any) {
    console.error(`Logout service error ${logoutServiceError}`);
    return {
      status: false,
      error: logoutServiceError.message || "Unable to logout"
    }
  }
}
