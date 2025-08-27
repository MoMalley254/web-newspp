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

  const htmlUrl = `${baseUrl}${mag["htmlPath"]
  .replace(/\\/g, "/")
  .replace(/\/+/g, "/")}`;

  thumb.addEventListener("click", () => {
    // showArticleContent(mag, actualArticleName);
    const articleId = mag['id'];
    window.location.href = `/front/view?article=${encodeURIComponent(articleId)}`;
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

// async function showArticleContent(magObject, actualArticleName) {
//   // Show thumbnails section and loader
//   showThumbnails();
//   const loadingArticleContent = document.querySelector(".loading-article-content");
//   const articleNameEl = loadingArticleContent.querySelector(".article-name");

//   loadingArticleContent.style.display = "block";
//   articleNameEl.textContent = actualArticleName;

//   const articleContainer = document.createElement("div");
//   articleContainer.id = "flipbook";

//   try {
//     removeOldScript(); // remove any previously loaded flip.js or similar

//     const htmlPath = `front${magObject["htmlPath"].replaceAll('\\', '/')}`;
//     const getHtml = await fetchHtml(htmlPath);

//     if (!getHtml.status) {
//       throw new Error(`Failed to fetch HTML for ${actualArticleName}`);
//     }

//   } catch (error) {
//     console.error(error);
//     articleContainer.innerHTML = `<p>Unable to extract ${actualArticleName} content.</p>`;
//   } finally {
//     // Hide loading UI
//     articleNameEl.textContent = "";
//     loadingArticleContent.style.display = "none";

//     // Replace existing flipbook if present
//     const oldFlipbook = contentContainer.querySelector("#flipbook");
//     if (oldFlipbook) oldFlipbook.remove();

//     contentContainer.appendChild(articleContainer);
//     thumbnailsSideView.style.display = "flex";
//     magazineTitle.textContent = actualArticleName;
//     pagesCount.style.display = "block";

//     // Load flip.js
//     loadFlipScript().then(() => {
//       console.log("✅ flip.js loaded");
//     });
//   }
// }

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

    // Initialize Turn.js here
    // $('#flipbook').turn({
    //   width: 800,
    //   height: 600,
    //   autoCenter: true,
    //   // ... your other Turn.js options
    // });

  } catch (error) {
    console.error(error);
    contentContainer.innerHTML = `<p>Unable to load ${actualArticleName}</p>`;
  } finally {
    articleNameEl.textContent = "";
    loadingArticleContent.style.display = "none";
  }
}


function loadAndExtractPages(htmlUrl) {
  return new Promise((resolve, reject) => {
    const iframe = document.createElement('iframe');
    iframe.style.position = 'fixed'; // or hidden however you want
    iframe.style.left = '-9999px'; // hide offscreen
    iframe.style.width = '80vw';  
    iframe.style.height = '75vh';
    iframe.src = htmlUrl;

    document.body.appendChild(iframe);

    iframe.onload = () => {
      try {
        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;

        // Extract styles from iframe head
        const styles = iframeDoc.querySelectorAll('style');
        styles.forEach(style => {
          document.head.appendChild(style.cloneNode(true));
        });

        // Extract page divs
        const pages = iframeDoc.querySelectorAll('div[id^="pf"]'); // adjust selector if needed

        if (pages.length === 0) {
          reject('No pages found in iframe document');
          return;
        }

        console.log(`Pages found ${pages.length}`);

        // Create container for pages in main document
        const container = document.createElement('div');
        container.id = 'toFlip';

        pages.forEach(pageDiv => {
          const page = document.createElement('div');
          page.classList.add('page');
          page.innerHTML = pageDiv.innerHTML;
          container.appendChild(page);
        });

        // Clean up iframe after extraction
        iframe.remove();

        resolve(container);

      } catch (error) {
        iframe.remove();
        reject(error);
      }
    };

    iframe.onerror = (err) => {
      iframe.remove();
      reject('Failed to load iframe: ' + err);
    };
  });
}



async function fetchHtml(htmlUrl) {
  console.log(`Page URL: ${htmlUrl}`);
  try {
    const response = await fetch(htmlUrl, {
      headers: {
        'Accept': 'text/html'
      }
    });

    if (response.ok) {
      const htmlContent = await response.text();  

      return {
        status: true,
        file: htmlContent,  
      };
    } else {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
  } catch (error) {
    console.error(`❌ Error fetching HTML: ${htmlUrl}`, error);
    return {
      status: false,
      error: error,
    };
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
    script.src = "/front/public/assets/scripts/flip.js";
    script.id = "flipJsFile";
    script.onload = () => {
      console.log("✅ flip.js loaded");
      initTurnjs(); // Call function after it's loaded
    };
    script.onerror = reject;
    document.body.appendChild(script);
  });
}
