const contentBody = document.querySelector(".content-body");
const articlesLoader = document.querySelector(".loading-articles");
const dotsSpan = document.querySelector(".loading-articles .dots");
const foundShower = document.querySelector(".found-articles");

const articlesSection = document.getElementById("articlesSection");
const articleNames = articlesSection.dataset.articleNames
  .split(",")
  .map((name) => name.trim());

const contentContainer = document.getElementById("contentContainer");
const thumbnailsContainer = document.getElementById("article-thumbnails"); // container for thumbnails
const thumbnailsSideView = document.getElementById("thumbnailsSideView");

const pagesCount = document.querySelector(".page-counts");

const magazineTitle = document.getElementById("magazineTitle");

let dotCount = 0;
let foundArticles = 0;
const baseUrl = window.location;

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
  if (mag['coverImage'] && mag['coverImage'] !== '') {
    const imageUrl = `${baseUrl}${mag['coverImage'].replace(/\\/g, '/').replace(/\/+/g, '/')}`;

    console.log(`Image ${imageUrl}`);
    thumb.style.backgroundImage = `linear-gradient(rgba(255,255,255,0.6), rgba(255,255,255,0.6)), url(${imageUrl})`;
    thumb.style.backgroundSize = "cover";
    thumb.style.backgroundPosition = "center";
    thumb.style.color = "#000"; // Optional: make text readable on light overlay
  }

  thumb.addEventListener("click", () => {
    showArticleContent(mag, actualArticleName);
    thumbnailsContainer.style.display = "none";
  });

  return thumb;
}


async function fetchMagazinesFromServer() {
  try {
    const response = await fetch("/front/all");

    // Check if the response status is OK (status code 200–299)
    if (response.ok) {
      const data = await response.json();
      console.log(`Mags found ${JSON.stringify(data)}`);
      // Successfully got results
      return {
        status: true,
        mags: data.mags,
      };
    } else {
      // Attempt to extract error message from response
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

// async function fetchPromises() {
//   return await Promise.all(
//     articleNames.map(async (article) => {
//       const url = `${articlesPath}/${encodeURIComponent(article)}`;
//       console.log('Fetching:', url);

//       try {
//         const response = await fetch(url);
//         if (!response.ok) throw new Error(`File not found: ${article}`);

//         foundArticles++;
//         console.log(`Found: ${article} (Total found: ${foundArticles})`);

//         if (foundShower) {
//           foundShower.style.opacity = '1';
//           const countElem = foundShower.querySelector('.article-count');
//           if (countElem) countElem.textContent = foundArticles;
//         }

//         const html = await response.text();
//         return { html, article };
//       } catch (error) {
//         console.error(error.message);
//         return null;
//       }
//     })
//   );
// }

function showArticleContent(articleHTML, actualArticleName) {
  showThumbnails();
  const loadingArticleContent = document.querySelector(
    ".loading-article-content"
  );
  loadingArticleContent.style.display = "block";
  loadingArticleContent.querySelector(".article-name").textContent =
    actualArticleName;

  const articleContainer = document.createElement("div");
  articleContainer.id = "flipbook";

  try {
    removeOldScript();

    const parser = new DOMParser();
    const doc = parser.parseFromString(articleHTML, "text/html");
    const pageContent = doc.body;

    if (pageContent) {
      // Insert content asynchronously to let browser update the UI (show loader)
      setTimeout(() => {
        const pagesContainer = pageContent.querySelector("#page-container");
        if (!pagesContainer) {
          throw new error("No Pages found in the article");
        }

        const articlePages = pagesContainer.querySelectorAll('div[id^="pf"]');
        console.log(`Images found ${articlePages.length}`);
        if (articlePages < 1) {
          throw new error("No Pages found in the article");
        }

        articlePages.forEach((page) => {
          const newPage = document.createElement("div");
          // newPage.classList.add('article-page');

          const newPageImg = document.createElement("img");
          // newPageImg.classList.add('article-page-img');
          newPageImg.src = page.querySelector("img").src;
          newPage.appendChild(newPageImg);

          articleContainer.appendChild(newPage);
        });

        // articleContainer.innerHTML = pageContent.innerHTML;

        // Hide loader after content inserted
        loadingArticleContent.querySelector(".article-name").textContent = "";
        loadingArticleContent.style.display = "none";
      }, 0);
    } else {
      articleContainer.innerHTML = `<p>Unable to extract ${actualArticleName} content.</p>`;
      loadingArticleContent.querySelector(".article-name").textContent = "";
      loadingArticleContent.style.display = "none";
    }
  } catch (error) {
    articleContainer.innerHTML = `<p>Unable to extract ${actualArticleName} content.</p>`;
    loadingArticleContent.querySelector(".article-name").textContent = "";
    loadingArticleContent.style.display = "none";
  } finally {
    if (contentContainer.querySelector("#flipbook")) {
      contentContainer.querySelector("#flipbook").remove();
    }

    contentContainer.appendChild(articleContainer);
    thumbnailsSideView.style.display = "flex";
    magazineTitle.textContent = actualArticleName;
    pagesCount.style.display = "block";

    //Load flip.js
    loadFlipScript().then(() => {
      console.log("✅ flip.js loaded");
    });
  }
}

function removeOldScript() {
  return new Promise((resolve, reject) => {
    const oldScript = document.getElementById("flipJsFile");
    if (oldScript) {
      oldScript.remove(); // ✅ Cleanly removes the script tag from DOM
      console.log("🗑️ flip.js removed from DOM");
    }
  });
}

function loadFlipScript() {
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "./scripts/flip.js";
    script.id = "flipJsFile";
    script.onload = () => {
      console.log("✅ flip.js loaded");
      initTurnjs(); // Call function after it's loaded
    };
    script.onerror = reject;
    document.body.appendChild(script);
  });
}
