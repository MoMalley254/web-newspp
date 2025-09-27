import prisma from "../../config/prismaClient";

export const saveUserMailService = async(userMail: string) => {
    try {
        const mailExists = await prisma.userMails.findUnique({
            where: { userMail }
        });

        if (mailExists) {
            return {
                status: false,
                error: "Email already exists"
            }
        }

        const saveMail = await prisma.userMails.create(
            {
                data: {
                    userMail: userMail
                }
            }
        );

        if (!saveMail) {
            return {
                status: false,
                error: "Unable to save"
            }
        }

        return {
            status: true
        }
    } catch(saveUserMailServiceError: any) {
        console.error(`Save user mail service error ${saveUserMailServiceError}`);
        return {
            status: false,
            error: saveUserMailServiceError.message || "Unable to save email"
        }
    }
};