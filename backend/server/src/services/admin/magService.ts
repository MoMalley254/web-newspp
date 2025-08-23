import prisma from "../../config/prismaClient";

export const getAllMagsService = async () => {
  try {
    const allMagazines = await prisma.magazine.findMany();

    console.log(`Mags found ${allMagazines}`);
    return {
      status: true,
      mags: allMagazines,
    };
  } catch (getAllMagsServiceError: any) {
    console.error(`Get all magazines service error ${getAllMagsServiceError}`);
    return {
      status: false,
      error: getAllMagsServiceError,
    };
  }
};

async function createTags(
  magTags: string
): Promise<{ status: boolean; tagIds?: string[]; error?: any }> {
  try {
    const tagNames = magTags
      .split(",")
      .map((tag) => tag.trim().toLowerCase())
      .filter((tag) => tag.length > 0); // Remove empty strings

    const tagIds: string[] = [];

    for (const tagName of tagNames) {
      // Try to find an existing tag
      let tag = await prisma.tag.findUnique({
        where: { name: tagName },
      });

      // If not found, create it
      if (!tag) {
        tag = await prisma.tag.create({
          data: { name: tagName },
        });
      }

      tagIds.push(tag.id);
    }

    return {
      status: true,
      tagIds,
    };
  } catch (createTagsError) {
    console.error(`❌ Create tags error:`, createTagsError);
    return {
      status: false,
      error: createTagsError,
    };
  }
}

export const createMagService = async (magData: Record<string, any>, hasImage: boolean) => {
  try {

    console.log(`Mag data ${JSON.stringify(magData)}`);
    // Create or get tags
    const tagsResult = await createTags(magData["tags"] as string);
    if (!tagsResult.status) {
      return {
        status: false,
        error: tagsResult.error,
      };
    }

    console.log(`Created tags ${tagsResult.tagIds}`);

    // Create the Magazine
    const magazine = await prisma.magazine.create({
      data: {
        title: magData.title,
        description: magData.description ?? null,
        publisher: magData.publisher ?? null,
        adminId: magData.adminId, // You must pass this in magData

        tags: {
          connect: tagsResult.tagIds!.map((id) => ({ id })),
        },
        issueNumber: magData.issueNumber,
        publishDate: new Date(magData.publishDate),
        htmlPath: magData.htmlPath,
        credits: magData.credits,
        coverImage: hasImage ? magData.coverImage : null
      },
    });

    console.log(`Magazine created with id: ${magazine.id}`);

    return {
      status: true,
      magazineId: magazine.id,
    };
  } catch (createMagServiceError: any) {
    console.error(`Create mag service error ${createMagServiceError}`);
    return {
      status: false,
      error: createMagServiceError,
    };
  }
};
