document.addEventListener("DOMContentLoaded", () => {
  const isMobile = detectDeviceType();
  let scrollHeight = isMobile ? 1.1 : 0.8;
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

  const scrollToArticlesBtns = document.querySelectorAll(".scrollToArticles");
  scrollToArticlesBtns.forEach((scrollBtn) => {
    scrollBtn.addEventListener("click", (e) => {
      e.preventDefault();
      window.scrollBy({
        top: window.innerHeight * scrollHeight,
        left: 0,
        behavior: "smooth",
      });

      showBackToTopBtn();
    });
  });

  setInterval(flipImages, 3000);
  function flipImages() {
    const coverImages = document.querySelectorAll(".cover");
    // Create a copy of the current class names in the order they appear
    const currentClasses = Array.from(coverImages).map((img) => {
      if (img.classList.contains("main")) return "main";
      if (img.classList.contains("behind-1")) return "behind-1";
      if (img.classList.contains("behind-2")) return "behind-2";
    });

    // Rotate the class names: move the last to the front
    const newClasses = [
      currentClasses[2],
      currentClasses[0],
      currentClasses[1],
    ];

    // Apply the rotated classes back to the elements
    coverImages.forEach((img, index) => {
      img.classList.remove("main", "behind-1", "behind-2");
      img.classList.add(newClasses[index]);
    });
  }

  function showBackToTopBtn() {
    const backToTopBtn = document.getElementById("backToTopBtn");
    backToTopBtn.style.opacity = "1";

    backToTopBtn.addEventListener("click", () => {
      window.scrollBy({
        top: -window.innerHeight * scrollHeight,
        left: 0,
        behavior: "smooth",
      });
      backToTopBtn.style.opacity = "0";
    });
  }
});
