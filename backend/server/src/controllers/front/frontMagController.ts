import { Request, Response } from "express";
import * as cheerio from "cheerio";
import {
  fetchMagazinesService,
  fetchSingleMagazineService,
  fetchSingleTagService,
  getTocsService,
  getAllTags
} from "../../services/front/frontMagService";
import path from "path";
import { promises as fs } from 'fs';
import { url } from "inspector";


export const renderIndexPage = async (req: Request, res: Response) => {
  const url = req.protocol + '://' + req.get('host')
  const fullUrl = url + req.originalUrl;
  try {
    return res.render("front/front", { url: url, fullUrl: fullUrl});
  } catch (renderIndexPageError: any) {
    console.error(`Render index page error ${renderIndexPageError}`);
    return res
      .status(500)
      .json({ error: renderIndexPageError.message || "Server error", url: url, fullUrl: fullUrl });
  }
};

export const fetchMagazines = async (req: Request, res: Response) => {
  try {
    const getMagazines = await fetchMagazinesService();
    if (!getMagazines.status) {
      return res.status(500).json({ error: getMagazines.error });
    } else {
      return res.status(200).json({ mags: getMagazines.mags });
    }
  } catch (fetchMagazinesError: any) {
    console.error(`Fetch magazines error ${fetchMagazinesError}`);
    return res
      .status(500)
      .json({ error: fetchMagazinesError.message || "Server error" });
  }
};

export const renderSingleMagazine = async (req: Request, res: Response) => {
  const url = req.protocol + '://' + req.get('host')
  const fullUrl = url + req.originalUrl;
  try {
    const magId: string = req.query.article as string;
    if (!magId || magId === "") {
      return res
        .status(400)
        .render("front/article", { status: false, error: "Unable to load -- please retry" });
    }
    const getMagazine = await fetchSingleMagazineService(magId);
    if (!getMagazine.status) {
      return res
        .status(500)
        .render("front/article", { status: false, error: getMagazine.error });
    }

    const magazine = getMagazine.magData;
    const magazinePath = magazine?.htmlPath;
    if (!magazinePath || magazinePath === "") {
      return res.status(500).render("front/article", {
        status: false,
        error: `Could not find content for "${magazine?.title || "Unknown"}".`,
      });
    }

    let tocs: any[] = [];
    if (magazine.hasToc) {
      const getTocs = await getTocsService(magazine.id);
      if (getTocs.status && Array.isArray(getTocs.tocs)) {
        tocs = getTocs.tocs;
      }
    }

    return res.status(200).render("front/article", { mag: magazine, status: true, tocs: tocs, url: url, fullUrl: fullUrl });
  } catch (renderSingleMagazineError: unknown) {
    const errorMessage =
      renderSingleMagazineError instanceof Error
        ? renderSingleMagazineError.message
        : "An unknown error occurred";

    return res.status(500).render("front/article", { status: false, error: errorMessage, url: url, fullUrl: fullUrl });
  }
};

export const returnImageUrls = async (req: Request, res: Response) => {
  try {
    const { path: basePath } = req.body;
    const index = parseInt(req.query.index as string, 10);
    const pagesPerChunk = parseInt(req.query.pages as string, 10);

    if (!basePath || isNaN(index) || isNaN(pagesPerChunk)) {
      return res.status(400).json({ error: 'Invalid path, index, or pages query.' });
    }

    // Generate chunked image URLs
    const start = index * pagesPerChunk;
    const end = start + pagesPerChunk;

    const absoluteImagePath = path.join(__dirname, '../../../', basePath);
    const allFiles = await fs.readdir(absoluteImagePath);
    if (allFiles.length < 1) {
      return res.status(500).json({ error: 'No content found' });
    }
    const imageFiles = allFiles.filter(file =>
      /\.(jpg|jpeg|png|gif|webp)$/i.test(file)
    );

    imageFiles.sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));

    // const currentChunk = imageFiles.slice(start, end);
    // const remainingChunk = imageFiles.slice(end);

    // const imageUrls = currentChunk.map(filename =>
    //   path.posix.join(basePath, filename)
    // );

    const imageUrls = imageFiles.map(filename =>
      path.posix.join(basePath, filename)
    );

    // const remainingImages = remainingChunk.map(filename =>
    //   path.posix.join(basePath, filename)
    // );

    // return res.status(200).json({ images: imageUrls, hasMore: remainingImages.length > 0, remaining: remainingImages });
    return res.status(200).json({ images: imageUrls });
  } catch (returnImageUrlsError) {
    console.error(`Return image urls error ${returnImageUrlsError}`);
    return res.status(500).json({ error: 'Failed to generate image URLs' });
  }
};

export const renderGroupedPage = async(req: Request, res: Response) => {
  const url = req.protocol + '://' + req.get('host')
  const fullUrl = url + req.originalUrl;
  try {
    const tagId = req.query.tag as string;
    if (!tagId || tagId === '') {
      return res
      .status(400)
      .json({ error: "Tag not available" });
    }

    const getMags = await fetchSingleTagService(tagId);
    if (getMags.status) {
      return res.render("front/grouped", { status: true, tag: getMags.tag, mags: getMags.magazines, url: url, fullUrl: fullUrl});
      // return res.render("front/grouped", { error: 'Felt like it'});
    } else {
      return res.render("front/grouped", { status: false, error: getMags.error, url: url, fullUrl: fullUrl});
    }
  } catch(renderGroupedPageError: any) {
    console.error(`Render grouped page error ${renderGroupedPageError}`);
    return res.render("front/grouped", { status: false, error: renderGroupedPageError.message || "Server error", url: url, fullUrl: fullUrl});
  }
}

export const renderTagsPage = async(req: Request, res: Response) => {
  const url = req.protocol + '://' + req.get('host')
  const fullUrl = url + req.originalUrl;
  try {
    const allTags = await getAllTags();
    if (!allTags.status) {
      return res.render("front/tags", { status: false, error: allTags.error, url: url, fullUrl: fullUrl})
    } else {
      return res.render("front/tags", { status: true, tags: allTags.tags, url: url, fullUrl: fullUrl });
    }
  } catch(renderTagsPageError: any) {
    console.error(`Render tags page error ${renderTagsPageError}`);
    return res.render("front/tags", { status: false, error: renderTagsPageError.message || "Server error", url: url, fullUrl: fullUrl});
  }
};


