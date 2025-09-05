let session;
let magazine;

activateServiceWorker();
async function activateServiceWorker() {
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", async (e) => {
      const baseUrl = window.location.pathname;
      console.log(`Base url ${baseUrl}`);

      // Construct full URL to sw.js
      // const swUrl = new URL('sw.js', baseUrl).toString();
      const swUrl = `${baseUrl}/public/sw.js`;
      console.log(`Sw url ${swUrl}`);

      navigator.serviceWorker
        .register(swUrl,)
        .then((reg) => {
          console.log("✅ Service Worker registered with scope:", reg.scope);
        })
        .catch((err) => {
          console.error("❌ Service Worker registration failed:", err);
        });
    });
  }
}

// === Init Fingerprint ===
function getOrCreateFingerprint() {
  let fp = localStorage.getItem("deviceFingerprint");
  if (!fp) {
    fp = crypto.randomUUID();
    localStorage.setItem("deviceFingerprint", fp);
  }
  return fp;
}

// === Device Info ===
function getDeviceType() {
  const ua = navigator.userAgent;
  if (/mobile/i.test(ua)) return "mobile";
  if (/tablet|ipad/i.test(ua)) return "tablet";
  return "desktop";
}

function getLanguage() {
  return navigator.language || "unknown";
}

function startTrack() {
  session = {
    fingerprint: getOrCreateFingerprint(),
    magazineId: null,
    language: getLanguage(),
    deviceType: getDeviceType(),
    location: null,
  };

  console.log(`Device ${session},`);
  sendDataToSw("sessionInfo", { session: session });
  collectMagInteraction();
}

startTrack();

function collectMagInteraction() {
  const params = new URLSearchParams(window.location.search);
  const magQuery = params.get("article");

  if (magQuery && magQuery !== "") {
    magazine = magQuery;
    console.log(`Mag id ${magazine}`);

    setupFlipbookListeners();
  }
}

const pageTimings = [];
let totalPages = null;
let currentPage = null;
let magazineStartTime = Date.now();
let hasCompletedMagazine = false;

// Tracks the time user starts and stops viewing a page
let pageStartTime = null;
let pageStopTime = null;

function setupFlipbookListeners() {
  // article.js
  const waitForFlipbook = setInterval(() => {
    const flipBook = window.flipBookInstance;

    if (flipBook) {
      clearInterval(waitForFlipbook);
      initializeFlipbookTracking(flipBook);
    }
  }, 100); // Poll every 100ms
}

function initializeFlipbookTracking(flipBook) {
  totalPages = flipBook.getPageCount();
  currentPage = flipBook.getCurrentPageIndex() + 1;
  pageStartTime = Date.now(); // Track time when user first lands on a page

  console.log(`Flipbook ready. Total pages: ${totalPages}`);

  // Attach page flip listener
  flipBook.on("flip", handlePageFlip);

  window.addEventListener("beforeunload", handleExit);
  window.addEventListener("popstate", handleExit); // Back button
}

function handlePageFlip(e) {
  const flippedToPage = e.data + 1;
  // If flipping backward, ignore or modify previous entry
  if (flippedToPage <= currentPage) {
    console.log(
      `Backward flip detected to page ${flippedToPage}. Ignoring or modifying...`
    );

    // Optional: Modify existing entry
    // const existing = pageTimings.find(p => p.page === flippedToPage);
    // if (existing) {
    //   existing.revisitedAt = now;
    // }

    // Don't update timing or currentPage
    return;
  }

  pageStopTime = Date.now();
  const timeSpent = pageStopTime - pageStartTime;

  // Save time spent on previous page
  if (currentPage !== null && pageStartTime !== null) {
    pageTimings.push({
      page: currentPage,
      start: pageStartTime,
      stop: pageStopTime,
      totalTime: timeSpent,
    });
  }

  // Update current page
  currentPage = flippedToPage;
  pageStartTime = Date.now(); // reset for next page
  pageStopTime = null;

  console.log(
    `Flipped to page ${flippedToPage}, spent ${timeSpent}ms on previous page`
  );
  console.log(` `);
  console.log(`Current times ${JSON.stringify(pageTimings)}`);

  // Optional: detect if completed
  if (flippedToPage === totalPages && !hasCompletedMagazine) {
    hasCompletedMagazine = true;
    const magazineTotalTime = Date.now() - magazineStartTime;
    console.log(`Magazine completed in ${magazineTotalTime}ms`);
    handleFinish();
  }
}

function handleExit(event) {
  event.returnValue = "Are you sure you want to leave?";
  handleFinish();
}

function handleFinish() {
  const now = Date.now();

  // Record time on current page before exit
  if (currentPage !== null && pageStartTime !== null) {
    pageStopTime = now;
    pageTimings.push({
      page: currentPage,
      start: pageStartTime,
      stop: pageStopTime,
      totalTime: pageStopTime - pageStartTime,
    });
  }

  if (currentPage !== null && currentPage === totalPages) {
    hasCompletedMagazine = true;
  }

  const totalDuration = now - magazineStartTime;

  const summary = {
    totalPages,
    currentPage,
    completed: hasCompletedMagazine,
    startedAt: new Date(magazineStartTime).toISOString(),
    exitedAt: new Date().toISOString(),
    duration: totalDuration,
    pages: pageTimings,
  };
  console.log("User finished or exited page. Final summary:", summary);
  sendDataToSw("magData", { magazine: summary });
}

async function sendDataToSw(key, payload) {
  console.log(`Send to service worker`);
  console.log('Controller:', navigator.serviceWorker.controller);

  if ("serviceWorker" in navigator) {
    try {
      const registration = await navigator.serviceWorker.ready;

      if (registration.active) {
        registration.active.postMessage({ type: key, payload: payload });
        console.log("Message sent to Service Worker.");
      } else {
        console.warn("Service Worker is not active.");
        activateServiceWorker();
      }
    } catch (error) {
      console.log(`Send to service worker error: ${error}`);
    }
  } else {
    console.log(`No service worker found`);
    activateServiceWorker();
  }
}
