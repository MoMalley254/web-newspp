function initTurnjs() {
  console.log("📘 flip.js loaded");

  console.log("📄 Window loaded, initializing flipbook...");

  // const $flipbook = $("#flipbook");
  const $flipbook = $("#page-container");

  // Clean up previous instance
  if ($flipbook.data("turn")) {
    $flipbook.turn("destroy").html("");
  }

  const width = $flipbook.width();
  const height = $flipbook.height();

  $flipbook.turn({
    width: width,
    height: height,
    autoCenter: true,
    display: !isMobile ? "double" : "single",
    duration: !isMobile ? 2000 : 1000,
    inclination: 5000,
    gradients: true, // 👈 Enables gradient effect
    acceleration: true, // 👈 Use hardware acceleration for smoother peel
    elevation: 100, // 👈 Increases peel depth (default: 50)
    corners: "all",
  });

  // ✅ Now set to page 1 AFTER turn is initialized
  $flipbook.turn("page", 1);

  // totalPagesSpan.

  const totalPagesSpan = document.getElementById("total-pages");
  const currentPageSpan = document.getElementById("current-page");
  currentPageSpan.textContent = $flipbook.turn("page");
  totalPagesSpan.textContent = $flipbook.turn("pages");

  const nextBtn = document.querySelectorAll(".btn-next-page");
  const prevBtn = document.querySelectorAll(".btn-prev-page");
  const skipPrevBtn = document.querySelectorAll(".btn-skip-backward");
  const skipNextBtn = document.querySelectorAll(".btn-skip-forward");

  console.log("🔍 Buttons found:");
  console.log("Next:", nextBtn.length);
  console.log("Prev:", prevBtn.length);
  console.log("Skip Back:", skipPrevBtn.length);
  console.log("Skip Forward:", skipNextBtn.length);

  window.addEventListener("keydown", (event) => {
    if (event.key === "ArrowRight") {
      console.log("[Keyboard] Right Arrow pressed");
      const currentPage = $flipbook.turn("page");
      console.log(`[Next] Current page: ${currentPage}`);
      //   updateCurrentPage(currentPage);
      $flipbook.turn("next");
    } else if (event.key === "ArrowLeft") {
      console.log("[Keyboard] Left Arrow pressed");
      const currentPage = $flipbook.turn("page");
      console.log(`[Previous] Current page: ${currentPage}`);
      //   updateCurrentPage(currentPage);
      $flipbook.turn("previous");
    }
  });

  // Go to next page
  nextBtn.forEach((btn) =>
    btn.addEventListener("click", () => {
      console.log("[Next] Button clicked");
      const currentPage = $flipbook.turn("page");

      console.log(`[Next] Current page: ${currentPage}`);
      //   updateCurrentPage(currentPage);
      $flipbook.turn("next");
    })
  );

  // Go to previous page
  prevBtn.forEach((btn) =>
    btn.addEventListener("click", () => {
      console.log("[Previous] Button clicked");
      const currentPage = $flipbook.turn("page");
      console.log(`[Previous] Current page: ${currentPage}`);
      //   updateCurrentPage(currentPage);
      $flipbook.turn("previous");
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
      //   updateCurrentPage(currentPage);
      $flipbook.turn("page", nextPage);
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
      //   updateCurrentPage(currentPage);
      $flipbook.turn("page", prevPage);
    })
  );

  // Log page turn events
  $flipbook.bind("turning", function (event, page) {
    console.log(`[Turning] Flipping to page: ${page}`);
  });

  $flipbook.bind("turned", function (event, page) {
    console.log(`[Turned] Now on page: ${page}`);
    updateCurrentPage();
  });

  function updateCurrentPage() {
    const view = $flipbook.turn("view"); // array of visible pages
    const total = $flipbook.turn("pages");

    if (view.length === 1 || (view.length === 2 && view[1] > total)) {
      // Single page visible OR second page number exceeds total pages (last page alone)
      currentPageSpan.textContent = `Page ${view[0]}`;
    } else {
		if (view[1] === 0) {
			currentPageSpan.textContent = `Page ${view[0]}`;
		} else if (view[0] === 0) {
			currentPageSpan.textContent = `Page ${view[0]}`;
		} else {
			currentPageSpan.textContent = `Pages ${view[0]} - ${view[1]}`;
		}
      
    }
  }
}
