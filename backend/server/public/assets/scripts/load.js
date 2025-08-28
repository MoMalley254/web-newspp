const contentBody = document.querySelector(".content-body");
const articlesLoader = document.querySelector(".loading-articles");
const dotsSpan = document.querySelector(".loading-articles .dots");
const foundShower = document.querySelector(".found-articles");

const articlesSection = document.getElementById("articlesSection");

const contentContainer = document.getElementById("contentContainer");
const thumbnailsContainer = document.getElementById("article-thumbnails"); // container for thumbnails
const thumbnailsSideView = document.getElementById("thumbnailsSideView");

const pagesCount = document.querySelector(".page-counts");

const magazineTitle = document.getElementById("magazineTitle");

let dotCount = 0;
let foundArticles = 0;
const baseUrl = `${window.location.origin}/front`;

const isMobile = detectDeviceType();

function detectDeviceType() {
  const ua = navigator.userAgent;

  if (/tablet|ipad|playbook|silk/i.test(ua)) {
    return false;
  }

  if (/Mobile|Android|iPhone|iPod|IEMobile|BlackBerry|Opera Mini/i.test(ua)) {
    return true;
  }

  return false;
}

// Animate loading dots
const dotsInterval = setInterval(() => {
  dotCount = (dotCount + 1) % 4;
  dotsSpan.textContent = ".".repeat(dotCount);
}, 500);

const articlesPath = `/assets/articles`;
getArticles();

async function getArticles() {
  // const allArticles = await fetchPromises();
  const allArticles = await fetchMagazinesFromServer();

  // Stop if all fetches failed
  if (
    !allArticles ||
    !allArticles.status ||
    allArticles.mags.every((item) => item === null)
  ) {
    const errorContainer = document.createElement("div");
    errorContainer.className = "alert alert-danger text-center mt-4 ms-2 me-2";
    errorContainer.role = "alert";
    errorContainer.innerHTML = `
    <strong>Error:</strong> Failed to load magazines. <br> ${allArticles.error}<br> <br> <br>
    <button class="btn btn-danger mt-3" onclick="location.reload()">Reload Page</button>
  `;

    articlesSection.innerHTML = "";
    articlesSection.appendChild(errorContainer);

    clearInterval(dotsInterval);

    if (articlesLoader) articlesLoader.style.display = "none"; // Show content area
    contentBody.style.opacity = "1";
    return;
  }

  // Show content area
  contentBody.style.opacity = "1";

  // Hide loader
  clearInterval(dotsInterval);
  if (articlesLoader) articlesLoader.style.display = "none";

  allArticles.mags.forEach((magazine) => {
    // console.log(` `);
    // console.log(`Mag ${JSON.stringify(magazine)}`);
    // console.log(``);
    // console.log(``);

    const thumb1 = createArticleThumbnail(magazine);
    const thumb2 = createArticleThumbnail(magazine);

    thumbnailsContainer.appendChild(thumb1);
    thumbnailsSideView.appendChild(thumb2);
  });
}

// Create thumbnail element
function createArticleThumbnail(mag) {
  const thumb = document.createElement("div");
  const actualArticleName = mag["title"];
  thumb.className = "article-thumbnail";
  thumb.textContent = actualArticleName;

  // If there's a cover image, set it as background with a white overlay
  if (mag["coverImage"] && mag["coverImage"] !== "") {
    const imageUrl = `${baseUrl}${mag["coverImage"]
      .replace(/\\/g, "/")
      .replace(/\/+/g, "/")}`;
    thumb.style.backgroundImage = `linear-gradient(rgba(255,255,255,0.6), rgba(255,255,255,0.6)), url(${imageUrl})`;
    thumb.style.backgroundSize = "cover";
    thumb.style.backgroundPosition = "center";
    thumb.style.color = "#000"; // Optional: make text readable on light overlay
  }

  thumb.addEventListener("click", () => {
    // showArticleContent(mag, actualArticleName);
    const articleId = mag['id'];
    window.location.href = `/front/view?article=${encodeURIComponent(articleId)}`;
    // window.open(`/front/view?article=${encodeURIComponent(articleId)}`);
    // thumbnailsContainer.style.display = "none";
  });

  return thumb;
}

async function fetchMagazinesFromServer() {
  try {
    const response = await fetch("/front/all");

    if (response.ok) {
      const data = await response.json();
      return {
        status: true,
        mags: data.mags,
      };
    } else {
      const errorData = await response.json();
      throw new Error(errorData.error || "Failed to fetch magazines");
    }
  } catch (error) {
    console.error("Error fetching magazines from server:", error);
    return {
      status: false,
      error: error,
    };
  }
}

async function showArticleContent(magObject, actualArticleName) {
  showThumbnails();
  const loadingArticleContent = document.querySelector(".loading-article-content");
  const articleNameEl = loadingArticleContent.querySelector(".article-name");

  loadingArticleContent.style.display = "block";
  articleNameEl.textContent = actualArticleName;

  try {
    const htmlPath = `front${magObject["htmlPath"].replaceAll("\\", "/")}`;
    const flipbookContainer = await loadAndExtractPages(htmlPath);

    // Remove old flipbook if present
    const oldFlipbook = contentContainer.querySelector("#flipbook");
    if (oldFlipbook) oldFlipbook.remove();

    contentContainer.appendChild(flipbookContainer);

  } catch (error) {
    console.error(error);
    contentContainer.innerHTML = `<p>Unable to load ${actualArticleName}</p>`;
  } finally {
    articleNameEl.textContent = "";
    loadingArticleContent.style.display = "none";
  }
}






