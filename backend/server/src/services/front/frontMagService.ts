import prisma from "../../config/prismaClient";

export const fetchMagazinesService = async() => {
    try {
        const magazines = await prisma.magazine.findMany();
        if (!magazines) {
            return {
                status:false,
                error: 'Unable to get magazines'
            }
        }

        return {
            status: true,
            mags: magazines
        }
    } catch (fetchMagazinesServiceError: any) {
        console.error(`Fetch magazines service error ${fetchMagazinesServiceError}`);
        return {
            status: false,
            error: fetchMagazinesServiceError
        }
    }
}