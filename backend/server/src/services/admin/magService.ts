import { DateTime } from "luxon";
import prisma from "../../config/prismaClient";
import { promises as fs } from 'fs';
import path from 'path';

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

    let dateToUse;

    const dateTime = DateTime.fromFormat(
      magData.publishDate,
      "yyyy-MM-dd HH:mm:ss.SSS",
      {
        zone: "Africa/Nairobi",
      }
    );

    if (dateTime.isValid) {
      dateToUse = dateTime.toJSDate(); // Convert to JS Date in UTC
    } else {
      throw new Error("Invalid date format for publishDate");
    }

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
        publishDate: dateToUse,
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
          error: "Unable to update magazine",
        };
      }

      return {
        status: true,
        data: update,
      };
    } else {
      let valueToUse = magData.value;

      if (magData.field === "issueNumber") {
        valueToUse = Number(magData.value);
      } else if (magData.field === "publishDate") {
        const cleanedValue = magData.value.replace(/^Date\s+/, "").trim();

        // Step 2: Parse using Luxon with EAT timezone
        const dateTime = DateTime.fromFormat(
          cleanedValue,
          "yyyy-MM-dd HH:mm:ss.SSS",
          {
            zone: "Africa/Nairobi",
          }
        );

        if (dateTime.isValid) {
          valueToUse = dateTime.toJSDate(); // Convert to JS Date (UTC under the hood)
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

export const deleteMagService = async (magId: string, adminId: string) => {
  try {
    const adminExists = await prisma.admin.findUnique({
      where: { id: adminId },
    });
    if (!adminExists) {
      return {
        status: false,
        error: "Unauthorized",
      };
    }

    const magExists = await prisma.magazine.findUnique({
      where: { id: magId}
    });

    if (!magExists) {
      return {
        status: false,
        error: "Magazine not found"
      };
    }

    const deletedMag = await prisma.magazine.delete({
      where: { id: magId },
    });

    if(!deletedMag) {
      return {
        status: false,
        error: "Unable to delete"
      }
    }

    const deleteMainFiles = await deleteFolder(magExists.htmlPath);
    if (magExists.coverImage !== null) {
      const deleteCoverImage = await deleteFolder(magExists.coverImage);
    }

    return {
      status: true,
      data: deletedMag,
    };
  } catch (deleteMagServiceError: any) {
    console.error(`Delete mag service error ${deleteMagServiceError}`);
    return {
      status: false,
      error: deleteMagServiceError.message || "Unknown error occurred",
    };
  }
};

async function deleteFolder(folderPath: string) {
  try {
    await fs.rm(folderPath, { recursive: true, force: true });
    console.log(`Folder deleted: ${folderPath}`);
    return true;
  } catch (deleteFolderError: any) {
    console.error(`Delete folder error: ${deleteFolderError}`);
    return false;
  }
}
