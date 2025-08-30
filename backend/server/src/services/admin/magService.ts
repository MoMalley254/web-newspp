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

export const createMagService = async (
  magData: Record<string, any>,
  hasImage: boolean
) => {
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

    console.log(`Publish date ${magData.publishDate}`);

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
        // publishDate: new Date(magData.publishDate),
        publishDate: new Date('2025-08-08'),
        htmlPath: magData.htmlPath,
        credits: magData.credits,
        coverImage: hasImage ? magData.coverImage : null,
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

export const findSingleMagService = async (magId: string) => {
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
  } catch (findSingleMagServiceError: any) {
    console.error(`Find single mag service error ${findSingleMagServiceError}`);
    return {
      status: false,
      error: findSingleMagServiceError.message || "Unable to find magazine",
    };
  }
};

export const updateMagazineService = async (
  magData: Record<string, any>,
  isCredits: boolean
) => {
  try {
    if (isCredits) {
      // 🔧 Handle credits-specific update
      const [, subKey] = magData.field.split(": "); // e.g., 'Graphics'

      // 1. Fetch current credits JSON
      const existing = await prisma.magazine.findUnique({
        where: { id: magData.id },
        select: { credits: true },
      });

      console.log(`Existing item found ${existing}`);

      if (
        !existing ||
        typeof existing.credits !== "object" ||
        existing.credits === null
      ) {
        throw new Error("Credits not found or not valid JSON object");
      }

      // Ensure it's an object
      const existingCredits = existing.credits as Record<string, any>;

      // 2. Modify the subfield
      const updatedCredits = {
        ...existingCredits,
        [subKey]: magData.value,
      };

      // 3. Save it back
      const update = await prisma.magazine.update({
        where: { id: magData.id },
        data: {
          credits: updatedCredits,
        },
      });

      if (!update) {
        return {
          status: false,
          error: 'Unable to update magazine'
        }
      }

      return {
        status: true,
        data: update
      };
    } else {
      let valueToUse = magData.value;

      if (magData.field === "issueNumber") {
        valueToUse = Number(magData.value);
      } else if (magData.field === "publishDate") {
        const date = new Date(magData.value);
        if (!isNaN(date.getTime())) {
          valueToUse = date;
        } else {
          throw new Error("Invalid date format for publishDate");
        }
      }

      const update = await prisma.magazine.update({
        where: { id: magData.id },
        data: {
          [magData.field]: valueToUse,
        },
      });

      if (!update) {
        return {
          status: false,
          error: "Unable to update magazine.",
        };
      }

      return {
        status: true,
        data: update,
      };
    }
  } catch (updateMagazineServiceError: any) {
    console.error(
      `Update magazine service error: ${updateMagazineServiceError}`
    );
    return {
      status: false,
      error: updateMagazineServiceError.message || "Unable to update magazine",
    };
  }
};
