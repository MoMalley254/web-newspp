console.log("📘 flip.js loaded");

console.log("📄 Window loaded, initializing flipbook...");

const $flipbook = $("#flipbook");

const width = $flipbook.width() ;
const height = $flipbook.height();

$flipbook.turn({
  width: width,
  height: height,
  autoCenter: true,
//   display: 'single',
	duration: 2000
});

// totalPagesSpan.

const currentPageSpan = document.getElementById('current-page');
currentPageSpan.textContent = $flipbook.turn("page");

const nextBtn = document.querySelectorAll(".btn-next-page");
const prevBtn = document.querySelectorAll(".btn-prev-page");
const skipPrevBtn = document.querySelectorAll(".btn-skip-backward");
const skipNextBtn = document.querySelectorAll(".btn-skip-forward");

console.log("🔍 Buttons found:");
console.log("Next:", nextBtn.length);
console.log("Prev:", prevBtn.length);
console.log("Skip Back:", skipPrevBtn.length);
console.log("Skip Forward:", skipNextBtn.length);

// Go to next page
nextBtn.forEach((btn) =>
  btn.addEventListener("click", () => {
    console.log("[Next] Button clicked");
    const currentPage = $flipbook.turn("page");
	
    console.log(`[Next] Current page: ${currentPage}`);
    $flipbook.turn("next");
	updateCurrentPage(currentPage);
  })
);

// Go to previous page
prevBtn.forEach((btn) =>
  btn.addEventListener("click", () => {
    console.log("[Previous] Button clicked");
    const currentPage = $flipbook.turn("page");
    console.log(`[Previous] Current page: ${currentPage}`);
    $flipbook.turn("previous");
	updateCurrentPage(currentPage);
  })
);

// Skip forward by 2 pages
skipNextBtn.forEach((btn) =>
  btn.addEventListener("click", () => {
    const currentPage = $flipbook.turn("page");
    const totalPages = $flipbook.turn("pages");
    const nextPage = Math.min(currentPage + 2, totalPages);
    console.log("[Skip Forward] Button clicked");
    console.log(
      `[Skip Forward] Current page: ${currentPage}, Going to: ${nextPage}`
    );
    $flipbook.turn("page", nextPage);
	updateCurrentPage(currentPage);
  })
);

// Skip backward by 2 pages
skipPrevBtn.forEach((btn) =>
  btn.addEventListener("click", () => {
    const currentPage = $flipbook.turn("page");
    const prevPage = Math.max(currentPage - 2, 1);
    console.log("[Skip Backward] Button clicked");
    console.log(
      `[Skip Backward] Current page: ${currentPage}, Going to: ${prevPage}`
    );
    $flipbook.turn("page", prevPage);
	updateCurrentPage(currentPage);
  })
);

// Log page turn events
$flipbook.bind("turning", function (event, page) {
  console.log(`[Turning] Flipping to page: ${page}`);
});

$flipbook.bind("turned", function (event, page) {
  console.log(`[Turned] Now on page: ${page}`);
});

function updateCurrentPage(currentPage) {
	currentPageSpan.textContent = currentPage
}
