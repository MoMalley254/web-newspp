import { Request, Response } from "express";
import * as cheerio from "cheerio";
import {
  fetchMagazinesService,
  fetchSingleMagazineService,
} from "../../services/front/frontMagService";
import path from "path";
import fs from "fs";
import readline from "readline";

export const renderIndexPage = async (req: Request, res: Response) => {
  try {
    return res.render("front/front");
  } catch (renderIndexPageError: any) {
    console.error(`Render index page error ${renderIndexPageError}`);
    return res
      .status(500)
      .json({ error: renderIndexPageError.message || "Server error" });
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
  try {
    const magId: string = req.query.article as string;
    if (!magId || magId === "") {
      return res
        .status(400)
        .render("front/article", { error: "Unable to load -- please retry" });
    }
    const getMagazine = await fetchSingleMagazineService(magId);
    if (!getMagazine.status) {
      return res
        .status(500)
        .render("front/article", { error: getMagazine.error });
    }

    const magazine = getMagazine.magData;
    const magazinePath = magazine?.htmlPath;
    if (!magazinePath || magazinePath === "") {
      return res.status(500).render("front/article", {
        error: `Could not find content for "${magazine?.title || "Unknown"}".`,
      });
    }

    return res.status(200).render("front/article", { error: 'Felt like it' });
  } catch (renderSingleMagazineError: unknown) {
    const errorMessage =
      renderSingleMagazineError instanceof Error
        ? renderSingleMagazineError.message
        : "An unknown error occurred";

    return res.status(500).render("front/article", { error: errorMessage });
  }
};

// ➕ Helper to clean and adjust #page-container CSS
function processCssBlock(lines: string[]): string {
  let cleaned = [...lines];

  // Flags for replacement case
  const hasBackgroundColor = cleaned.some((l) =>
    l.includes("background-color: #9e9e9e")
  );
  const hasBackgroundImage = cleaned.some((l) =>
    l.includes("background-image: url(data:image/svg+xml;base64")
  );

  if (hasBackgroundColor && hasBackgroundImage) {
    // Remove both original lines
    cleaned = cleaned.filter(
      (l) =>
        !l.includes("background-color: #9e9e9e") &&
        !l.includes("background-image: url(data:image/svg+xml;base64")
    );

    // Insert new background line before closing }
    const lastIndex = cleaned.findIndex((l) => l.trim().endsWith("}"));
    if (lastIndex !== -1) {
      cleaned.splice(
        lastIndex,
        0,
        "  background: linear-gradient(to bottom right, #232370, #4f0a8c);"
      );
    }

    return cleaned.join("\n");
  }

  // Handle #page-container overflow cleanup as before
  const isPageContainer = cleaned[0]?.trim().startsWith("#page-container");

  if (isPageContainer) {
    cleaned = cleaned.filter((l) => !l.includes("overflow: auto"));

    const hasOverflowX = cleaned.some((l) => l.includes("overflow-x"));
    if (!hasOverflowX) {
      const idx = cleaned.findIndex((l) => l.trim().endsWith("}"));
      if (idx !== -1) {
        cleaned.splice(idx, 0, "  overflow-x: hidden;");
      }
    }
  }

  return cleaned.join("\n");
}
