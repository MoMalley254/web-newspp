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

async function createAuthors(authors: string): Promise<{ status: boolean; authorIds?: string[]; error?: any }> {
  try {
    const authorNames = authors
      .split(",")
      .map((author) => author.trim().toLowerCase())
      .filter((author) => author.length > 0);

    const authorIds: string[] = [];

    for (const authorName of authorNames) {
      const author = await prisma.author.findFirst({
        where: { name: authorName },
      });

      if (author) {
        authorIds.push(author.id);
      }
      // If author not found, skip (do NOT create new author)
    }

    return {
      status: true,
      authorIds,
    };
  } catch (createAuthorsError: any) {
    console.error(`Create authors error:`, createAuthorsError);
    return {
      status: false,
      error: createAuthorsError,
    };
  }
}


export const createMagService = async (magData: Record<string, any>) => {
  try {
    // Create or get tags
    const tagsResult = await createTags(magData["tags"] as string);
    if (!tagsResult.status) {
      return {
        status: false,
        error: tagsResult.error,
      };
    }

    console.log(`Created tags ${tagsResult.tagIds}`);

    // Get authors (only existing ones per your logic)
    const authorsResult = await createAuthors(magData["author"] as string);
    if (!authorsResult.status) {
      return {
        status: false,
        error: authorsResult.error,
      };
    }

    console.log(`Authors found ${authorsResult.authorIds}`);

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

        authors: {
          connect: authorsResult.authorIds!.map((id) => ({ id })),
        },
      },
    });

    console.log(`Magazine created with id: ${magazine.id}`);

    // Create the initial Magazine Issue
    const issue = await prisma.magazineIssues.create({
      data: {
        title: magData.issueTitle ?? magData.title,
        issueNumber: magData.issueNumber ?? 1, // default to 1 if not provided
        publishDate: magData.publishDate ? new Date(magData.publishDate) : undefined,
        htmlPath: magData.htmlPath,

        magazineId: magazine.id,

        tags: {
          connect: tagsResult.tagIds!.map((id) => ({ id })),
        },
      },
    });

    console.log(`Magazine issue created with id: ${issue.id}`);

    return {
      status: true,
      magazineId: magazine.id,
      issueId: issue.id,
    };
  } catch (createMagServiceError: any) {
    console.error(`Create mag service error ${createMagServiceError}`);
    return {
      status: false,
      error: createMagServiceError,
    };
  }
};
