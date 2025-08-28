import prisma from "../../config/prismaClient";

export const fetchMagazinesService = async() => {
    try {
        const magazines = await prisma.magazine.findMany({
            select: { 
                id: true,
                title: true,
                coverImage: true
            }
        });
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

export const fetchSingleMagazineService = async(magId: string) => {
    try {
        const mag = await prisma.magazine.findUnique({
              where: { id: magId },
            });
        
            if (!mag) {
              return {
                status: false,
                error: "Magazine does not exist",
              };
            }
        
            return {
              status: true,
              magData: mag,
            };
    } catch (fetchSingleMagazineServiceError: any) {
        console.error(`Fetch single magazine error ${fetchSingleMagazineServiceError}`);
        return {
            status: false,
            error: fetchSingleMagazineServiceError.message
        }
    }
}