import prisma from "../../config/prismaClient";

export const getAllMagsService = async() => {
    try {
        const allMagazines = await prisma.magazine.findMany();

        console.log(`Mags found ${allMagazines}`);
        return {
            status: true,
            mags: allMagazines
        };
    } catch(getAllMagsServiceError: any) {
        console.error(`Get all magazines service error ${getAllMagsServiceError}`);
        return {
            status: false,
            error: getAllMagsServiceError
        };
    }
}