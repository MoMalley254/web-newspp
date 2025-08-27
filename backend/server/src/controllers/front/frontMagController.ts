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
    // console.log(`Html path ${magazinePath}`);
    console.log("Original magazinePath:", JSON.stringify(magazinePath));

    const cleanMagazinePath = magazinePath.replace(/^[/\\]+/, "");
    const fullPath = path.resolve(__dirname, "../../../", cleanMagazinePath);
    console.log(`Full path ${fullPath}`);

    // const rawHtml = await fs.readFile(fullPath, "utf-8");
    // const rawHtml = await fs.readFile(fullPath, 'utf-8',);
    // if (!rawHtml || rawHtml === "") {
    //   console.log(`Unable to find file`);
    // }

    // const $ = cheerio.load(rawHtml);
    // Remove elements with class 'loading-indicator'
    // $(".loading-indicator").remove();

    // Remove sidebar — assuming it's identified by a class or ID like '.sidebar' or '#sidebar'
    // $(".sidebar, #sidebar").remove();

    // Inject a custom banner or buttons if needed
    // $('body').qu

    const readStream = fs.createReadStream(fullPath, { encoding: "utf-8" });
    const rl = readline.createInterface({ input: readStream });

    res.setHeader("Content-Type", "text/html");

    let insideStyle = false;
    let pfCount = 0;
    for await (const line of rl) {
      const trimmed = line.trim();

      if (trimmed.toLowerCase().startsWith("</head")) {
        res.write(`
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.3.3/css/bootstrap.min.css" rel="stylesheet" />
  `);
        res.write(line + "\n");
      }

      // Track whether you're inside a <style> block
      if (trimmed.includes("<style")) insideStyle = true;

      // Detect closing </style> tag
      if (insideStyle && trimmed.includes("</style>")) {
        // Inject your override styles just before closing </style>
        res.write(`
            /* Custom style overrides */
            #page-container {     
                overflow: hidden; 
                background: linear-gradient(to bottom right, #232370, #4f0a8c) !important;
                position: relative !important;
            }

            #page-container > pf {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;        /* full width */
                height: 100%;       /* full height */
                overflow: hidden;   /* prevent inner scrolling */
            }

            body {
                background: linear-gradient(to bottom right, #232370, #4f0a8c) !important;
            }
        `);

        insideStyle = false;
        res.write(line + "\n");
        continue;
      }

      // Other logic (e.g., removing loading indicators, sidebar) remains
      const shouldSkip =
        line.includes('class="sidebar"') ||
        line.includes('class="loading-indicator"') ||
        line.includes(
          '<img alt="" src="data:image/png;base64,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">'
        );

      if (!shouldSkip) {
        res.write(line + "\n");
      }

      if (/^<div[^>]*id=["']pf[^"']*["']/i.test(trimmed)) {
        pfCount++;
      }

      if (trimmed.toLowerCase() === "</body>") {
        // Inject your script tag before closing </body>
        // res.write(
        //   `<script src="/front/public/assets/scripts/flip.js"></script>\n`
        // );

        res.write(`
    <script>
      document.addEventListener('DOMContentLoaded', () => {

        const styles = \`
        @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300..700;1,300..700&family=Crimson+Pro:ital,wght@0,200..900;1,200..900&display=swap');
        iframe {
          height: 50vh;
          width: 75vw
        }  
        
        /* Top Controls */
          .top h1, 
.top h2, 
.top h2, 
.top h3, 
.top h4, 
.controls-bottom h4, 
.top h5 {
    font-family: "Cormorant Garamond", serif;
    font-weight: bold;
    text-align: center;
    color: white;
}

.top p, 
.top a, 
.controls-bottom span
.top span {
    font-family: "Crimson Pro", serif;
    font-weight: normal;
    color: white;
}

.top i {
    color: white;
}

.top {
    z-index: 99;
    top: 0;
    position: fixed;
}

.top .titles {
    height: 7vh;
    margin-top: -0.8vh;
    width: 100vw;
    background:  #232370;
    justify-content: center;
}

.top h1 {
    margin: 10px 0;
}

.top .titles h2 {
    margin-top: 5px;
    font-size: 35px;
}

.controls-top {
    height: 7vh;
    width: 100vw;
    display: flex;
    justify-content: space-between;
    align-items: center;
    justify-items: center;
}

.controls-top .top-show-controls {
    flex: 9;
    display: flex;
    justify-content: space-evenly;
    transition: transform 800ms ease-in-out;
    background: linear-gradient(to bottom right,  #232370, #4f0a8c);
} 

.top-show-controls.hide {
  /* transform: translateX(calc(-100vw));  */
  transform: translateY(calc(-100vh)); 
}

.controls-top button {
    position: relative;
    background-color: transparent;
    font-size: 20px;
    border-radius: 10px;
    cursor: pointer;
    transition: background-color 500ms ease-in-out, color 500ms ease-in-out, transform 500ms ease-in-out;
    padding: 8px 12px; 
    border: none;
}

.controls-top #btn-hide-controls {
    flex: 1;
    transition: opacity 400ms ease;
    background:  #232370;
    border-radius: 0;
}

.controls-top button:hover {
    /* background-color: white; */
}

/* Tooltip styling */
.controls-top button::after {
    content: attr(aria-label);
    position: absolute;
    top: 100%; /* place above the button */
    left: 50%;
    transform: translateX(-50%) translateY(-8px);
    background-color: #4f0a8c;
    color: white;
    padding: 4px 8px;
    border-radius: 4px;
    white-space: nowrap;
    font-size: 14px;
    opacity: 0;
    pointer-events: none;
    transition: opacity 300ms ease-in-out, transform 300ms ease-in-out;
    z-index: 10;
  /* small arrow */
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}

.controls-top button:hover::after {
    opacity: 1;
    transform: translateX(-50%) translateY(-12px);
    pointer-events: auto;
}

.controls-top button i {
    transition: color 500ms ease-in-out, transform 500ms ease-in-out;
    font-size: 30px;
}

.controls-top .top-show-controls button:hover i {
    /* color: #232370; */
    transform: scale(1.17); 
}

#btn-hide-controls {
  position: sticky;
  left: 0;
  z-index: 100;
}
  .controls-bottom {
    height: 5vh;
    width: 70vw;
    display: flex;
    justify-content: space-between;
    align-items: center;
    justify-items: center;
    margin: -10vh 14vw 0 14vw;
    position: fixed;
}

.controls-bottom button {
    position: relative;
    background-color: transparent;
    font-size: 20px;
    border-radius: 10px;
    cursor: pointer;
    transition: background-color 500ms ease-in-out, color 500ms ease-in-out, transform 500ms ease-in-out;
    padding: 8px 12px; 
    border: none;
    color: white;
}

.controls-bottom #btn-hide-controls {
    flex: 1;
    transition: opacity 400ms ease;
    background:  #232370;
    border-radius: 0;
}

/* Tooltip styling */
.controls-bottom button::after {
    content: attr(aria-label);
    position: absolute;
    bottom: 100%; /* place above the button */
    left: 50%;
    transform: translateX(-50%) translateY(-8px);
    background-color: #4f0a8c;
    color: white;
    padding: 4px 8px;
    border-radius: 4px;
    white-space: nowrap;
    font-size: 14px;
    opacity: 0;
    pointer-events: none;
    transition: opacity 300ms ease-in-out, transform 300ms ease-in-out;
    z-index: 10;
  /* small arrow */
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}

.controls-bottom button:hover::after {
    opacity: 1;
    transform: translateX(-50%) translateY(-12px);
    pointer-events: auto;
}

.controls-bottom button i {
    transition: color 500ms ease-in-out, transform 500ms ease-in-out;
    font-size: 30px;
}

.controls-bottom  button:hover i {
    /* color: #232370; */
    transform: scale(1.17); 
}

.controls-bottom .page-counts {
    display: block;
}
    #page-container {
        margin-top: 10vh;
        height: 80vh; 
    }

    body {
      overflow: hidden !important;
      height: 100vh !important;
    }

@media (max-width: 767px) {
    .top .titles h2 {
        margin-top: 10px;
        font-size: 20px;
    }

    .top .titles {
        height: 5vh;
        margin-top: 0vh;
    }

    .controls-top .top-show-controls {
        margin-top: 30px;
        display: grid;
        grid-template-columns: repeat(3, 20%);
        grid-template-rows: repeat(2, 40%);
        gap: 10px;
        /* justify-content: space-evenly; */
    } 

    .controls-top button {
        font-size: 10px;
        padding: 8px 8px; 
    }

    .controls-top button i {
        font-size: 20px;
    }

    .controls-top .btn-skip-backward,
    .controls-top .btn-prev-page,
    .controls-top .btn-next-page,
    .controls-top .btn-skip-forward {
        display: none;
    }

    .controls-top #btn-hide-controls::after {
        content: attr(aria-label);
        position: absolute;
        bottom: 100%; /* place above the button */
        left: 100%;
        transform: translateX(-50%) translateY(-8px);
        color: white;
        padding: 8px 8px;
        border-radius: 4px;
        white-space: nowrap;
        font-size: 14px;
        z-index: 9999;
    }

    .controls-bottom {
        width: 100vw;
        display: flex;
        justify-content: space-between;
        align-items: center;
        justify-items: center;
        margin: -5vh 1vw 0 1vw;
        position: fixed;
    }

    #page-container {
        margin-top: 10vh;
    }
}
    
        \`;
        const styleTag = document.createElement('style');
        styleTag.textContent = styles;
        document.head.appendChild(styleTag);

        const htmlSection = \`
          <section class="top">
            <div class="titles">
              <h2 id="magazineTitle">${magazine.title}</h2>
            </div>
            <div class="controls-top">
              <button id="btn-hide-controls" aria-label="Hide Controls">
                <i class="material-icons">keyboard_double_arrow_up</i>
              </button>
              <div class="top-show-controls">
                <button id="btn-fullscreen" aria-label="Full Screen"><i class="material-icons">fullscreen</i></button>
                <button id="btn-zoom-in" aria-label="Zoom In"><i class="material-icons">zoom_in</i></button>
                <button id="btn-zoom-out" aria-label="Zoom Out"><i class="material-icons">zoom_out</i></button>
                <button class="btn-skip-backward" aria-label="Skip Page Backward"><i class="material-icons">skip_previous</i></button>
                <button class="btn-prev-page" aria-label="Previous Page"><i class="material-icons">navigate_before</i></button>
                <button class="btn-next-page" aria-label="Next Page"><i class="material-icons">navigate_next</i></button>
                <button class="btn-skip-forward" aria-label="Skip Page Forward"><i class="material-icons">skip_next</i></button>
                <button id="btn-share" aria-label="Share"><i class="material-icons">share</i></button>
                <button id="btn-search" aria-label="Search"><i class="material-icons">search</i></button>
                <button id="btn-menu" aria-label="Show Articles"><i class="material-icons">segment</i></button>
              </div>
            </div>
          </section>
          
        \`;
        document.body.insertAdjacentHTML('afterbegin', htmlSection);
      });

      const bottomControls = \`
          <section class="bottom">
          
        <!-- controls bottom -->
        <div class="controls-bottom">

            <button class="btn-skip-backward" aria-label="Skip Page Backward">
              <i class="material-icons">skip_previous</i>
            </button>

            <button class="btn-prev-page" aria-label="Previous Page">
              <i class="material-icons">navigate_before</i>
            </button>

            <div class="page-counts">
              <h4 class="page">
                 <span id="current-page">0</span> of <span id="total-pages">0</span> pages
              </h4>
            </div>

            <button class="btn-next-page" aria-label="Next Page">
              <i class="material-icons">navigate_next</i>
            </button>

            <button class="btn-skip-forward" aria-label="Skip Page Forward">
              <i class="material-icons">skip_next</i>
            </button>
        </div>
      </section>

      \`;
      document.body.insertAdjacentHTML('beforeend', bottomControls);
    </script>
  `);

  res.write(`
      <script>
  function initHideMenuButton(retries = 10, delay = 300) {
    const hideMenuBtn = document.getElementById('btn-hide-controls');
    const topControls = document.querySelector('.top-show-controls');
    const fullScreenBtn = document.getElementById('btn-fullscreen');
const fullScreenContent = document.querySelector('#page-container');

    if (!hideMenuBtn || !topControls || !fullScreenBtn || !fullScreenContent) {
      if (retries > 0) {
        // Retry after a short delay
        setTimeout(() => {
          initHideMenuButton(retries - 1, delay);
        }, delay);
      } else {
        console.warn('btn-hide-controls or .top-show-controls not found in DOM after retries.');
      }
      return;
    }

    console.log('Try fullscreen controls');
      fullScreenBtn.addEventListener('click', function(e) {
  console.log('Clicked full screen btn');

  if (fullScreenBtn.getAttribute('aria-label') === 'Full Screen') {
    // Enter full screen
    if (fullScreenContent.requestFullscreen) {
      fullScreenContent.requestFullscreen();
    } else if (fullScreenContent.webkitRequestFullscreen) { // Safari
      fullScreenContent.webkitRequestFullscreen();
    } else if (fullScreenContent.msRequestFullscreen) { // IE11
      fullScreenContent.msRequestFullscreen();
    }

    fullScreenBtn.innerHTML = '<i class="material-icons">fullscreen_exit</i>';
    fullScreenBtn.setAttribute('aria-label', 'Exit Full Screen');
  } else {
    // Exit full screen
    if (document.exitFullscreen) {
      document.exitFullscreen();
    } else if (document.webkitExitFullscreen) { // Safari
      document.webkitExitFullscreen();
    } else if (document.msExitFullscreen) { // IE11
      document.msExitFullscreen();
    }

    fullScreenBtn.innerHTML = '<i class="material-icons">fullscreen</i>';
    fullScreenBtn.setAttribute('aria-label', 'Full Screen');
  }
});

// Reset button if user exits full screen using Esc or system controls
document.addEventListener('fullscreenchange', function() {
  if (!document.fullscreenElement) {
    fullScreenBtn.innerHTML = '<i class="material-icons">fullscreen</i>';
    fullScreenBtn.setAttribute('aria-label', 'Full Screen');
  }
});


    hideMenuBtn.addEventListener('click', (e) => {
      // Fade out current icon
      e.target.style.opacity = '0';

      setTimeout(() => {
        if (topControls.classList.contains('hide')) {
          topControls.classList.remove('hide');
          e.target.innerHTML = '<i class="material-icons">keyboard_double_arrow_up</i>';
          hideMenuBtn.setAttribute('aria-label', 'Hide Controls');
        } else {
          topControls.classList.add('hide');
          e.target.innerHTML = '<i class="material-icons">keyboard_double_arrow_down</i>';
          hideMenuBtn.setAttribute('aria-label', 'Show Controls');
        }

        // Fade in new icon
        e.target.style.opacity = '1';
      }, 400); // match the CSS transition duration
    });
  }

  // Start trying to init the button after the DOM is ready
  document.addEventListener('DOMContentLoaded', () => {
    initHideMenuButton();
  });
</script>

    `);

        res.write(`
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/turn.js/3/turn.min.js"></script>
  <script>
  const body = document.querySelector('body');
const styles = getComputedStyle(body);

const widthPx = parseFloat(styles.width);  // convert "1200px" to 1200
const heightPx = parseFloat(styles.height);

const width = widthPx * 0.7;
const height = heightPx * 0.7;

console.log('Width: ' + width + 'px, Height: ' + height + 'px');
  const pages = document.querySelectorAll('div[id^="pf"]');
let count = 0;

console.log('Found these pages: ' + pages.length);

pages.forEach(function(originalDiv) {
  console.log('Working on frame ' + (count + 1) + ' of ' + pages.length);

  // 1. Extract the original HTML
  const htmlContent = originalDiv.outerHTML;

  // 2. Create an iframe
  const iframe = document.createElement('iframe');
  iframe.style.width = width; // Match width
  iframe.style.height = height; // Match height
  iframe.style.border = 'none';

  // 3. Replace the div with the iframe
  originalDiv.parentNode.replaceChild(iframe, originalDiv);

  // 4. Inject the HTML into the iframe
  iframe.onload = function () {
    const doc = iframe.contentDocument || iframe.contentWindow.document;
    doc.open();
    doc.write(htmlContent);
    doc.close();

    iframe.contentWindow.onload = function () {
      const contentBody = doc.body;

      // Get dimensions
      const iframeWidth = iframe.clientWidth;
      const iframeHeight = iframe.clientHeight;
      const contentWidth = contentBody.scrollWidth;
      const contentHeight = contentBody.scrollHeight;

      // Calculate scale
      const scaleX = iframeWidth / contentWidth;
      const scaleY = iframeHeight / contentHeight;
      const scale = Math.min(scaleX, scaleY);

      // Apply scaling
      contentBody.style.transformOrigin = 'top left';
      contentBody.style.transform = 'scale(' + scale + ')';

      // Prevent scrollbars
      doc.documentElement.style.overflow = 'hidden';
    };
  };

  count++;

  
});

// Initialize with desired width/height
      


    // Save original pages content once at the start
    const originalPages = $('#page-container').html();

    function initFlipbook() {
      const container = $('#page-container');
      
      if (container.data('turn')) {
        // Destroy previous turn.js instance
        container.turn('destroy');
        
        // Restore original pages
        container.html(originalPages);
      }

      

      const containerWidth = container.width() / 2;
      const containerHeight = container.height() / 2;

      container.turn({
        width: width,
        height: height,
        autoCenter: true
      });

      container.turn("page", 1);

      // Query number of iframes after adding each one
  const currentIframes = document.querySelectorAll('iframe');
  console.log('Currently there are ' + currentIframes.length + ' iframe(s) in the document.');

      const totalPagesSpan = document.getElementById("total-pages");
  const currentPageSpan = document.getElementById("current-page");
  currentPageSpan.textContent = container.turn("page");
  totalPagesSpan.textContent = container.turn("pages");

  const nextBtn = document.querySelectorAll(".btn-next-page");
  const prevBtn = document.querySelectorAll(".btn-prev-page");
  const skipPrevBtn = document.querySelectorAll(".btn-skip-backward");
  const skipNextBtn = document.querySelectorAll(".btn-skip-forward");

  window.addEventListener("keydown", (event) => {
    if (event.key === "ArrowRight") {
      console.log("[Keyboard] Right Arrow pressed");
      const currentPage = container.turn("page");
      //   updateCurrentPage(currentPage);
      container.turn("next");
    } else if (event.key === "ArrowLeft") {
      console.log("[Keyboard] Left Arrow pressed");
      const currentPage = container.turn("page");
      //   updateCurrentPage(currentPage);
      container.turn("previous");
    }
  });

  // Go to next page
  nextBtn.forEach((btn) =>
    btn.addEventListener("click", () => {
      console.log("[Next] Button clicked");
      const currentPage = container.turn("page");
      //   updateCurrentPage(currentPage);
      container.turn("next");
    })
  );

  // Go to previous page
  prevBtn.forEach((btn) =>
    btn.addEventListener("click", () => {
      console.log("[Previous] Button clicked");
      const currentPage = container.turn("page");
      //   updateCurrentPage(currentPage);
      container.turn("previous");
    })
  );

  // Skip forward by 2 pages
  skipNextBtn.forEach((btn) =>
    btn.addEventListener("click", () => {
      const currentPage = container.turn("page");
      const totalPages = container.turn("pages");
      const nextPage = Math.min(currentPage + 2, totalPages);
      console.log("[Skip Forward] Button clicked");
      //   updateCurrentPage(currentPage);
      container.turn("page", nextPage);
    })
  );

  // Skip backward by 2 pages
  skipPrevBtn.forEach((btn) =>
    btn.addEventListener("click", () => {
      const currentPage = container.turn("page");
      const prevPage = Math.max(currentPage - 2, 1);
      console.log("[Skip Backward] Button clicked");
      //   updateCurrentPage(currentPage);
      container.turn("page", prevPage);
    })
  );

  function updateCurrentPage() {
  const view = container.turn("view"); // array of visible pages
  const total = container.turn("pages");

  if (view.length === 1 || (view.length === 2 && view[1] > total)) {
    // Single page visible OR second page number exceeds total pages (last page alone)
    currentPageSpan.textContent = 'Page ' + view[0];
  } else {
    if (view[1] === 0) {
      currentPageSpan.textContent = 'Page ' + view[0];
    } else if (view[0] === 0) {
      currentPageSpan.textContent = 'Page ' + view[0];
    } else {
      currentPageSpan.textContent = 'Pages ' + view[0] + ' - ' + view[1];
    }
  }
}




    }

// Run on page load
initFlipbook();

// Optional: re-init on resize or media query change
window.addEventListener('resize', initFlipbook);

  </script>
`);


        res.write(line + "\n"); // then write </body> itself
        // continue;
      } else {
        // res.write(line + "\n");
        continue;
      }
    }
    console.log(`Total pages with id starting with "pf": ${pfCount}`);
    res.end();

    // return res.send($.html());
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
