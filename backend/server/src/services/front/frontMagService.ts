import prisma from "../../config/prismaClient";

export const fetchMagazinesService = async () => {
  try {
    const magazines = await prisma.magazine.findMany({
      select: {
        id: true,
        title: true,
        coverImage: true,
      },
    });
    if (!magazines) {
      return {
        status: false,
        error: "Unable to get magazines",
      };
    }

    return {
      status: true,
      mags: magazines,
    };
  } catch (fetchMagazinesServiceError: any) {
    console.error(
      `Fetch magazines service error ${fetchMagazinesServiceError}`
    );
    return {
      status: false,
      error: fetchMagazinesServiceError,
    };
  }
};

export const fetchSingleMagazineService = async (magId: string) => {
  try {
    const mag = await prisma.magazine.findUnique({
      where: { id: magId },
      select: {
        id: true,
        title: true,
        issueNumber: true,
        publishDate: true,
        description: true,
        publisher: true,
        htmlPath: true,
        coverImage: true,
        tags: true,
        credits: true,
        hasToc: true,
        links: true
      },
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
    console.error(
      `Fetch single magazine error ${fetchSingleMagazineServiceError}`
    );
    return {
      status: false,
      error: fetchSingleMagazineServiceError.message,
    };
  }
};

export const fetchSingleTagService = async(tagId: string) => {
  try {
    const tagExist = await prisma.tag.findUnique({
      where: { id: tagId}
    }); 

    if (!tagExist) {
      return {
        status: false,
        error: 'Tag not found'
      }
    }

    const magsForTag = await prisma.magazine.findMany({
      where: { 
        tags: {
          some: {
            id: tagId
          }
        }
      }
    });

    return {
      status: true,
      tag: tagExist,
      magazines: magsForTag
    }
  } catch(fetchSingleTagServiceError) {
    console.error(`Fetch single tag service error ${fetchSingleTagServiceError}`);
    return {
      status: false,
      error: fetchSingleTagServiceError
    }
  }
};

export const getTocsService = async(magazineId: string) => {
  try {
    const allTocsForMag = await prisma.tableOfContents.findMany({
      where: { magazineId }
    });

    return {
      status: true,
      tocs: allTocsForMag
    };
  } catch(getTocsServiceError: any) {
    console.error(`Get tocs service error ${getTocsServiceError}`);
    return {
      status: false,
      error: getTocsServiceError.message || "Unable to get contents"
    }
  }
}
