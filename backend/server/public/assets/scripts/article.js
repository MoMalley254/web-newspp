const articlesLoader = document.querySelector(".loader");
const dotsSpan = document.querySelector(".loader .dots");
const flipContainer = document.getElementById("flipContainer");
const thumbNailsContainer = document.getElementById("thumbNailsContainer");

const nextBtns = document.querySelectorAll(".btn-next-page");
const prevBtns = document.querySelectorAll(".btn-prev-page");
const skipBackwardBtns = document.querySelectorAll(".btn-skip-backward");
const skipForwardBtns = document.querySelectorAll(".btn-skip-forward");
const pageCounts = document.querySelector(".page-counts");
const currentPageEl = document.getElementById("current-page");
const totalPagesEl = document.getElementById("total-pages");

const switchPageViewBtn = document.getElementById('switch-btn');
let pageWidth

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

const dotsInterval = setInterval(() => {
  dotCount = (dotCount + 1) % 4;
  dotsSpan.textContent = ".".repeat(dotCount);
}, 500);

switchPageViewBtn.addEventListener('click', () => {

});

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

    const imagePages = data.images.map((image) => {
      const imageUrl = `view${image}`;

      const pageElement = document.createElement("div");
      pageElement.classList.add("page");

      const wrapper = document.createElement("div");
      wrapper.classList.add("image-wrapper");

      const loader = document.createElement("div");
      loader.classList.add("image-loader");

      const img = document.createElement("img");
      img.src = imageUrl;
      img.setAttribute("loading", "lazy");
      img.classList.add("image-hidden");
      img.style.width = "100%";
      img.style.height = "100%";
      img.style.objectFit = "contain";
      img.style.display = "block";

      img.addEventListener("load", () => {
        wrapper.style.backgroundColor = "transparent";
        loader.remove();
        img.classList.remove("image-hidden");
        img.classList.add("image-loaded");
      });

      img.addEventListener("error", () => {
        loader.style.animation = "none";
        loader.textContent = "Failed to load";
        loader.style.border = "none";
        loader.style.color = "red";
      });

      wrapper.appendChild(loader);
      wrapper.appendChild(img);
      pageElement.appendChild(wrapper);
      flipContainer.appendChild(pageElement);

      return {
        html: pageElement,
      };
    });

    showFlipbook(data.images);
  } catch (error) {
    console.error(`Prepare flipbook error: ${error}`);
    showErrorDiv(flipContainer, error.message || "Unknown error");
  } finally {
    articlesLoader.style.display = "none";
  }
}

async function showFlipbook(imageUrls) {
  const flipBook = new St.PageFlip(flipContainer, {
    width: isMobile ? 350 : 450,
    height: isMobile ? 500 : 600,

    size: "fixed",
    minWidth: 315,
    maxWidth: 1000,
    minHeight: 420,
    maxHeight: 1350,
    maxShadowOpacity: 0.7,
    showCover: true,
    mobileScrollSupport: true,
  });

  flipBook.loadFromHTML(document.querySelectorAll(".page"));

  window.flipBookInstance = flipBook;

  buildTableOfContents(flipBook);
  initButtons(flipBook);
  initPageCounter(flipBook);
  populateThumbnails(imageUrls, flipBook);
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

  const current = flipBook.getCurrentPageIndex() + 1;
  currentPageEl.textContent = current.toString();

  flipBook.on("flip", (e) => {
    const pageNum = e.data + 1;

    if (isMobile) {
      currentPageEl.textContent = pageNum.toString();
    } else {
      if (pageNum >= totalPages || pageNum <= 1) {
        currentPageEl.textContent = `${pageNum}`;
      } else if (pageNum > current) {
        currentPageEl.textContent = `${pageNum} - ${pageNum + 1}`;
      } else {
        currentPageEl.textContent = `${pageNum - 1} - ${pageNum}`;
      }
    }
  });

  pageCounts.style.display = "block";
}

function populateThumbnails(images, flipBook) {
  images.forEach((image, index) => {
    const imageUrl = `view${image}`;
    const imageDiv = document.createElement("div");
    imageDiv.classList.add("thumbnail-div");

    imageDiv.addEventListener("click", (e) => {
      flipBook.turnToPage(index);

      const offcanvasEl = document.querySelector("#thumbnailsCanvas");
      const offcanvas = bootstrap.Offcanvas.getInstance(offcanvasEl);
      offcanvas.hide();
    });

    const imageImg = document.createElement("img");
    imageImg.src = imageUrl;
    imageImg.setAttribute("loading", "lazy");
    imageDiv.appendChild(imageImg);

    const imageNumber = document.createElement("span");
    imageNumber.textContent = `${index + 1}`;
    imageDiv.appendChild(imageNumber);
    thumbNailsContainer.appendChild(imageDiv);
  });
}

function buildTableOfContents(flipbook) {
  const showTocsBtn = document.getElementById('showTocsBtn');
  const hasTocs = showTocsBtn?.getAttribute('data-has-tocs');

  if (hasTocs === 'true') {
    const tocsCanvas = document.getElementById('tableOfContentsCanvas');
    const offcanvas = bootstrap.Offcanvas.getOrCreateInstance(tocsCanvas);

    const allTocs = document.querySelectorAll('.toc-entry');

    allTocs.forEach((tocEntry) => {
      const pageEl = tocEntry.querySelector('.tocNumber');
      if (!pageEl) return;

      const tocFirstPage = parseInt(pageEl.textContent, 10);
      if (isNaN(tocFirstPage)) return;

      tocEntry.addEventListener('click', () => {
        flipbook.turnToPage(tocFirstPage);
        offcanvas.hide();
      });
    });

    offcanvas.show();
  }
}

