const articlesLoader = document.querySelector(".loader");
const dotsSpan = document.querySelector(".loader .dots");
const flipContainer = document.getElementById("flipContainer");

const nextBtns = document.querySelectorAll(".btn-next-page");
const prevBtns = document.querySelectorAll(".btn-prev-page");
const skipBackwardBtns = document.querySelectorAll(".btn-skip-backward");
const skipForwardBtns = document.querySelectorAll(".btn-skip-forward");
const pageCounts = document.querySelector(".page-counts");
const currentPageEl = document.getElementById("current-page");
const totalPagesEl = document.getElementById("total-pages");

let dotCount = 0;
const isMobile = detectDeviceType();

let index = 0;
let pagesPerChunk = 5;

document.addEventListener("DOMContentLoaded", async function () {
  prepareFlipBook();
});

function showErrorDiv(parentContainer, errorMessage) {
  const div = document.createElement("div");
  div.innerHTML = `
        <div
          class="alert alert-danger d-flex flex-column justify-content-center align-items-center m-4"
          role="alert"
        >
          <div class="text-center">
            <strong>Error:</strong> <br />
            ${errorMessage}
          </div>  <br/> 
          <div>
            <button
              class="btn btn-outline-success btn-sm me-2"
              onclick="location.reload()"
            >
              Reload
            </button>
          </div>
        </div>
    `;
  // Clear the parent container and append the new div
  parentContainer.innerHTML = "";
  parentContainer.appendChild(div.firstElementChild);
}

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
async function prepareFlipBook() {
  try {
    const resourceUrl = flipContainer.getAttribute("data-resource-url");
    console.log(`Resource URL: ${resourceUrl}`);

    if (!resourceUrl || resourceUrl.trim() === "") {
      showErrorDiv(flipContainer, "Unable to get content. Please refresh.");
      return;
    }

    const fullPath = `/front/view/images?index=${index}&pages=${pagesPerChunk}`;

    const response = await fetch(fullPath, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        path: resourceUrl,
      }),
    });

    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }

    const data = await response.json();

    if (
      !data.images ||
      !Array.isArray(data.images) ||
      data.images.length === 0
    ) {
      throw new Error("No images found in response.");
    }

    // const imageUrls = data.images.map((image) => `view${image}`);
    // showFlipbook(imageUrls, data.hasMore, data.remaining);

    const imagePages = data.images.map((image) => {
      const imageUrl = `view${image}`;

      // Create an actual DOM element
      const pageElement = document.createElement("div");
      pageElement.classList.add("page");

      const img = document.createElement("img");
      img.src = imageUrl;
      img.style.width = "100%";
      img.style.height = "100%";
      img.style.objectFit = "contain";
      img.style.display = "block";

      pageElement.appendChild(img);
      flipContainer.appendChild(pageElement);

      return {
        html: pageElement, // ✅ Must be a real DOM Node
      };
    });

    showFlipbook(imagePages);
  } catch (error) {
    console.error(`Prepare flipbook error: ${error}`);
    showErrorDiv(flipContainer, error.message || "Unknown error");
  } finally {
    articlesLoader.style.display = "none";
  }
}

// async function showFlipbook(imageUrls, hasMore, moreImages = []) {
async function showFlipbook(imageUrls) {
  const flipBook = new St.PageFlip(flipContainer, {
    // width: isMobile ? flipContainer.clientWidth :  flipContainer.clientWidth / 2,
    // height: flipContainer.clientHeight,
    // size: "fixed",
    // minWidth: 300,
    // minHeight: 400,
    // maxWidth: 2000,
    // maxHeight: 3000,
    width: 500, // base page width
    height: 700, // base page height

    size: "fixed",
    // set threshold values:
    minWidth: 315,
    maxWidth: 1000,
    minHeight: 420,
    maxHeight: 1350,
    maxShadowOpacity: 0.5,
    showCover: true,
    mobileScrollSupport: true,
  });

  // Load the initial chunk
  // flipBook.loadFromImages(imageUrls);
  flipBook.loadFromHTML(document.querySelectorAll('.page'));

  // Keep track of remaining images
  //   let remainingImages = [...moreImages];
  //   let isLoading = false; // Prevent duplicate loads

  // Add listener to load more pages when near the end
  //   flipBook.on("flip", async (e) => {
  //     const totalPages = flipBook.getPageCount();
  //     const currentPage = e.data;

  //     // If user is on the last or second-last page, load more
  //     if (
  //       hasMore &&
  //       !isLoading &&
  //       remainingImages.length > 0 &&
  //       currentPage >= totalPages - 2
  //     ) {
  //       isLoading = true;

  //       const nextChunk = remainingImages.splice(0, 5); // Load next 5 pages
  //       for (let img of nextChunk) {
  //         const cleanLink = `view${img}`;
  //         console.log(`Img ${img}`);
  //         console.log(`Cleaned ${cleanLink}`);
  //         flipBook.loadFromImages(cleanLink);
  //       }

  //       // If nothing left, stop future loading
  //       if (remainingImages.length === 0) {
  //         hasMore = false;
  //       }

  //       isLoading = false;
  //     }
  //   });

  // Store for global access if needed
  window.flipBookInstance = flipBook;

  initButtons(flipBook);
  initPageCounter(flipBook);
}

function initButtons(flipBook) {
  document.addEventListener("keydown", (e) => {
    if (!flipBook) return;

    switch (e.key) {
      case "ArrowLeft":
        e.preventDefault();
        flipBook.flipPrev();
        break;
      case "ArrowRight":
        e.preventDefault();
        flipBook.flipNext();
        break;
    }
  });

  nextBtns.forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      if (flipBook) {
        flipBook.flipNext();
      }
    });
  });

  prevBtns.forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      if (flipBook) {
        flipBook.flipPrev();
      }
    });
  });

  skipBackwardBtns.forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      if (flipBook) {
        const currentPage = flipBook.getCurrentPageIndex();
        const targetPage = Math.max(0, currentPage - 3);
        flipBook.flip(targetPage);
      }
    });
  });

  skipForwardBtns.forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      if (flipBook) {
        const currentPage = flipBook.getCurrentPageIndex();
        const maxPage = flipBook.getPageCount() - 1;
        const targetPage = Math.min(maxPage, currentPage + 3);
        flipBook.flip(targetPage);
      }
    });
  });
}

function initPageCounter(flipBook) {
  const totalPages = flipBook.getPageCount();
  totalPagesEl.textContent = totalPages.toString();

  // Set initial current page
  const current = flipBook.getCurrentPageIndex() + 1; 
  currentPageEl.textContent = current.toString();

  // Listen for page changes
  flipBook.on("flip", (e) => {
    const pageNum = e.data + 1;
    currentPageEl.textContent = pageNum.toString();
  });

  pageCounts.style.display = "block";
}
