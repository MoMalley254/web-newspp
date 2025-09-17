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

const switchPageViewBtn = document.getElementById("switch-btn");
let pageWidth;

const zoomWrapper = document.getElementById("zoomWrapper");
const zoomInBtn = document.getElementById("btn-zoom-in");
const zoomOutBtn = document.getElementById("btn-zoom-out");
const zoomSlider = document.getElementById("zoomSlider");

const switchViewBtn = document.getElementById("switchViewBtn");
let isSingleView = false;
let isStretched = false;

const fullScreenBtn = document.getElementById("btn-fullscreen");
const fullScreenContent = document.querySelector(".content-body");

let dotCount = 0;
const isMobile = detectDeviceType();
const isLaptop = checkScreenSize();

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

function checkScreenSize() {
  const width = window.innerWidth;
  return width >= 1024 && width < 1920;
}

const dotsInterval = setInterval(() => {
  dotCount = (dotCount + 1) % 4;
  dotsSpan.textContent = ".".repeat(dotCount);
}, 500);

// switchPageViewBtn.addEventListener('click', () => {

// });

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

      // if (isMobile) adjustMarginToAvoidOverlap(img);
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
    width: isMobile ? 340 : isLaptop ? 450 : 650,
    height: isMobile ? 700 : isLaptop ? 650 : 850,

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

  flipContainer.style.width = "100vw";

  buildTableOfContents(flipBook);
  initButtons(flipBook);
  initView(flipBook);
  // populateThumbnails(imageUrls, flipBook);
  initZoom(flipBook);
  initStretch(flipBook);
  if (!isMobile && !isLaptop) {
    updateScreenSize(flipBook);
  }
  allowMoveHelpBtn();
  makeDraggable(flipContainer);
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

  fullScreenBtn.addEventListener("click", (e) => {
    if (fullScreenBtn.getAttribute("aria-label") === "Full Screen") {
      if (fullScreenContent.requestFullscreen) {
        fullScreenContent.requestFullscreen();
      } else if (fullScreenContent.webkitRequestFullscreen) {
        // Safari
        fullScreenContent.webkitRequestFullscreen();
      } else if (fullScreenContent.msRequestFullscreen) {
        // IE11
        fullScreenContent.msRequestFullscreen();
      }

      // enlargeContent(true, flipBook);
      fullScreenBtn.innerHTML = `<i class="material-icons">fullscreen_exit</i>`;
      fullScreenBtn.setAttribute("aria-label", "Exit Full Screen");
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if (document.webkitExitFullscreen) {
        // Safari
        document.webkitExitFullscreen();
      } else if (document.msExitFullscreen) {
        // IE11
        document.msExitFullscreen();
      }

      // enlargeContent(false, flipBook);
      fullScreenBtn.innerHTML = `<i class="material-icons">fullscreen</i>`;
      fullScreenBtn.setAttribute("aria-label", "Full Screen");
    }
  });

  document.addEventListener("fullscreenchange", () => {
    if (!document.fullscreenElement) {
      // enlargeContent(false, flipBook);
      fullScreenBtn.innerHTML = `<i class="material-icons">fullscreen</i>`;
      fullScreenBtn.setAttribute("aria-label", "Full Screen");
    }
  });
}

function initPageCounter(flipBook) {
  pageCounts.style.display = "none";
  const totalPages = flipBook.getPageCount();
  totalPagesEl.textContent = totalPages.toString();

  const current = flipBook.getCurrentPageIndex() + 1;
  currentPageEl.textContent = current.toString();

  flipBook.on("flip", (e) => {
    const pageNum = e.data + 1;

    if (isMobile) {
      currentPageEl.textContent = pageNum.toString();
    } else if (isSingleView) {
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
  const showTocsBtns = document.querySelectorAll(".showTocsBtn");
  if (showTocsBtns.length > 0) {
    showTocsBtns.forEach((btn) => {
      const hasTocs = btn?.getAttribute("data-has-tocs");

      if (hasTocs === "true") {
        const tocsCanvas = document.getElementById("tableOfContentsCanvas");
        const offcanvas = bootstrap.Offcanvas.getOrCreateInstance(tocsCanvas);

        const allTocs = document.querySelectorAll(".toc-entry");

        allTocs.forEach((tocEntry) => {
          const pageEl = tocEntry.querySelector(".tocNumber");
          if (!pageEl) return;

          const tocFirstPage = parseInt(pageEl.textContent, 10);
          if (isNaN(tocFirstPage)) return;

          tocEntry.addEventListener("click", () => {
            flipbook.turnToPage(tocFirstPage);
            offcanvas.hide();
          });
        });

        offcanvas.show();
      }
    });
  }
}

function initZoom(flipBook) {
  let currentScale = 1;
  let translateX = 0;
  let translateY = 0;
  const scaleStep = 0.1;
  const maxScale = 3;
  const minScale = 1;
  const flipBookHeight = flipContainer.offsetHeight;
  const flipBookWidth = flipContainer.offsetWidth;

  // Create and setup overlay once
  const overlay = document.createElement("div");
  overlay.style.position = "fixed";
  overlay.style.top = 0;
  overlay.style.left = 0;
  overlay.style.width = "100vw";
  overlay.style.height = isMobile ? "72vh" : "85vh";
  overlay.style.marginTop = isMobile ? "9vh" : "10vh";
  overlay.style.zIndex = 9999;
  overlay.style.background = "transparent";
  // overlay.style.background = 'blue';
  overlay.style.display = "none";
  document.body.appendChild(overlay);

  function applyTransform() {
    console.log(
      `Flipcontainer height ${flipBookHeight}, flipcontainerwidth ${flipBookWidth}`
    );
    zoomWrapper.style.transform = `scale(${currentScale}) translate(${translateX}px, ${translateY}px)`;

    // Show overlay only when zoomed in (> 1)
    if (currentScale > 1) {
      overlay.style.display = "block";
      zoomSlider.style.display = "block";
    } else {
      overlay.style.display = "none";
      translateX = 0;
      translateY = 0;
      zoomWrapper.style.transform = `scale(1) translate(0, 0)`;
      zoomSlider.style.display = "none";
    }

    if (Math.abs(zoomSlider.value - currentScale) > 0.001) {
      zoomSlider.value = currentScale.toFixed(2);
    }
  }

  // Zoom In
  zoomInBtn.addEventListener("click", () => {
    if (currentScale < maxScale) {
      currentScale += scaleStep;
      currentScale = Math.min(currentScale, maxScale);
      applyTransform();
    }
  });

  // Zoom Out
  zoomOutBtn.addEventListener("click", () => {
    if (currentScale > minScale) {
      currentScale -= scaleStep;
      currentScale = Math.max(currentScale, minScale);
      applyTransform();
    }
  });

  zoomSlider.addEventListener("change", (e) => {
    currentScale = parseFloat(e.target.value);
    applyTransform();
  });

  // Dragging state on overlay instead of zoomWrapper
  let isDragging = false;
  let startX, startY;

  function getEventPosition(e) {
    if (e.touches && e.touches.length > 0) {
      return { x: e.touches[0].clientX, y: e.touches[0].clientY };
    } else {
      return { x: e.clientX, y: e.clientY };
    }
  }

  function onDragStart(e) {
    if (currentScale <= 1) return;

    isDragging = true;
    const pos = getEventPosition(e);
    startX = pos.x;
    startY = pos.y;

    e.preventDefault();
  }

  function onDragMove(e) {
    if (!isDragging) return;

    const pos = getEventPosition(e);
    const dx = pos.x - startX;
    const dy = pos.y - startY;

    startX = pos.x;
    startY = pos.y;

    translateX += dx / currentScale;
    translateY += dy / currentScale;

    applyTransform();
  }

  function onDragEnd(e) {
    isDragging = false;
  }

  // Attach drag event listeners to overlay
  overlay.addEventListener("mousedown", onDragStart);
  overlay.addEventListener("mousemove", onDragMove);
  overlay.addEventListener("mouseup", onDragEnd);
  overlay.addEventListener("mouseleave", onDragEnd);

  overlay.addEventListener("touchstart", onDragStart, { passive: false });
  overlay.addEventListener("touchmove", onDragMove, { passive: false });
  overlay.addEventListener("touchend", onDragEnd);
}

function initView(flipBook) {
  if (switchViewBtn) {
    switchViewBtn.addEventListener("click", (e) => {
      if (!isSingleView) {
        flipContainer.style.width = "30vw";
        isSingleView = true;
        switchViewBtn.setAttribute("aria-label", "Double Page View");
        switchViewBtn.querySelector("i").textContent = "menu_book";
        flipBook.update({ width: 768 });
      } else {
        flipContainer.style.width = "100vw";
        isSingleView = false;
        switchViewBtn.setAttribute("aria-label", "Single Page View");
        switchViewBtn.querySelector("i").textContent = "article";
        flipBook.update({ width: 450 });
      }
    });
  }
  initPageCounter(flipBook);
}

function initStretch(flipBook) {
  const stretchBtn = document.getElementById("btn-stretch");
  stretchBtn.addEventListener("click", () => {
    if (!isStretched) {
      console.log(`Current container width ${flipContainer.style.width}`);
      const fullWidth = document.body.offsetWidth;
      console.log(`Full body width ${fullWidth}`);
      const pages = document.querySelectorAll(".page");
      pages.forEach((page) => {
        console.log(`Current page width ${page.style.width}`);
        page.style.width = `${fullWidth / 2}px`;
      });
      flipContainer.style.width = `${fullWidth}px`;
      flipBook.update({ width: 2000 });
    }
  });
}

// function enlargeContent(increase, flipBook) {
//   const enlargeFactor = isMobile ? '30px' : '50px';
//   if (increase) {
//     flipBook.update({
//       width: isMobile ? 340 : 750,
//       height: isMobile ? 700 : 950,
//     });
//   } else {
//     flipBook.update({
//       width: isMobile ? 340 : 450,
//       height: isMobile ? 700 : 650,
//     });
//   }
// }

function updateScreenSize(flipBook) {
  const desktopWidth = window.innerWidth;
  const desktopHeight = window.innerHeight;
  console.log(
    `Working on desktop with ${desktopWidth}, height ${desktopHeight}`
  );

  // Define desktop as screen width >= 1440 (adjust if needed)
  const isDesktop = desktopWidth >= 1920;

  if (isDesktop) {
    const newWidth = Math.floor(desktopWidth * 0.7);
    const newHeight = Math.floor(desktopHeight * 0.7);

    flipBook.update({
      width: newWidth,
      height: newHeight,
      minWidth: 815,
      maxWidth: 1500,
      minHeight: 920,
      maxHeight: 1850,
    });
  }
}

function adjustMarginToAvoidOverlap(img) {
  const elRect = img.getBoundingClientRect();
  const controlEl = document.querySelector(".controls-bottom"); // just one element

  if (!controlEl) return; // if no such element, nothing to do

  const otherRect = controlEl.getBoundingClientRect();

  // Check if rectangles overlap
  const isOverlap = !(
    otherRect.right <= elRect.left ||
    otherRect.left >= elRect.right ||
    otherRect.bottom <= elRect.top ||
    otherRect.top >= elRect.bottom
  );

  if (!isOverlap) return; // no overlap, no margin adjustment

  const overlapHeight = Math.max(
    0,
    Math.min(elRect.bottom, otherRect.bottom) -
      Math.max(elRect.top, otherRect.top)
  );

  if (overlapHeight > 0) {
    img.style.marginTop = "-" + overlapHeight + "px";
    console.log(`Adjusted marginTop by ${overlapHeight}px`);
  }
}

function allowMoveHelpBtn() {
  const button = document.getElementById("btn-help-float");
  makeDraggable(button);
}

function makeDraggable(element) {
  const holdDelay = 500;
  let offsetX = 0;
  let offsetY = 0;
  let isDragging = false;
  let wasDragged = false;
  let startX = 0;
  let startY = 0;
  let dragTimeout = null;
  let isHeld = false;

  element.addEventListener(
    "touchstart",
    function (e) {
      const touch = e.touches[0];
      startX = touch.clientX;
      startY = touch.clientY;
      offsetX = touch.clientX - element.offsetLeft;
      offsetY = touch.clientY - element.offsetTop;
      wasDragged = false;
      isDragging = false;
      isHeld = false;

      // Start hold timer
      dragTimeout = setTimeout(() => {
        isDragging = true;
        isHeld = true;
      }, holdDelay);

      e.preventDefault(); // Prevents scrolling when starting touch
    },
    { passive: false }
  );

  document.addEventListener(
    "touchmove",
    function (e) {
      const touch = e.touches[0];
      const dx = touch.clientX - startX;
      const dy = touch.clientY - startY;

      if (isHeld && isDragging) {
        wasDragged = true;
        element.style.left = `${touch.clientX - offsetX}px`;
        element.style.top = `${touch.clientY - offsetY}px`;
        e.preventDefault();
      } else {
        // Cancel drag if user moves before holding long enough
        if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
          clearTimeout(dragTimeout);
        }
      }
    },
    { passive: false }
  );

  document.addEventListener("touchend", function (e) {
    clearTimeout(dragTimeout);

    if (!wasDragged && e.target === element) {
    element.click();
  }

    isDragging = false;
    isHeld = false;
  });

  element.addEventListener("mousedown", function (e) {
    startX = e.clientX;
    startY = e.clientY;
    offsetX = e.clientX - element.offsetLeft;
    offsetY = e.clientY - element.offsetTop;
    wasDragged = false;
    isDragging = false;
    isHeld = false;

    dragTimeout = setTimeout(() => {
      isDragging = true;
      isHeld = true;
    }, holdDelay);

    // Prevent text selection while dragging
    e.preventDefault();
  });

  document.addEventListener("mousemove", function (e) {
    if (!isHeld || !isDragging) return;
    const dx = e.clientX - startX;
    const dy = e.clientY - startY;

    if (Math.abs(dx) > 0 || Math.abs(dy) > 0) {
      wasDragged = true;
      element.style.left = `${e.clientX - offsetX}px`;
      element.style.top = `${e.clientY - offsetY}px`;
    }
  });

  document.addEventListener("mousemove", function (e) {
    if (!isDragging) {
      const dx = e.clientX - startX;
      const dy = e.clientY - startY;
      if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
        clearTimeout(dragTimeout);
      }
    }
  });

  document.addEventListener("mouseup", function (e) {
    clearTimeout(dragTimeout);

    if (!wasDragged && e.target === element) {
      element.click();
    }

    isDragging = false;
    isHeld = false;
  });
}

